#!/usr/bin/env bash
set -euo pipefail

OUTPUT="project-bundle.md"
> "$OUTPUT"

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

# Git 管理下のファイル一覧を配列に取得
mapfile -t FILES < <(git ls-files)

for ext in "${EXTS[@]}"; do
  for file in "${FILES[@]}"; do
    if [[ "$file" == *.$ext ]]; then
      echo "## $file" >> "$OUTPUT"

      # 言語別のコードブロック
      case "$ext" in
        kt)   echo '```kotlin' >> "$OUTPUT" ;;
        java) echo '```java' >> "$OUTPUT" ;;
        ts)   echo '```ts' >> "$OUTPUT" ;;
        js)   echo '```js' >> "$OUTPUT" ;;
        json) echo '```json' >> "$OUTPUT" ;;
        yml|yaml) echo '```yaml' >> "$OUTPUT" ;;
        toml) echo '```toml' >> "$OUTPUT" ;;
        md)   echo '```markdown' >> "$OUTPUT" ;;
        txt)  echo '```text' >> "$OUTPUT" ;;
        gradle|kts) echo '```kotlin' >> "$OUTPUT" ;;
        *)    echo '```' >> "$OUTPUT" ;;
      esac

      cat "$file" >> "$OUTPUT"
      echo "" >> "$OUTPUT"
      echo '```' >> "$OUTPUT"
      echo "" >> "$OUTPUT"
    fi
  done
done

echo "✅ Done! → $OUTPUT"
