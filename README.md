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
