#!/bin/bash
# 偵測主機 IP (取第一個非 Loopback IP)
export HOST_IP=$(hostname -I | awk '{print $1}')

# 如果偵測失敗，預設為 localhost
if [ -z "$HOST_IP" ]; then
    echo "⚠️ 無法偵測到主機 IP，將使用 127.0.0.1"
fi

echo "ℹ️ 偵測到主機 IP: $HOST_IP"
echo "⚠️ 執行初始化模式 (包含 Setup)..."
echo "執行指令: docker compose -f docker-compose.yml -f docker-compose.setup.yml up -d"
docker compose -f docker-compose.yml -f docker-compose.setup.yml up -d