#!/bin/bash

# 定義憑證目錄
CERTS_DIR="./certs"

# 檢查憑證目錄是否存在且不為空
if [ -d "$CERTS_DIR" ] && [ "$(ls -A $CERTS_DIR)" ]; then
    echo "✅ 檢測到憑證，執行日常啟動模式..."
    echo "執行指令: docker compose up -d"
    docker compose up -d
else
    echo "⚠️ 未檢測到憑證，執行初始化模式 (包含 Setup)..."
    echo "執行指令: docker compose -f docker-compose.yml -f docker-compose.setup.yml up -d"
    docker compose -f docker-compose.yml -f docker-compose.setup.yml up -d
fi
