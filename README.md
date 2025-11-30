# ELK Stack with Docker Compose

這是一個基於 Docker Compose 的 ELK (Elasticsearch, Logstash, Kibana) Stack 環境，包含 Metricbeat 監控。

## 目錄結構

- **`start.sh`**: **主要啟動腳本**。會自動判斷是否需要執行初始化。
- **`docker-compose.yml`**: 日常運行的服務定義 (Elasticsearch, Kibana, Logstash, Beats)。
- **`docker-compose.setup.yml`**: 初始化專用的服務定義 (Setup 服務與依賴)。
- **`esdata/`**: Elasticsearch 的數據持久化目錄。**請勿隨意刪除此目錄**，否則會丟失所有索引數據和密碼設定。
- **`certs/`**: 存放 SSL/TLS 憑證的目錄。
- **`logstash/`**: Logstash 的配置與 Pipeline 定義。
- **`metricbeat/`**: Metricbeat 的配置。
- **`.env`**: 環境變數設定（版本、密碼等）。

## 快速開始

無論是首次安裝還是日常重啟，您只需要執行：

```bash
./start.sh
```

腳本會自動判斷：
1. **首次運行** (當 `./certs` 為空)：自動加載 `setup` 服務來生成憑證與設定密碼。
2. **日常運行** (當 `./certs` 存在)：僅啟動核心服務，跳過 `setup` 檢查，加快啟動速度。

## 手動操作 (進階)

如果您想了解腳本背後執行的指令，或是需要手動操作：

### 首次建立環境 (初始化)
```bash
docker compose -f docker-compose.yml -f docker-compose.setup.yml up -d
```
這會合併兩個配置檔案，啟用 `setup` 服務並讓 `es01` 等待它完成。

### 日常啟動
```bash
docker compose up -d
```
這只會讀取 `docker-compose.yml`，不包含 `setup` 服務。

### 停止服務
若要停止服務但**保留容器狀態**：
```bash
docker compose stop
```

若要移除容器但**保留數據**（推薦）：
```bash
docker compose down
```
數據會保留在 `./esdata`，憑證保留在 `./certs`。

### 查看日誌
```bash
docker compose logs -f
# 或查看特定服務
docker compose logs -f logstash
```

## 重置環境

如果您需要完全重置環境（**警告：這將刪除所有數據**）：

1. 停止並移除容器：
   ```bash
   docker compose down
   ```
2. 刪除本地數據與憑證：
   ```bash
   sudo rm -rf esdata/ certs/
   ```
3. 重新執行啟動腳本：
   ```bash
   ./start.sh
   ```

## 正式環境部署 (使用自有憑證)

當您拿到正式的 SSL 憑證（例如 `*.example.com`）時，請依照以下 SOP 進行替換。

### 1. 準備檔案

根據您提供的檔案範例，我們需要將其對應到 ELK 的格式：

| 您的檔案 (範例) | 說明 | 對應 ELK 檔案 | 處理方式 |
| :--- | :--- | :--- | :--- |
| **example_site.crt** | 網站憑證 (Leaf Cert) | `es01.crt` / `kibana.crt` | 需要與 CA Bundle 合併 (見下文) |
| **example_site.key** | 私鑰 (Private Key) | `es01.key` / `kibana.key` | 直接改名使用 |
| **intermediate_ca.crt** | 中繼憑證鏈 (CA Bundle) | `ca.crt` | 直接改名使用 |

> ⚠️ **注意**：`.pfx`, `.p7b` 等格式通常不需要，我們只需要 `.crt` (PEM) 和 `.key`。

### 2. 合併憑證 (建立完整鏈)

為了確保瀏覽器和服務能正確識別，建議將「網站憑證」與「中繼憑證」合併。
(這與您在其他負載平衡器的操作類似，但**不需要**把 Key 放進去)。

**操作方式 (使用文字編輯器)：**
1. 打開一個新檔案。
2. 貼上 **網站憑證** (`example_site.crt`) 的內容。
3. 換行，接著貼上 **中繼憑證鏈** (`intermediate_ca.crt`) 的內容。
4. 存檔為 `full_chain.crt`。

### 3. 放置檔案

請將準備好的檔案複製到 `certs` 目錄下的對應位置，並**覆蓋**或**替換**原有檔案：

**目錄結構：**
```text
certs/
├── ca/
│   └── ca.crt          <-- 放 intermediate_ca.crt
├── es01/
│   ├── es01.crt        <-- 放 full_chain.crt (合併後的檔案)
│   └── es01.key        <-- 放 example_site.key
└── kibana/
    ├── kibana.crt      <-- 放 full_chain.crt (同上)
    └── kibana.key      <-- 放 example_site.key (同上)
```

### 4. 修正權限 (關鍵步驟！)

Docker 內的服務使用特定使用者 ID (UID 1000) 運行。如果您是手動複製檔案進去，權限通常會變成您的使用者，導致服務無法讀取而啟動失敗。

**請務必執行以下指令修正權限：**

```bash
# 1. 將所有憑證擁有者改為 UID 1000 (Elasticsearch/Kibana 使用者)
sudo chown -R 1000:1000 certs/

# 2. 設定檔案權限 (私鑰 600，憑證 644)
sudo find certs -type f -name "*.key" -exec chmod 600 {} \;
sudo find certs -type f -name "*.crt" -exec chmod 644 {} \;
```

### 5. 重啟服務

完成上述步驟後，重啟容器以套用新憑證：

```bash
docker compose restart
```
