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
