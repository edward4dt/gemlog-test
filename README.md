# My Gemlog

> 基於 Gemini 協定打造的個人極簡膠囊（Capsule）。內容與主機完全解耦，以 GitHub 作為單一事實來源（Single Source of Truth），具備秒級災難復原能力的純文字個人站點。

---

## 專案特性

- **極簡純文字**：全站採用 Gemtext（`.gmi`），不依賴任何前端框架、CSS、JavaScript 或資料庫。
- **資料高度便攜**：文章全部存放在此儲存庫，伺服器只作為「拋棄式呈現端」，隨時可更換。
- **自動化發布**：提交 Commit 並推送到 `main` 分支時，觸發 GitHub Actions 自動同步到伺服器。
- **原生安全**：Gemini 協定強制使用 TLS 加密傳輸，杜絕明文竊聽與追蹤。

---

## 目錄結構

```text
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions 自動部署腳本
├── posts/                      # 文章收納目錄
│   └── hello-world.gmi         # 文章範本
├── index.gmi                   # 站點首頁
└── README.md

```

---

## 寫作規範（Gemtext 語法速查）

Gemtext 檔案副檔名統一使用 `.gmi`，常見語法規範如下：

```gemtext
# 一級標題
## 二級標題
### 三級標題

一般內文段落直接換行書寫即可。讀者客戶端會自動調整行距與斷行。

* 清單項目 A
* 清單項目 B

> 這是引言區塊

=> /posts/hello-world.gmi 2026-10-02 連結文字（內部文章）
=> [https://example.com](https://example.com) 外部 Web 連結


```

預先格式化文字區塊（程式碼或 ASCII Art）

```

```

---

## 伺服器端環境設定（以 Agate 為例）

伺服器端建議使用 Rust 開發的輕量伺服器 [Agate](https://github.com/mbrubeck/agate)。

### 1. 安裝與目錄建立

```bash
# 建立內容與憑證目錄
sudo mkdir -p /var/gemini/content
sudo mkdir -p /var/gemini/certs

# 下載 Agate 二進位檔
wget [https://github.com/mbrubeck/agate/releases/latest/download/agate-x86_64-unknown-linux-gnu.tar.gz](https://github.com/mbrubeck/agate/releases/latest/download/agate-x86_64-unknown-linux-gnu.tar.gz)
tar -xvf agate-x86_64-unknown-linux-gnu.tar.gz
sudo mv agate /usr/local/bin/

```

### 2. 設定 systemd 服務常駐

建立 `/etc/systemd/system/agate.service`：

```ini
[Unit]
Description=Agate Gemini Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/agate --content /var/gemini/content --certs /var/gemini/certs --hostname yourdomain.tw --lang zh-TW
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

```

啟動服務並設定開機自啟：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now agate

```

---

## CI/CD 部署設定

專案透過 `.github/workflows/deploy.yml` 進行部署。

### 1. 建立專用 SSH Key（於主機執行）

```bash
ssh-keygen -t ed25519 -C "deploy@github-action" -f ~/.ssh/gemlog_deploy
cat ~/.ssh/gemlog_deploy.pub >> ~/.ssh/authorized_keys

```

### 2. GitHub Secrets 設定

前往本儲存庫的 **Settings → Secrets and variables → Actions**，新增以下 Secret：

| 變數名稱 | 說明 |
| --- | --- |
| `SERVER_IP` | 伺服器對外公開 IP 位址 |
| `SERVER_USER` | 登入主機的使用者名稱（如 `root` 或 `ubuntu`） |
| `SSH_PRIVATE_KEY` | 剛剛生成的私鑰內容（`~/.ssh/gemlog_deploy` 全文） |

設定完成後，每次推送到 `main` 分支將自動同步檔案至 `/var/gemini/content`。

---

## DNS 設定注意事項

在網域註冊商或 Cloudflare 新增 A 記錄：

* **名稱 (Name)**：`@` 或 `gemini`
* **內容 (Content)**：主機 IP 位址
* **Proxy 狀態**：**務必關閉代理（DNS Only）**。Cloudflare 免費 CDN 不支援 Gemini 專屬的 `1965` 連接埠。

---

## 災難復原演練（主機損毀或更換）

若現有 VPS 服務終止或硬體故障，請依序執行以下步驟：

1. 開啟一台新 VPS 並安裝 Agate（參考上方「伺服器端環境設定」）。
2. 更新網域 DNS A 記錄指向新主機 IP。
3. 前往 GitHub Repo 修改 `SERVER_IP` 與 `SSH_PRIVATE_KEY`。
4. 手動點擊 GitHub Actions 的 **Run workflow**，站點即刻滿血復原。

```

