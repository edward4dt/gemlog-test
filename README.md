# Serverless Gemlog

> 基於 Gemini 協定打造的極簡個人膠囊（Capsule）。採用 **Fly.io Scale-to-Zero（無伺服器容器）** 架構，徹底擺脫傳統 VPS 維護負擔，結合 GitHub Actions 實現「推送即發布」的無伺服器工作流。

---

## 為什麼選擇此架構？

- **零作業系統維護**：不需要租用 Linux VPS、無須管理防火牆、不用定期更新系統套件與安全補丁。
- **無連線自動休眠（Scale-to-Zero）**：無人訪問時容器自動掛起（0 CPU / 0 記憶體消耗），有請求時於數百毫秒內冷啟動。
- **原生支援 Port 1965**：突破多數 Serverless 平台僅支援 HTTP/HTTPS 的限制，完整支援 Gemini 專屬 TCP 通訊協定。
- **單一事實來源（SSOT）**：所有文章與設定均由 Git 版本控制，本儲存庫即為完整站點。

---

## 目錄結構

```text
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # 自動建置並部署至 Fly.io
├── posts/                      # 膠囊文章目錄
│   └── hello-world.gmi         # 範例文章
├── Dockerfile                  # 超輕量 Agate 執行映像檔（< 20MB）
├── fly.toml                    # Fly.io 連接埠與休眠規則配置
├── index.gmi                   # 膠囊首頁
└── README.md

```

---

## 快速開始

### 1. 準備必要檔案

`Dockerfile` 與 `fly.toml` 已包含在本儲存庫中，內容如下供參考。

#### `Dockerfile`

```dockerfile
FROM alpine:latest
RUN apk add --no-cache wget ca-certificates \
    && wget -O agate.tar.gz https://github.com/mbrubeck/agate/releases/latest/download/agate-x86_64-unknown-linux-musl.tar.gz \
    && tar -xvf agate.tar.gz -C /usr/local/bin/ \
    && rm agate.tar.gz

WORKDIR /app
COPY . /app/content

# 宣告對外開放 Gemini 協定 Port 1965
EXPOSE 1965

CMD ["agate", "--content", "/app/content", "--certs", "/app/certs", "--hostname", "yourdomain.tw", "--lang", "zh-TW"]
```

> 注意：`CMD` 中的 `--hostname` 請改為你的實際網域（Agate 以此自動取得 TLS 憑證）。

#### `fly.toml`

```toml
app = "my-gemlog"
primary_region = "nrt" # 建議選擇鄰近區域（如東京 nrt 或新加坡 sin）

[build]
  dockerfile = "Dockerfile"

[[services]]
  protocol = "tcp"
  internal_port = 1965
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0

  [[services.ports]]
    port = 1965
```

---

### 2. 初始化 Fly.io 服務

1. 安裝命令列工具並登入：
```bash
# macOS / Linux 安裝
curl -L https://fly.io/install.sh | sh
fly auth login
```

2. 註冊 App（僅建立定義，不立即在本機發布；請將 `my-gemlog` 換成你的唯一 App 名稱）：
```bash
fly launch --no-deploy
```

3. 取得專屬 IPv4 與 IPv6 位址：
```bash
fly ips allocate-v4
fly ips allocate-v6
```

4. 取得 GitHub Actions 部署專用 Token：
```bash
fly tokens create deploy
```

---

### 3. 設定 GitHub Secrets 與 CI/CD

前往 GitHub 儲存庫的 **Settings → Secrets and variables → Actions**，新增以下 Secret：

| Secret 名稱 | 內容說明 |
| --- | --- |
| `FLY_API_TOKEN` | 剛才由 `fly tokens create deploy` 生成的 Token 憑證 |

`.github/workflows/deploy.yml` 已包含在本儲存庫中：

```yaml
name: Deploy to Fly.io

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    name: Deploy Capsule
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup flyctl
        uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Deploy App
        run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

> 本專案額外啟用了 `workflow_dispatch`，可在 **Actions → Deploy to Fly.io → Run workflow** 手動觸發重新發布。

---

### 4. 設定 DNS 記錄

至網域託管商（如 Cloudflare、Namecheap）加入解析：

| 類型 | 名稱 (Name) | 內容 (Content) | 代理狀態 |
| --- | --- | --- | --- |
| **A** | `@` (或子網域) | `fly ips allocate-v4` 取得的 IP | **僅限 DNS（關閉 CDN 代理）** |
| **AAAA** | `@` (或子網域) | `fly ips allocate-v6` 取得的 IP | **僅限 DNS（關閉 CDN 代理）** |

> **提示**：Cloudflare 免費 CDN 無法轉發 Port 1965 流量，因此必須保持灰色雲朵（DNS Only）。

---

## Gemtext 語法規範速查

Gemtext（`.gmi`）採用純文字超輕量排版，支援以下 6 種核心標記：

```gemtext
# 一級標題（站點名稱）
## 二級標題（文章章節）
### 三級標題

一般內文段落直接書寫，斷行由讀者客戶端排版引擎自動計算。

* 無序清單項目 1
* 無序清單項目 2

> 引言或註解區塊

=> /posts/hello-world.gmi 2026-10-02 第一篇文章連結（站內）
=> https://example.com 外部網頁超連結
```

預先格式化的程式碼區塊、ASCII 表格或文本，以三個反引號 ``` 包圍。

---

## 日常寫作流程

1. 在本機撰寫新文章存至 `posts/my-post.gmi`。
2. 在 `index.gmi` 加入文章連結索引：
```gemtext
=> /posts/my-post.gmi 2026-10-02 我的最新文章
```

3. 提交並推送至 GitHub：
```bash
git add .
git commit -m "feat: publish my-post"
git push origin main
```

4. GitHub Actions 自動建置 Docker 映像檔並更新至 Fly.io，約 1 分鐘內即可透過 Gemini 瀏覽器閱讀更新。

---

## 災難復原（Serverless 版）

由於整個站點就是這個 Git 儲存庫，且執行環境為 Fly.io 上的拋棄式容器：

1. 若 App 異常，直接在 GitHub Actions 手動 **Run workflow** 重新部署。
2. 若需更換平台／區域，修改 `fly.toml`（如 `primary_region`）後推送，或改 DNS A/AAAA 記錄指向新 IP。
3. 歷史文章存在 Git 版本控制中，一篇也不會丟失。
