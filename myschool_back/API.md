# Myschool Back — API 与使用说明

> **完整后端说明**（架构、数据、部署、排查）见同目录 **[《后端说明书.md》](./后端说明书.md)**。

## 1. 基础信息

| 项 | 说明 |
|----|------|
| 协议 | HTTP |
| 数据格式 | JSON，`UTF-8`，中文不转义为 `\uXXXX` |
| 跨域 | 已启用 CORS，浏览器前端可直接调用 |
| 默认监听 | **`0.0.0.0`**（所有网卡），端口默认 `5000` |

服务绑定在 **`0.0.0.0`**，不是只监听 `127.0.0.1`，因此：

- 本机访问：`http://127.0.0.1:<端口>` 或 `http://localhost:<端口>`
- 同一局域网内其它设备：`http://<这台电脑的局域网IP>:<端口>`（如 `http://192.168.1.10:5000`）

若系统防火墙拦截入站连接，需在系统设置中允许 Python/终端，或为该端口放行。

> **端口提示**：若本机 5000 被占用（常见于 macOS AirPlay），请设置环境变量 `PORT` 或换端口。下文用 `{base}` 表示 `http://<主机>:<端口>`。

### 启动服务

```bash
cd /path/to/myschool_back
pip install -r requirements.txt
python app.py
```

可选环境变量（不设则使用默认值）：

| 变量 | 默认 | 说明 |
|------|------|------|
| `HOST` | `0.0.0.0` | 监听地址；保持 `0.0.0.0` 即可对外网卡开放 |
| `PORT` | `5000` | 监听端口 |

示例（端口 5001）：

```bash
PORT=5001 python app.py
```

---

## 2. 通知条目结构（列表 `items` 中单条）

数据来自 `gdut_notices.json`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `title` | string | 标题 |
| `url` | string | 通知链接 |
| `date` | string | 日期（如 `2026-03-30`） |
| `category` | string | 分类（筛选时需与存储值**完全一致**） |
| `tags` | string[] | 标签 |
| `content` | string | 正文 |
| `publish_date` | string | 可为空 |
| `department` | string | 可为空 |
| `attachments` | array | 附件 |
| `source_url` | string | 来源页 URL |

---

## 3. 接口列表

### 3.1 健康检查

| 项 | 内容 |
|----|------|
| **方法 / 路径** | `GET /api/health` |
| **说明** | 判断服务是否存活 |

**响应 200**

```json
{ "status": "ok" }
```

---

### 3.2 通知列表（分页 + 筛选）

| 项 | 内容 |
|----|------|
| **方法 / 路径** | `GET /api/notices` |

**Query 参数**

| 参数 | 类型 | 必填 | 默认 | 说明 |
|------|------|------|------|------|
| `page` | int | 否 | `1` | 页码，从 1 开始 |
| `per_page` | int | 否 | `10` | 每页条数 |
| `keyword` | string | 否 | 空 | 标题**子串**匹配 |
| `category` | string | 否 | 空 | 分类**全等**匹配 |
| `tag` | string | 否 | 空 | `tags` 数组中**包含**该字符串 |

`keyword`、`category`、`tag` 同时存在时为 **AND**；先过滤再分页。

**响应 200**

```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "per_page": 10,
  "pages": 0
}
```

- `pages` = `⌈total / per_page⌉`（实现为整数除法向上取整）。

**无数据文件时的行为**：若不存在 `gdut_notices.json`，会尝试运行爬虫 `mes.GDUTSpider`（最多 3 页）生成文件；失败则 **500**：

```json
{ "status": "error", "message": "无法获取通知数据: ..." }
```

**文件存在但 JSON 不合法**：若 `gdut_notices.json` 存在却非合法 JSON（常见原因：某条 `content` 在**未闭合的双引号字符串内**被错误换行，下一行单独出现 `",`），服务端会尝试**自动合并**这类断行后再 `json.loads`；若仍失败则 **500**，`message` 中多为 `Invalid control character ...` 等解析错误。写入数据时请保证整文件可被标准 JSON 解析，或依赖上述容错逻辑。

**其它异常**：**500**，`{ "status": "error", "message": "..." }`。

**示例**

```http
GET {base}/api/notices?page=1&per_page=10
GET {base}/api/notices?keyword=清明节
GET {base}/api/notices?category=综合通知
GET {base}/api/notices?tag=教学
GET {base}/api/notices?category=教务通知&keyword=教学计划&page=1&per_page=5
```

---

### 3.3 分类与标签统计

| 项 | 内容 |
|----|------|
| **方法 / 路径** | `GET /api/categories` |
| **说明** | 基于当前 `gdut_notices.json` 统计，**不触发爬虫** |

**文件不存在**：**404**

```json
{ "status": "error", "message": "通知数据文件不存在" }
```

**响应 200**

```json
{
  "categories": [
    {
      "name": "综合通知",
      "count": 5,
      "tags": ["教学", "考试"]
    }
  ],
  "total_notices": 37,
  "all_tags": ["教学", "考试"]
}
```

- 每个分类下的 `tags` 最多返回 **10** 个；`all_tags` 最多 **50** 个（实现限制）。

---

### 3.4 手动触发爬虫

| 项 | 内容 |
|----|------|
| **方法 / 路径** | `POST /api/crawl/trigger` |
| **请求体** | 无（可空） |
| **说明** | 调用 `GDUTSpider().run(max_pages=3)`，更新本地 JSON |

**成功 200**

```json
{ "status": "success", "message": "爬虫运行成功" }
```

**爬虫失败 500**

```json
{ "status": "error", "message": "爬虫运行失败" }
```

**异常 500**：`{ "status": "error", "message": "..." }`

> 请求可能较慢，前端建议设置较长超时与 loading。当前**无鉴权**，公网部署请自行加固。

---

### 3.5 新增通知

| 项 | 内容 |
|----|------|
| **方法 / 路径** | `POST /api/notices/add` |
| **请求头** | `Content-Type: application/json` |

**请求体 JSON 字段**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `title` | string | 是 | 去空格后非空 |
| `category` | string | 是 | 去空格后非空 |
| `content` | string | 是 | 去空格后非空 |
| `department` | string | 否 | 默认空 |
| `tags` | string | 否 | 多个标签用**英文逗号**分隔，如 `教学,通知`；服务端拆成数组；省略或空串表示无标签 |

**成功 201**

```json
{
  "status": "success",
  "message": "新增成功",
  "notice": { }
}
```

`notice` 为完整通知对象，字段与 §2 列表项一致（另可能含 `teacher_published` 等扩展字段）。

**失败**

- **400**：非 JSON、`Content-Type` 非 JSON、根非对象、`tags` 类型错误、必填缺失或为空等。
- **404**：`gdut_notices.json` 不存在。
- **500**：其它异常。

---

## 4. 联调建议

1. 先请求 `GET /api/health` 确认服务与端口。
2. 分类筛选用 `GET /api/categories` 返回的 `categories[].name` 作为 `category` 参数，避免拼写不一致。
3. 查询串含中文时注意 UTF-8 编码（浏览器通常自动处理）。
4. iOS 真机联调时，客户端默认示例端口常为 **5001**（避免与 macOS AirPlay 占用 5000 冲突）；请与启动后端时设置的 `PORT` 一致，并在 App「设置 → 校园通知接口」中填写根地址（如 `http://192.168.1.10:5001`），勿带路径后缀如 `/api/notices`。
5. 教师端新增通知使用 `POST /api/notices/add`，`tags` 须为英文逗号分隔的字符串；成功返回 **HTTP 201**。

---

## 5. 依赖

见项目根目录 `requirements.txt`（Flask、flask-cors、requests、beautifulsoup4 等）。

---

## 6. 自动化测试

- **单元 / 接口测试**：在 `myschool_back` 目录执行 `pip install -r requirements-dev.txt` 后运行 `python3 -m pytest tests/ -v`。测试通过环境变量 `MYSCHOOL_NOTICES_PATH` 指向临时 JSON，不修改仓库内 `gdut_notices.json`。
- **一键脚本**（仓库内 iOS 工程 `scripts/run_all_tests.sh`）：依次运行上述 pytest 与 `xcodebuild` 编译主 App。若本机已启动后端，可执行 `RUN_LIVE=1 BASE_URL=http://127.0.0.1:5001 bash scripts/run_all_tests.sh` 额外跑 `verify_notice_api.sh`（含 `POST /api/notices/add` 烟测，会在服务器数据文件写入一条 `_curl_verify_` 标题的通知）。
