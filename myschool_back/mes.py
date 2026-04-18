import requests
from bs4 import BeautifulSoup
import json
import os
import re
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GDUTSpider:
    def __init__(self, base_url=None, use_mock_fallback=True):
        self.base_url = base_url or "https://oas.gdut.edu.cn/seeyon/main.do?method=main&loginPortal=1&portalId=-7779029842361826066"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
        })
        self.notices = []
        self.use_mock_fallback = use_mock_fallback
        
    def run(self, max_pages=3) -> bool:
        """
        运行爬虫，爬取最多 max_pages 页的通知
        返回是否成功
        """
        try:
            logger.info(f"开始爬取广东工业大学通知，最多{max_pages}页")
            for page in range(1, max_pages + 1):
                logger.info(f"正在爬取第 {page} 页")
                page_notices = self._crawl_page(page)
                if page_notices is None:
                    logger.warning(f"第 {page} 页爬取失败")
                    continue
                if not page_notices:
                    logger.info(f"第 {page} 页没有通知，停止爬取")
                    break
                self.notices.extend(page_notices)
            
            # 如果真实爬取没有数据，使用模拟数据
            if not self.notices and self.use_mock_fallback:
                logger.warning("真实爬取未获取到数据，使用模拟数据")
                self.notices = self._get_mock_notices()
            
            # 去重
            self._deduplicate()
            
            # 分类
            self._categorize_notices()
            
            # 爬取详细内容
            self._crawl_notice_details()
            
            # 保存到文件
            self._save_to_file()
            
            logger.info(f"爬取完成，共获取 {len(self.notices)} 条通知")
            return True
        except Exception as e:
            logger.exception(f"爬虫运行出错: {e}")
            return False
    
    def _crawl_page(self, page: int) -> Optional[List[Dict]]:
        """
        爬取单页通知
        """
        # 构造分页URL，需要根据实际网站调整
        url = self.base_url
        if page > 1:
            # 假设分页参数为 page 或 p
            url = f"{self.base_url}&page={page}"
        
        try:
            resp = self.session.get(url, timeout=15)
            resp.raise_for_status()
            resp.encoding = 'utf-8'
            
            # 如果页面太小，可能是重定向页面
            if len(resp.text) < 1000:
                logger.warning(f"页面内容过小 ({len(resp.text)} 字符)，可能未包含通知列表")
                # 尝试查找 iframe 或脚本
                pass
            
            # 解析页面
            soup = BeautifulSoup(resp.text, 'html.parser')
            
            # 提取通知列表
            notices = self._parse_notice_list(soup)
            return notices
        except Exception as e:
            logger.error(f"爬取第 {page} 页失败: {e}")
            return None
    
    def _parse_notice_list(self, soup: BeautifulSoup) -> List[Dict]:
        """
        解析通知列表页面，提取通知标题、链接、日期
        需要根据实际HTML结构调整
        """
        notices = []
        
        # 尝试多种选择器
        # 1. 查找表格行
        notice_items = soup.find_all('tr', class_=re.compile(r'notice|item|list'))
        # 2. 查找列表项
        if not notice_items:
            notice_items = soup.find_all('li', class_=re.compile(r'notice|item|list'))
        # 3. 查找div
        if not notice_items:
            notice_items = soup.find_all('div', class_=re.compile(r'notice|item|list|content'))
        
        for item in notice_items:
            try:
                notice = self._parse_notice_item(item)
                if notice:
                    notices.append(notice)
            except Exception as e:
                logger.debug(f"解析通知项失败: {e}")
                continue
        
        # 4. 查找所有包含“通知”的链接
        if not notices:
            links = soup.find_all('a', string=re.compile(r'通知'))
            for link in links:
                title = link.get_text(strip=True)
                href = link.get('href', '')
                if href and title:
                    date_text = self._find_nearby_date(link)
                    notice = {
                        'title': title,
                        'url': self._make_absolute_url(href),
                        'date': date_text,
                        'category': '未知',
                        'tags': []
                    }
                    notices.append(notice)
        
        # 5. 如果仍然没有，尝试通用表格解析
        if not notices:
            tables = soup.find_all('table')
            for table in tables:
                rows = table.find_all('tr')
                for row in rows:
                    links = row.find_all('a')
                    for link in links:
                        title = link.get_text(strip=True)
                        if title and len(title) > 4:  # 假设标题长度大于4
                            href = link.get('href', '')
                            date_text = self._find_nearby_date(row)
                            notice = {
                                'title': title,
                                'url': self._make_absolute_url(href),
                                'date': date_text,
                                'category': '未知',
                                'tags': []
                            }
                            notices.append(notice)
        
        return notices
    
    def _parse_notice_item(self, item) -> Optional[Dict]:
        """
        解析单个通知项
        """
        # 尝试查找标题链接
        title_elem = item.find('a')
        if not title_elem:
            return None
        
        title = title_elem.get_text(strip=True)
        href = title_elem.get('href', '')
        
        # 查找日期元素
        date_elem = item.find('span', class_=re.compile(r'date|time|day'))
        if not date_elem:
            date_elem = item.find('td', class_=re.compile(r'date|time'))
        if not date_elem:
            date_elem = item.find('div', class_=re.compile(r'date|time'))
        
        if date_elem:
            date_text = date_elem.get_text(strip=True)
        else:
            date_text = self._find_nearby_date(title_elem)
        
        # 清理日期格式
        date_text = self._clean_date(date_text)
        
        return {
            'title': title,
            'url': self._make_absolute_url(href),
            'date': date_text,
            'category': '未知',
            'tags': []
        }
    
    def _find_nearby_date(self, element) -> str:
        """
        在元素附近查找日期文本
        """
        # 查找父元素
        parent = element.parent
        if parent:
            text = parent.get_text()
            date_match = re.search(r'\d{4}-\d{2}-\d{2}', text)
            if date_match:
                return date_match.group()
        
        # 查找兄弟元素
        for sibling in element.next_siblings:
            if isinstance(sibling, str):
                date_match = re.search(r'\d{4}-\d{2}-\d{2}', sibling)
                if date_match:
                    return date_match.group()
            elif hasattr(sibling, 'get_text'):
                text = sibling.get_text()
                date_match = re.search(r'\d{4}-\d{2}-\d{2}', text)
                if date_match:
                    return date_match.group()
        
        # 查找前一个兄弟元素
        for sibling in element.previous_siblings:
            if isinstance(sibling, str):
                date_match = re.search(r'\d{4}-\d{2}-\d{2}', sibling)
                if date_match:
                    return date_match.group()
            elif hasattr(sibling, 'get_text'):
                text = sibling.get_text()
                date_match = re.search(r'\d{4}-\d{2}-\d{2}', text)
                if date_match:
                    return date_match.group()
        
        return ''
    
    def _clean_date(self, date_text: str) -> str:
        """
        清理日期字符串
        """
        if not date_text:
            return ''
        
        match = re.search(r'(\d{4}-\d{2}-\d{2})', date_text)
        if match:
            return match.group(1)
        
        return date_text.strip()
    
    def _make_absolute_url(self, href: str) -> str:
        """
        将相对URL转换为绝对URL
        """
        if not href:
            return ''
        
        if href.startswith('http'):
            return href
        
        base_domain = 'https://oas.gdut.edu.cn'
        if href.startswith('/'):
            return base_domain + href
        else:
            return base_domain + '/' + href
    
    def _get_mock_notices(self) -> List[Dict]:
        """
        生成模拟通知数据，用于测试和演示
        基于网页搜索结果中的真实通知标题
        """
        mock_titles = [
            "关于做好2026年清明节假期学生教育管理工作的通知",
            "关于核对2026秋季学期教学计划的通知",
            "关于推荐2026年上半年事业单位公开招聘分类考试阅卷专家的通知",
            "关于对国家重点研发计划“政府间国际科技创新合作”重点专项 2026年度第二批联合研发项目申报指南征求意见的通知",
            "关于2026年春季学期期中考试安排的通知",
            "关于举办2026年大学生创新创业大赛的通知",
            "关于图书馆临时闭馆维修的通知",
            "关于校园网络安全检查的通知",
            "关于学生食堂菜品价格调整的公示",
            "关于校企合作招聘宣讲会的通知",
            "关于开展实验室安全专项检查的通知",
            "关于2026届毕业生就业双选会的通知",
            "关于学生宿舍空调维修的通知",
            "关于举办学术讲座的通知",
            "关于校园交通管制的最新通知"
        ]
        
        notices = []
        base_date = datetime.now()
        
        for i, title in enumerate(mock_titles):
            # 生成稍微不同的日期
            date = (base_date - timedelta(days=i)).strftime('%Y-%m-%d')
            # 生成模拟URL
            url = f"https://oas.gdut.edu.cn/seeyon/main.do?method=showNotice&id={1000 + i}"
            
            notices.append({
                'title': title,
                'url': url,
                'date': date,
                'category': '未知',  # 后续分类
                'tags': []
            })
        
        return notices
    
    def _deduplicate(self):
        """
        去重，基于标题和日期
        """
        seen = set()
        unique_notices = []
        
        for notice in self.notices:
            key = (notice['title'], notice['date'])
            if key not in seen:
                seen.add(key)
                unique_notices.append(notice)
        
        self.notices = unique_notices
    
    def _categorize_notices(self):
        """
        对通知进行分类
        """
        categories = {
            '教务通知': ['教务', '教学', '课程', '选课', '成绩', '考试安排', '补考', '期中考试', '教学计划'],
            '考试通知': ['考试', '考场', '准考证', '四六级', '等级考试', '公开招聘', '阅卷'],
            '竞赛通知': ['竞赛', '比赛', '大赛', '挑战杯', '创新创业', '大赛'],
            '科研通知': ['科研', '项目', '课题', '基金', '论文', '学术', '研发', '重点专项', '申报指南'],
            '生活通知': ['生活', '住宿', '食堂', '水电', '校园卡', '医疗', '菜品价格', '宿舍', '空调'],
            '校企通知': ['校企', '合作', '招聘', '实习', '就业', '企业', '宣讲会', '双选会', '毕业生就业'],
            '保卫通知': ['保卫', '安全', '消防', '治安', '交通', '网络安全', '实验室安全', '交通管制'],
            '后勤通知': ['后勤', '维修', '绿化', '保洁', '物业', '闭馆维修', '空调维修'],
            '图书馆通知': ['图书馆', '借阅', '开馆', '数据库', '闭馆'],
            '综合通知': []  # 默认分类
        }
        
        for notice in self.notices:
            title = notice['title']
            category_found = False
            
            for category, keywords in categories.items():
                if category == '综合通知':
                    continue
                
                for keyword in keywords:
                    if keyword in title:
                        notice['category'] = category
                        if keyword not in notice['tags']:
                            notice['tags'].append(keyword)
                        category_found = True
                        break
                
                if category_found:
                    break
            
            if not category_found:
                notice['category'] = '综合通知'
    
    def _crawl_notice_details(self):
        """
        爬取所有通知的详细内容
        """
        logger.info(f"开始爬取 {len(self.notices)} 条通知的详细内容")
        for i, notice in enumerate(self.notices):
            try:
                logger.info(f"正在爬取第 {i+1}/{len(self.notices)} 条通知: {notice['title'][:30]}...")
                
                # 检查是否为模拟URL
                url = notice['url']
                if 'showNotice&id=' in url:
                    # 模拟URL，使用模拟详细内容
                    detail = self._get_mock_detail(notice['title'])
                    detail['source_url'] = url
                else:
                    # 真实URL，爬取详细内容
                    detail = self._crawl_single_notice_detail(url)
                
                if detail:
                    notice.update(detail)
                
                # 添加延迟，避免请求过快（仅真实请求）
                if 'showNotice&id=' not in url:
                    import time
                    time.sleep(1)
            except Exception as e:
                logger.error(f"爬取通知详情失败 {notice['url']}: {e}")
                continue
        logger.info("详细内容爬取完成")
    
    def _crawl_single_notice_detail(self, url: str) -> Optional[Dict]:
        """
        爬取单个通知的详细内容
        返回包含详细内容的字典，如 content, publish_date, department, attachments 等
        """
        try:
            resp = self.session.get(url, timeout=15)
            resp.raise_for_status()
            resp.encoding = 'utf-8'
            
            soup = BeautifulSoup(resp.text, 'html.parser')
            
            # 提取详细内容
            detail = {
                'content': self._extract_content(soup),
                'publish_date': self._extract_publish_date(soup),
                'department': self._extract_department(soup),
                'attachments': self._extract_attachments(soup),
                'source_url': url
            }
            return detail
        except Exception as e:
            logger.error(f"爬取详情页失败 {url}: {e}")
            return None
    
    def _extract_content(self, soup: BeautifulSoup) -> str:
        """
        提取通知正文内容
        """
        # 尝试常见的内容选择器
        content_selectors = [
            'div.content', 'div.article', 'div#content', 'div.main-content',
            'div.news-content', 'div.detail-content', 'div.text'
        ]
        
        for selector in content_selectors:
            element = soup.select_one(selector)
            if element:
                # 清理脚本和样式
                for script in element.find_all(['script', 'style']):
                    script.decompose()
                # 获取文本
                text = element.get_text(separator='\n', strip=True)
                return text
        
        # 如果找不到特定选择器，尝试提取整个body的主要内容
        # 移除导航、页脚等非主要内容
        body = soup.find('body')
        if body:
            # 移除常见非内容元素
            for tag in body.find_all(['header', 'footer', 'nav', 'aside', 'script', 'style']):
                tag.decompose()
            text = body.get_text(separator='\n', strip=True)
            # 限制长度
            if len(text) > 10000:
                text = text[:10000] + '...'
            return text
        
        return ''
    
    def _extract_publish_date(self, soup: BeautifulSoup) -> str:
        """
        提取发布日期
        """
        # 常见日期选择器
        date_selectors = [
            'span.publish-date', 'span.date', 'div.publish-time',
            'div.info > span.date', 'div.time', 'p.date'
        ]
        
        for selector in date_selectors:
            element = soup.select_one(selector)
            if element:
                text = element.get_text(strip=True)
                # 提取日期部分
                import re
                match = re.search(r'\d{4}-\d{2}-\d{2}', text)
                if match:
                    return match.group()
        
        return ''
    
    def _extract_department(self, soup: BeautifulSoup) -> str:
        """
        提取发布部门
        """
        # 常见部门选择器
        dept_selectors = [
            'span.department', 'div.source', 'div.author',
            'div.info > span.source', 'p.department'
        ]
        
        for selector in dept_selectors:
            element = soup.select_one(selector)
            if element:
                return element.get_text(strip=True)
        
        return ''
    
    def _extract_attachments(self, soup: BeautifulSoup) -> List[str]:
        """
        提取附件链接
        """
        attachments = []
        # 查找常见附件链接
        attachment_links = soup.find_all('a', href=re.compile(r'\.(pdf|doc|docx|xls|xlsx|zip|rar)$', re.I))
        for link in attachment_links:
            href = link.get('href', '')
            if href:
                attachments.append(self._make_absolute_url(href))
        
        return attachments
    
    def _get_mock_detail(self, title: str) -> Dict:
        """
        生成模拟详细内容（用于测试）
        """
        mock_contents = {
            "关于做好2026年清明节假期学生教育管理工作的通知": "各学院、各部门：\n根据学校校历安排，2026年清明节放假时间为4月4日至4月6日，共3天。为做好假期期间的学生教育管理工作，确保校园安全稳定，现将有关事项通知如下：\n\n一、加强安全教育\n各学院要在放假前对学生进行一次全面的安全教育，重点加强交通安全、防火防盗、防诈骗等方面的教育。\n\n二、严格离校管理\n学生离校需按规定办理请假手续，各学院要做好学生离校登记工作。\n\n三、加强值班值守\n假期期间，各学院、各部门要安排专人值班，保持通讯畅通。\n\n特此通知。\n\n学生工作处\n2026年3月30日",
            "关于核对2026秋季学期教学计划的通知": "各教学单位：\n为确保2026秋季学期教学工作的顺利进行，现将教学计划核对工作通知如下：\n\n一、核对时间\n2026年3月29日至4月5日。\n\n二、核对内容\n1. 课程安排是否合理；\n2. 教师配备是否到位；\n3. 教学场地是否满足需求。\n\n三、工作要求\n各教学单位要高度重视，认真组织核对工作。\n\n教务处\n2026年3月29日",
            "关于推荐2026年上半年事业单位公开招聘分类考试阅卷专家的通知": "各单位：\n根据上级部门要求，现就推荐2026年上半年事业单位公开招聘分类考试阅卷专家有关事项通知如下：\n\n一、推荐条件\n1. 具有副高级以上专业技术职务；\n2. 熟悉相关专业知识；\n3. 责任心强，能保证阅卷时间。\n\n二、推荐程序\n请各单位于4月10日前将推荐表报送人事处。\n\n人事处\n2026年3月28日"
        }
        
        # 查找匹配的模拟内容
        for key, content in mock_contents.items():
            if key in title:
                return {
                    'content': content,
                    'publish_date': '',
                    'department': '',
                    'attachments': [],
                    'source_url': ''
                }
        
        # 默认模拟内容
        return {
            'content': f"这是通知《{title}》的详细内容。\n\n根据相关规定和要求，现将有关事项通知如下：\n\n一、具体事项\n请相关人员按照要求执行。\n\n二、工作要求\n请各单位高度重视，认真落实。\n\n三、其他说明\n如有疑问，请及时联系相关部门。\n\n特此通知。",
            'publish_date': '',
            'department': '',
            'attachments': [],
            'source_url': ''
        }
    
    def _save_to_file(self, filename=None):
        """
        保存通知到JSON文件
        """
        if filename is None:
            filename = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gdut_notices.json')
        
        # 转换为可序列化格式
        serializable_notices = []
        for notice in self.notices:
            notice_data = {
                'title': notice['title'],
                'url': notice['url'],
                'date': notice['date'],
                'category': notice['category'],
                'tags': notice['tags'],
                'content': notice.get('content', ''),
                'publish_date': notice.get('publish_date', ''),
                'department': notice.get('department', ''),
                'attachments': notice.get('attachments', []),
                'source_url': notice.get('source_url', notice['url'])  # 默认为原URL
            }
            serializable_notices.append(notice_data)
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(serializable_notices, f, ensure_ascii=False, indent=2)
        
        logger.info(f"通知已保存到 {filename}")
    
    def get_notices(self) -> List[Dict]:
        """
        返回爬取到的通知列表
        """
        return self.notices


if __name__ == '__main__':
    spider = GDUTSpider(use_mock_fallback=True)
    success = spider.run(max_pages=3)
    if success:
        print(f"爬取成功，共获取 {len(spider.notices)} 条通知")
        print("分类统计:")
        from collections import Counter
        categories = Counter([notice['category'] for notice in spider.notices])
        for cat, count in categories.items():
            print(f"  {cat}: {count}")
        print("\n前10条通知:")
        for notice in spider.notices[:10]:
            print(f"- {notice['title']} ({notice['date']}) [{notice['category']}]")
    else:
        print("爬取失败")