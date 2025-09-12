# shell-tools

## project-bundler.sh について（日本語）

リポジトリ内のファイルを拡張子ごとにコードブロック付きのMarkdownへまとめるスクリプトです。サイズ上限（既定: 3MB）を超えないように自動で分割し、`project-bundle-1.md`, `project-bundle-2.md` のように複数ファイルに出力します。

主な特徴:
- `git ls-files` の結果に含まれるファイルのみを対象（未追跡ファイルは除外）
- 多くの言語・設定ファイルをサポート（拡張子に応じてコードフェンス言語を自動付与）
- 出力ファイルごとにサイズを管理し、上限超過前に自動ローテーション

### 使い方（ワンライナー）

```bash
curl -sSL https://raw.githubusercontent.com/momosetkn/shell-tools/refs/heads/main/project-bundler.sh | bash
```

実行は対象プロジェクトのルート（`git` 管理されているディレクトリ）で行ってください。完了するとカレントディレクトリに `project-bundle-*.md` が生成されます。

### ローカルにダウンロードして実行

```bash
curl -sSLO https://raw.githubusercontent.com/momosetkn/shell-tools/refs/heads/main/project-bundler.sh
chmod +x project-bundler.sh
./project-bundler.sh
```

### 出力仕様
- ファイル名: `project-bundle-<連番>.md`
- 各エントリ: `## <パス>` の見出しと、拡張子に応じたコードフェンスで中身を囲んで出力
- 対象拡張子: ソースコード、設定、ドキュメント、データ系など多数（`project-bundler.sh` 内の `EXTS` を参照）

### カスタマイズ
スクリプト冒頭の変数を編集することで挙動を変更できます。
- `BASE`: 出力ファイルのベース名（既定: `project-bundle`）
- `MAX_SIZE`: 1ファイルあたりの最大サイズ（既定: 3MB）
- `EXTS`: 取りまとめ対象の拡張子リスト

### 注意事項
- `git ls-files` ベースのため、未追跡ファイルや `.gitignore` で無視されたファイルは含まれません。
- 大きなプロジェクトでは複数のMarkdownファイルが作成されます。
