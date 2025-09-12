#!/usr/bin/env bash
set -euo pipefail

BASE="project-bundle"
MAX_SIZE=$((3 * 1024 * 1024)) # 3MB
PART=1
CURRENT_FILE="${BASE}-${PART}.md"
CURRENT_SIZE=0
> "$CURRENT_FILE"

# まとめたい拡張子リスト
EXTS=(
  # ソースコード系
  "kt" "kts" "java" "scala" "groovy" "ts" "tsx" "js" "jsx"
  "py" "rb" "go" "rs" "swift" "php" "c" "h" "cpp" "hpp"
  "cs" "vb" "m" "mm" "dart" "clj" "ex" "exs"

  # ビルド・設定系
  "gradle" "pom" "xml" "json" "yaml" "yml" "toml" "ini" "cfg" "conf" "properties"

  # Infra / DevOps 系
  "dockerfile" "sh" "bash" "zsh" "bat" "ps1"
  "tf" "tfvars" "hcl"

  # ドキュメント系
  "md" "markdown" "rst" "txt" "adoc" "org"

  # データ系
  "csv" "tsv" "sql"
)

mapfile -t FILES < <(git ls-files)

for file in "${FILES[@]}"; do
  ext="${file##*.}"
  if [[ " ${EXTS[*]} " == *" $ext "* ]]; then
    header="## $file\n\`\`\`${ext}\n"
    footer="\n\`\`\`\n\n"
    size=$(( ${#header} + $(stat -c%s "$file") + ${#footer} ))

    # 新しいファイルに切り替え
    if (( CURRENT_SIZE + size > MAX_SIZE )); then
      echo "📦 ${CURRENT_FILE} done (size: $CURRENT_SIZE bytes)"
      PART=$((PART+1))
      CURRENT_FILE="${BASE}-${PART}.md"
      > "$CURRENT_FILE"
      CURRENT_SIZE=0
    fi

    # 出力
    echo "## $file" >> "$CURRENT_FILE"
    case "$ext" in
      kt|kts|gradle) echo '```kotlin' >> "$CURRENT_FILE" ;;
      java) echo '```java' >> "$CURRENT_FILE" ;;
      ts|tsx) echo '```ts' >> "$CURRENT_FILE" ;;
      js|jsx) echo '```js' >> "$CURRENT_FILE" ;;
      json) echo '```json' >> "$CURRENT_FILE" ;;
      yml|yaml) echo '```yaml' >> "$CURRENT_FILE" ;;
      toml) echo '```toml' >> "$CURRENT_FILE" ;;
      md|markdown) echo '```markdown' >> "$CURRENT_FILE" ;;
      txt) echo '```text' >> "$CURRENT_FILE" ;;
      py) echo '```python' >> "$CURRENT_FILE" ;;
      go) echo '```go' >> "$CURRENT_FILE" ;;
      rs) echo '```rust' >> "$CURRENT_FILE" ;;
      sh|bash) echo '```bash' >> "$CURRENT_FILE" ;;
      sql) echo '```sql' >> "$CURRENT_FILE" ;;
      xml) echo '```xml' >> "$CURRENT_FILE" ;;
      ini|cfg|properties) echo '```ini' >> "$CURRENT_FILE" ;;
      *) echo '```' >> "$CURRENT_FILE" ;;
    esac

    cat "$file" >> "$CURRENT_FILE"
    echo "" >> "$CURRENT_FILE"
    echo '```' >> "$CURRENT_FILE"
    echo "" >> "$CURRENT_FILE"

    CURRENT_SIZE=$((CURRENT_SIZE + size))
  fi
done

echo "✅ Done! ${PART} file(s) created."

