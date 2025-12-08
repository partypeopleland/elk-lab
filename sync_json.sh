#!/bin/bash

# ==============================================================================
# Script Name: sync_json.sh
# Description: Synchronizes two JSON files with specific rules (Add/Remove/Keep).
#              Embeds necessary jq modules for structural synchronization.
# Usage: ./sync_json.sh [source_file] [target_file] [--dry]
# ==============================================================================

# 參數解析
POSITIONAL_ARGS=()
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry)
      DRY_RUN=true
      shift # past argument
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# 設定變數
SOURCE_FILE="${1:-source.json}"
TARGET_FILE="${2:-appsettings.json}"
REPORT_FILE="sync_report.md"
DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
TMP_DIR=$(mktemp -d)

# 顏色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 清理函式 (Script 結束時刪除暫存檔)
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo -e "${YELLOW}=== JSON Sync Tool ===${NC}"
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}[DRY RUN MODE] 僅顯示預期變更，不寫入檔案。${NC}"
fi
echo "來源: $SOURCE_FILE"
echo "目標: $TARGET_FILE"

# 1. 檢查 jq 是否安裝
if ! command -v jq &> /dev/null; then
    echo -e "${RED}錯誤: 未偵測到 jq。請執行 'sudo apt install -y jq' 安裝。${NC}"
    exit 1
fi

# 2. 檢查來源檔案
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}錯誤: 來源檔案 $SOURCE_FILE 不存在。${NC}"
    exit 1
fi

# 3. 處理目標檔案與備份
if [ -f "$TARGET_FILE" ]; then
    if [ "$DRY_RUN" = false ]; then
        BACKUP_NAME="${TARGET_FILE}.$(date +"%Y%m%d_%H%M%S").json"
        cp "$TARGET_FILE" "$BACKUP_NAME"
        echo -e "${GREEN}已建立備份: $BACKUP_NAME${NC}"
    fi
else
    echo "{}" > "$TARGET_FILE"
    echo -e "${YELLOW}目標檔案不存在，已建立新檔案。${NC}"
fi

# ==============================================================================
# 建立嵌入的 JQ 模組檔案
# ==============================================================================

# 模組 1: find_added.jq
cat <<'EOF' > "$TMP_DIR/find_added.jq"
def find_added(path; s_node; t_wrapper):
  if (s_node | type) == "object" then
    reduce (s_node | keys_unsorted | .[]) as $k ([]; 
      . + find_added(
            (if path == "" then $k else path + "." + $k end); 
            s_node[$k]; 
            (if (t_wrapper != null) and (t_wrapper.v | type) == "object" and (t_wrapper.v | has($k))
             then {"v": t_wrapper.v[$k]}
             else null
             end)
          )
    )
  else
    if t_wrapper == null then [path] else [] end
  end;

find_added(""; $s[0]; {"v": $t[0]}) | .[]
EOF

# 模組 2: find_removed.jq
cat <<'EOF' > "$TMP_DIR/find_removed.jq"
def find_removed(path; s_node; t_node):
  if (t_node | type) == "object" then
    reduce (t_node | keys_unsorted | .[]) as $k ([];
      if (s_node | type) != "object" or (s_node | has($k) | not) then
         . + [(if path == "" then $k else path + "." + $k end)]
      else
         . + find_removed(
               (if path == "" then $k else path + "." + $k end); 
               s_node[$k]; 
               t_node[$k]
             )
      end
    )
  else
    [] 
  end;

find_removed(""; $s[0]; $t[0]) | .[]
EOF

# 模組 3: sync.jq
cat <<'EOF' > "$TMP_DIR/sync.jq"
def sync(s_node; t_wrapper):
  if (s_node | type) == "object" then
     reduce (s_node | keys_unsorted | .[]) as $k ({};
       . + { 
         ($k): sync(
           s_node[$k]; 
           (if (t_wrapper != null) and (t_wrapper.v | type) == "object" and (t_wrapper.v | has($k)) 
            then {"v": t_wrapper.v[$k]} 
            else null 
            end)
         ) 
       }
     )
  else
     if t_wrapper != null then t_wrapper.v else "" end
  end;

sync($s[0]; {"v": $t[0]})
EOF

# ==============================================================================
# 4. 產生報告 (Sync Report) 與 顯示差異
# ==============================================================================
echo -e "${YELLOW}正在分析差異...${NC}"

# 初始化報告
if [ "$DRY_RUN" = false ]; then
    echo "# Sync Report" > "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**Target File:** $TARGET_FILE" >> "$REPORT_FILE"
    echo "**Date:** $DATE_STR" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# 分析新增的 Keys
ADDED_KEYS=$(jq -n -r --slurpfile s "$SOURCE_FILE" --slurpfile t "$TARGET_FILE" -f "$TMP_DIR/find_added.jq")

# 分析移除的 Keys
REMOVED_KEYS=$(jq -n -r --slurpfile s "$SOURCE_FILE" --slurpfile t "$TARGET_FILE" -f "$TMP_DIR/find_removed.jq")

# 寫入報告
if [ "$DRY_RUN" = false ]; then
    echo "## 🟢 Added Keys (Set to empty string)" >> "$REPORT_FILE"
    if [ -n "$ADDED_KEYS" ]; then
        echo "$ADDED_KEYS" >> "$REPORT_FILE"
    else
        echo "(None)" >> "$REPORT_FILE"
    fi

    echo -e "\n## 🔴 Removed Keys" >> "$REPORT_FILE"
    if [ -n "$REMOVED_KEYS" ]; then
        echo "$REMOVED_KEYS" >> "$REPORT_FILE"
    else
        echo "(None)" >> "$REPORT_FILE"
    fi
fi

# 顯示在螢幕上
if [ -n "$ADDED_KEYS" ]; then
    echo -e "${GREEN}[新增 Keys]${NC}"
    echo "$ADDED_KEYS"
fi

if [ -n "$REMOVED_KEYS" ]; then
    echo -e "${RED}[刪除 Keys]${NC}"
    echo "$REMOVED_KEYS"
fi

if [ -z "$ADDED_KEYS" ] && [ -z "$REMOVED_KEYS" ]; then
    echo -e "${GREEN}沒有偵測到結構差異。${NC}"
fi

# ==============================================================================
# 5. 執行同步 (Sync Execution)
# ==============================================================================
if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}正在同步 JSON 結構...${NC}"

    jq -n --slurpfile s "$SOURCE_FILE" --slurpfile t "$TARGET_FILE" -f "$TMP_DIR/sync.jq" > "${TARGET_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
        echo -e "${GREEN}同步完成！${NC}"
        echo "報告已產生: $REPORT_FILE"
    else
        echo -e "${RED}同步失敗，jq 執行發生錯誤。${NC}"
        rm -f "${TARGET_FILE}.tmp"
        exit 1
    fi
else
    echo -e "${YELLOW}[DRY RUN] 不執行寫入操作。${NC}"
fi