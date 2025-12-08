#!/bin/bash
echo "⚠️ 執行初始化模式 (包含 Setup)..."
echo "執行指令: docker compose -f docker-compose.yml -f docker-compose.setup.yml up -d"
docker compose -f docker-compose.yml -f docker-compose.setup.yml up -d