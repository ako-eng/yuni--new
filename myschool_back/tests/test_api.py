import json
import importlib
from pathlib import Path

import pytest


def test_health_ok(client):
    r = client.get('/api/health')
    assert r.status_code == 200
    assert r.get_json() == {'status': 'ok'}
    assert 'charset=utf-8' in (r.headers.get('Content-Type') or '').lower()


def test_get_notices_pagination_and_shape(client):
    r = client.get('/api/notices', query_string={'page': 1, 'per_page': 10})
    assert r.status_code == 200
    data = r.get_json()
    assert data['total'] == 1
    assert data['page'] == 1
    assert data['per_page'] == 10
    assert data['pages'] == 1
    assert len(data['items']) == 1
    assert data['items'][0]['title'] == 'pytest样例通知'


def test_json_response_body_contains_literal_chinese_not_unicode_escapes(client):
    """Flask 3 需 app.json.ensure_ascii=False，否则正文里全是 \\uXXXX，浏览器像乱码。"""
    r = client.get('/api/notices', query_string={'page': 1, 'per_page': 1})
    assert r.status_code == 200
    raw = r.data.decode('utf-8')
    assert '综合通知' in raw
    assert '\\u7efc' not in raw


def test_get_notices_keyword_filter(client):
    r = client.get('/api/notices', query_string={'keyword': '不存在的关键词xyz'})
    assert r.status_code == 200
    data = r.get_json()
    assert data['total'] == 0
    assert data['items'] == []


def test_get_notices_category_filter(client):
    r = client.get('/api/notices', query_string={'category': '综合通知'})
    assert r.status_code == 200
    assert r.get_json()['total'] == 1

    r2 = client.get('/api/notices', query_string={'category': '其它分类'})
    assert r2.get_json()['total'] == 0


def test_get_notices_tag_filter(client):
    r = client.get('/api/notices', query_string={'tag': '教学'})
    assert r.status_code == 200
    assert r.get_json()['total'] == 1

    r2 = client.get('/api/notices', query_string={'tag': '无此标签'})
    assert r2.get_json()['total'] == 0


def test_get_categories_ok(client):
    r = client.get('/api/categories')
    assert r.status_code == 200
    data = r.get_json()
    assert data['total_notices'] == 1
    assert len(data['categories']) >= 1
    names = [c['name'] for c in data['categories']]
    assert '综合通知' in names


def test_categories_404_missing_file(tmp_path, monkeypatch):
    missing = str(tmp_path / 'nope.json')
    monkeypatch.setenv('MYSCHOOL_NOTICES_PATH', missing)
    import app as app_mod

    importlib.reload(app_mod)
    c = app_mod.create_app().test_client()
    r = c.get('/api/categories')
    assert r.status_code == 404
    assert '不存在' in r.get_json().get('message', '')


def test_add_notice_201_and_tags_string(client, notices_path):
    payload = {
        'title': ' 新增标题 ',
        'category': '教务通知',
        'content': '新增正文',
        'department': '测试部',
        'tags': 'a,b, c',
    }
    r = client.post(
        '/api/notices/add',
        data=json.dumps(payload),
        content_type='application/json',
    )
    assert r.status_code == 201
    body = r.get_json()
    assert body['status'] == 'success'
    assert 'notice' in body
    assert body['notice']['tags'] == ['a', 'b', 'c']
    assert body['notice']['title'] == '新增标题'

    disk = json.loads(Path(notices_path).read_text(encoding='utf-8'))
    assert disk[0]['title'] == '新增标题'
    assert len(disk) == 2


def test_add_notice_400_tags_array(client):
    r = client.post(
        '/api/notices/add',
        data=json.dumps(
            {
                'title': 't',
                'category': 'c',
                'content': 'x',
                'tags': ['bad'],
            }
        ),
        content_type='application/json',
    )
    assert r.status_code == 400


def test_add_notice_400_missing_field(client):
    r = client.post(
        '/api/notices/add',
        data=json.dumps({'title': 'only'}),
        content_type='application/json',
    )
    assert r.status_code == 400


def test_add_notice_404_no_file(tmp_path, monkeypatch):
    p = str(tmp_path / 'missing.json')
    monkeypatch.setenv('MYSCHOOL_NOTICES_PATH', p)
    import app as app_mod

    importlib.reload(app_mod)
    c = app_mod.create_app().test_client()
    r = c.post(
        '/api/notices/add',
        data=json.dumps({'title': 't', 'category': 'c', 'content': 'x'}),
        content_type='application/json',
    )
    assert r.status_code == 404


def test_load_notices_json_repair_orphan_quote_line(tmp_path, app_module):
    """错误换行：content 字符串在句号处物理断行且下一行仅为 ", 时应能合并后解析。"""
    bad = (
        '[\n  {\n    "title": "x",\n    "url": "u",\n    "date": "2026-01-01",\n'
        '    "category": "综合通知",\n    "tags": [],\n    "content": "未闭合的一行。\n'
        '",\n    "publish_date": "",\n    "department": "",\n    "attachments": [],\n'
        '    "source_url": "u"\n  }\n]'
    )
    p = tmp_path / 'broken.json'
    p.write_text(bad, encoding='utf-8')
    data = app_module.load_notices_json(str(p))
    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]['content'] == '未闭合的一行。'
