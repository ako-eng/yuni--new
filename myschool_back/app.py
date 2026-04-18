from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import date
import json
import os
import sys
import uuid
import hashlib


def notices_json_path():
    """通知列表 JSON 路径。测试可通过环境变量 MYSCHOOL_NOTICES_PATH 覆盖。"""
    override = (os.environ.get('MYSCHOOL_NOTICES_PATH') or '').strip()
    if override:
        return override
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gdut_notices.json')


def users_json_path():
    """用户数据 JSON 路径"""
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), 'users.json')


def load_notices_json(notices_file):
    """读取通知列表 JSON。若某条字符串值被错误换行（行尾为 `",` 的孤儿行），自动合并后再解析。"""
    with open(notices_file, 'r', encoding='utf-8') as f:
        raw = f.read()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        lines = raw.splitlines(keepends=True)
        i = 0
        while i < len(lines) - 1:
            nxt = lines[i + 1].strip()
            if nxt == '",':
                lines[i] = lines[i].rstrip('\r\n') + lines[i + 1]
                del lines[i + 1]
                continue
            i += 1
        repaired = ''.join(lines)
        return json.loads(repaired)


def load_users_json():
    """读取用户数据 JSON"""
    users_file = users_json_path()
    if not os.path.exists(users_file):
        return {}
    try:
        with open(users_file, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError:
        return {}


def save_users_json(users):
    """保存用户数据 JSON"""
    users_file = users_json_path()
    tmp = users_file + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(users, f, ensure_ascii=False, indent=2)
    os.replace(tmp, users_file)


def hash_password(password):
    """对密码进行哈希处理"""
    return hashlib.sha256(password.encode()).hexdigest()


def create_app():
    app = Flask(__name__)
    # 响应 JSON 中直接输出中文（浏览器里可读）；Flask 3 需改 json provider，仅 JSON_AS_ASCII 可能不生效
    app.config['JSON_AS_ASCII'] = False
    try:
        app.json.ensure_ascii = False
    except AttributeError:
        pass
    CORS(app)

    @app.after_request
    def json_response_utf8_charset(response):
        ct = response.headers.get('Content-Type', '')
        if ct.startswith('application/json') and 'charset=' not in ct.lower():
            response.headers['Content-Type'] = 'application/json; charset=utf-8'
        return response

    @app.route('/api/notices', methods=['GET'])
    def get_notices():
        try:
            notices_file = notices_json_path()
            
            if not os.path.exists(notices_file):
                try:
                    from mes import GDUTSpider
                    spider = GDUTSpider()
                    spider.run(max_pages=3)
                except Exception as e:
                    return jsonify({'status': 'error', 'message': f'无法获取通知数据: {str(e)}'}), 500
            
            notices = load_notices_json(notices_file)
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            keyword = request.args.get('keyword', '', type=str)
            category = request.args.get('category', '', type=str)
            tag = request.args.get('tag', '', type=str)
            
            filtered_notices = notices
            
            # 按关键词过滤
            if keyword:
                filtered_notices = [notice for notice in filtered_notices if keyword in notice.get('title', '')]
            
            # 按分类过滤
            if category:
                filtered_notices = [notice for notice in filtered_notices if notice.get('category', '') == category]
            
            # 按标签过滤
            if tag:
                filtered_notices = [notice for notice in filtered_notices if tag in notice.get('tags', [])]
            
            total = len(filtered_notices)
            start = (page - 1) * per_page
            end = start + per_page
            paginated_notices = filtered_notices[start:end]
            
            return jsonify({
                'items': paginated_notices,
                'total': total,
                'page': page,
                'per_page': per_page,
                'pages': (total + per_page - 1) // per_page
            }), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500

    @app.post('/api/notices/add')
    def add_notice():
        """手动新增一条通知：追加写入 gdut_notices.json（列表首部）。请求体见 API 文档。"""
        try:
            if not request.is_json:
                return jsonify({'status': 'error', 'message': '请求需使用 Content-Type: application/json'}), 400

            data = request.get_json(silent=True)
            if data is None:
                return jsonify({'status': 'error', 'message': '无效的 JSON 请求体'}), 400
            if not isinstance(data, dict):
                return jsonify({'status': 'error', 'message': 'JSON 根须为对象'}), 400

            title = (data.get('title') or '').strip()
            content = (data.get('content') or '').strip()
            category = (data.get('category') or '').strip()
            if not title or not content or not category:
                return jsonify({'status': 'error', 'message': 'title、content、category 为必填且去空格后不能为空'}), 400

            department = (data.get('department') or '').strip()

            raw_tags = data.get('tags')
            if raw_tags is None or raw_tags == '':
                tags = []
            elif isinstance(raw_tags, str):
                tags = [p.strip() for p in raw_tags.split(',') if p.strip()]
            else:
                return jsonify({'status': 'error', 'message': 'tags 须为字符串（英文逗号分隔），或省略'}), 400

            notices_file = notices_json_path()
            if not os.path.exists(notices_file):
                return jsonify({'status': 'error', 'message': '通知数据文件不存在'}), 404

            notices = load_notices_json(notices_file)
            if not isinstance(notices, list):
                return jsonify({'status': 'error', 'message': '通知数据格式异常'}), 500

            nid = str(uuid.uuid4())
            page_url = f'teacher://notice/{nid}'
            today = date.today().isoformat()
            new_item = {
                'title': title,
                'url': page_url,
                'date': today,
                'category': category,
                'tags': tags,
                'content': content,
                'publish_date': '',
                'department': department,
                'attachments': [],
                'source_url': page_url,
                'teacher_published': True,
            }
            notices.insert(0, new_item)

            tmp = notices_file + '.tmp'
            with open(tmp, 'w', encoding='utf-8') as f:
                json.dump(notices, f, ensure_ascii=False, indent=2)
            os.replace(tmp, notices_file)

            return jsonify({
                'status': 'success',
                'message': '新增成功',
                'notice': new_item,
            }), 201
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500

    @app.route('/api/health', methods=['GET'])
    def health_check():
        return jsonify({'status': 'ok'})

    @app.route('/api/categories', methods=['GET'])
    def get_categories():
        try:
            notices_file = notices_json_path()
            
            if not os.path.exists(notices_file):
                return jsonify({'status': 'error', 'message': '通知数据文件不存在'}), 404
            
            notices = load_notices_json(notices_file)
            
            # 统计分类
            category_stats = {}
            all_tags = set()
            
            for notice in notices:
                category = notice.get('category', '未知')
                tags = notice.get('tags', [])
                
                if category not in category_stats:
                    category_stats[category] = {
                        'count': 0,
                        'tags': set()
                    }
                
                category_stats[category]['count'] += 1
                
                for tag in tags:
                    all_tags.add(tag)
                    category_stats[category]['tags'].add(tag)
            
            categories = []
            for cat, stats in category_stats.items():
                categories.append({
                    'name': cat,
                    'count': stats['count'],
                    'tags': list(stats['tags'])[:10] 
                })
            
            categories.sort(key=lambda x: x['count'], reverse=True)
            
            return jsonify({
                'categories': categories,
                'total_notices': len(notices),
                'all_tags': list(all_tags)[:50] 
            }), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500

    @app.route('/api/crawl/trigger', methods=['POST'])
    def trigger_crawl():
        try:
            from mes import GDUTSpider
            spider = GDUTSpider()
            success = spider.run(max_pages=3)
            if success:
                return jsonify({'status': 'success', 'message': '爬虫运行成功'}), 200
            else:
                return jsonify({'status': 'error', 'message': '爬虫运行失败'}), 500
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500

    @app.route('/api/auth/login', methods=['POST'])
    def login():
        """用户登录/注册接口"""
        try:
            if not request.is_json:
                return jsonify({'status': 'error', 'message': '请求需使用 Content-Type: application/json'}), 400

            data = request.get_json(silent=True)
            if data is None:
                return jsonify({'status': 'error', 'message': '无效的 JSON 请求体'}), 400
            if not isinstance(data, dict):
                return jsonify({'status': 'error', 'message': 'JSON 根须为对象'}), 400

            student_id = (data.get('studentId') or '').strip()
            password = (data.get('password') or '').strip()
            
            if not student_id or not password:
                return jsonify({'status': 'error', 'message': '学号和密码为必填项'}), 400

            if len(student_id) < 8:
                return jsonify({'status': 'error', 'message': '学号长度至少为8位'}), 400

            if len(password) < 6:
                return jsonify({'status': 'error', 'message': '密码长度至少为6位'}), 400

            # 加载用户数据
            users = load_users_json()

            # 检查用户是否存在
            if student_id in users:
                # 用户存在，验证密码
                hashed_pwd = users[student_id]['password']
                if hash_password(password) != hashed_pwd:
                    return jsonify({'status': 'error', 'message': '密码错误'}), 401
            else:
                # 用户不存在，自动注册
                users[student_id] = {
                    'password': hash_password(password),
                    'created_at': date.today().isoformat()
                }
                save_users_json(users)

            return jsonify({'status': 'success', 'message': '登录成功'}), 200
        except Exception as e:
            return jsonify({'status': 'error', 'message': str(e)}), 500

    return app

if __name__ == '__main__':
    app = create_app()
    # 默认监听所有网卡，局域网/其它机器可通过本机 IP 访问（勿用 127.0.0.1 作为 bind 地址）
    host = os.environ.get('HOST', '0.0.0.0')
    port = int(os.environ.get('PORT', '5000'))
    app.run(host=host, port=port, debug=False)