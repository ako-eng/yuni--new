#!/usr/bin/env python
# -*- coding: utf-8 -*-


import json
import os
import sys
import time
from datetime import datetime

def add_notice_manually(title, category, content, department='', tags=''):
    tag_list = []
    if tags:
        tag_list = [tag.strip() for tag in tags.split(',') if tag.strip()]
    
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    notice_id = int(time.time() * 1000)
    url = f"https://oas.gdut.edu.cn/seeyon/main.do?method=teacherAdded&id={notice_id}"
    
    new_notice = {
        'title': title,
        'url': url,
        'date': current_date,
        'category': category,
        'tags': tag_list,
        'content': content,
        'publish_date': current_date,
        'department': department,
        'attachments': [],
        'source_url': url
    }
    
    notices_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gdut_notices.json')
    notices = []
    
    if os.path.exists(notices_file):
        try:
            with open(notices_file, 'r', encoding='utf-8') as f:
                notices = json.load(f)
        except json.JSONDecodeError as e:
            print(f"警告: JSON文件损坏，将使用空列表。错误: {e}")
            import shutil
            backup_file = notices_file + '.bak'
            shutil.copy2(notices_file, backup_file)
            print(f"已创建备份文件: {backup_file}")
            notices = []
        except Exception as e:
            print(f"警告: 读取通知文件失败: {e}")
            notices = []
    
    notices.insert(0, new_notice)
    
    with open(notices_file, 'w', encoding='utf-8') as f:
        json.dump(notices, f, ensure_ascii=False, indent=2)
    
    print(f"标题: {title}")
    print(f"类型: {category}")
    print(f"日期: {current_date}")
    print(f"发布单位: {department if department else '未指定'}")
    print(f"标签: {tag_list if tag_list else '无'}")
    print(f"通知总数: {len(notices)}")
    
    return new_notice

def interactive_mode():
    
    try:
        title = input("通知标题: ").strip()
        while not title:
            title = input("通知标题: ").strip()
        
        category = input("通知类型（如：教务通知、考试通知、科研通知等）: ").strip()
        while not category:
            category = input("通知类型: ").strip()
        
        print("通知正文（输入空行结束）:")
        content_lines = []
        while True:
            line = input()
            if line == '' and content_lines:
                break
            content_lines.append(line)
        content = '\n'.join(content_lines)
        
        if not content:
            print("警告: 正文为空")
        
        department = input("发布单位（可选）: ").strip()
        tags = input("标签（多个用逗号分隔，可选）: ").strip()
        
        print("\n正在添加通知...")
        add_notice_manually(title, category, content, department, tags)
        
    except KeyboardInterrupt:
        print("\n\n操作已取消")
        return

def main():
    if len(sys.argv) > 1:
        if len(sys.argv) >= 4:
            title = sys.argv[1]
            category = sys.argv[2]
            content = sys.argv[3]
            department = sys.argv[4] if len(sys.argv) > 4 else ''
            tags = sys.argv[5] if len(sys.argv) > 5 else ''
            add_notice_manually(title, category, content, department, tags)
        else:
            print("用法: python teacher_add.py '标题' '类型' '内容' [发布单位] [标签]")
            print("示例: python teacher_add.py '测试通知' '教务通知' '通知内容' '教务处' '教学,通知'")
    else:
        interactive_mode()

if __name__ == '__main__':
    main()