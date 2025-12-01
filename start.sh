#!/bin/bash

# 定義憑證目錄
CERTS_DIR="./certs"

# 偵測主機 IP (取第一個非 Loopback IP)
#export HOST_IP=$(hostname -I | awk '{print $1}')

export HOST_IP="172.21.2.217"

# 如果偵測失敗，預設為 localhost
if [ -z "$HOST_IP" ]; then
    echo "⚠️ 無法偵測到主機 IP，將使用 127.0.0.1"
    export HOST_IP="127.0.0.1"
else
    echo "ℹ️ 偵測到主機 IP: $HOST_IP"
fi

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
