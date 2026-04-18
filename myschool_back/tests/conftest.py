import json
import importlib
from pathlib import Path

import pytest

SAMPLE_NOTICE = {
    'title': 'pytest样例通知',
    'url': 'http://example.com/pytest-1',
    'date': '2026-01-15',
    'category': '综合通知',
    'tags': ['教学'],
    'content': '正文内容',
    'publish_date': '',
    'department': '教务处',
    'attachments': [],
    'source_url': 'http://example.com/pytest-1',
}


@pytest.fixture
def notices_path(tmp_path: Path) -> str:
    p = tmp_path / 'notices.json'
    p.write_text(json.dumps([SAMPLE_NOTICE], ensure_ascii=False), encoding='utf-8')
    return str(p)


@pytest.fixture
def app_module(monkeypatch, notices_path: str):
    monkeypatch.setenv('MYSCHOOL_NOTICES_PATH', notices_path)
    import app as app_mod

    importlib.reload(app_mod)
    return app_mod


@pytest.fixture
def client(app_module):
    return app_module.create_app().test_client()
