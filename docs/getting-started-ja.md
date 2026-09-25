<!-- Translated from docs/getting-started.md at 4892c7a -->
# Claude Docker はじめに

Docker で Claude Code を動かすためのクイックガイドです。

> [!NOTE]
> この翻訳は AI の支援で作成したもので、ネイティブスピーカーによるレビューはまだ受けていません。修正の PR を歓迎します。内容に差異がある場合は、英語版の [getting-started.md](getting-started.md) が正です。

## クイックスタート

```bash
docker pull ghcr.io/jyje/claude-docker

docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

## 環境変数

使い始めるのに必要なのは `ANTHROPIC_API_KEY` だけです。[console.anthropic.com](https://console.anthropic.com/) で取得できます。

そのほかの変数（モデル選択、プロキシ、クラウドプロバイダー、実行制限、テレメトリーの無効化など）は、**[README の環境変数セクション](../readme-ja.md#環境変数)** を参照してください。

`.env` ファイルを使う場合：

```bash
# .env
ANTHROPIC_API_KEY=sk-ant-api03-xxxx...

docker run --rm -it --env-file .env -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

## クイックテスト

ヘッドレスモードが動作することを確認します。

```bash
curl -O https://raw.githubusercontent.com/jyje/claude-docker/main/test.sh
chmod +x test.sh
echo "sk-ant-api03-your-key" > api-key

./test.sh
./test.sh "Analyze this code" "./output.txt"
```

自動化用のテンプレートは [test.sh](../test.sh) を参照してください。

## 使い方のバリエーション

**カスタム Base URL**（ローカルモデル/プロキシ）：
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -e ANTHROPIC_BASE_URL=http://localhost:12434 -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

**バージョンを指定する：**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker:v2.1.23
```

**Claude を直接実行する：**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker claude
```

利用可能なバージョン: [GitHub Container Registry](https://github.com/jyje/claude-docker/pkgs/container/claude-docker)

## API キー認証（ログイン不要）

ブラウザでの OAuth ログインなしに API キーを使います。ヘッドレス/CI 環境では必須です。

**セットアップ**（一度だけ、コンテナ内で実行）：
```bash
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

Claude はこの helper 経由でキーを読み取り、OAuth を回避します。カスタムイメージの Dockerfile の例は、[上級ガイド](advanced-guide-ja.md)を参照してください。

## ネットワークサンドボックス

[公式のファイアウォールスクリプト](https://github.com/anthropics/claude-code/tree/main/.devcontainer)を使った、オプションのネットワーク分離です。

```bash
docker run --rm -it --cap-add=NET_ADMIN --cap-add=NET_RAW -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker

# Inside container:
sudo /usr/local/bin/init-firewall.sh
```

## 上級：Kubernetes、CI/CD、Argo Workflows

Kubernetes のサイドカー、Argo Workflows、Job、CronJob、CI/CD 連携については、[上級ガイド](advanced-guide-ja.md)を参照してください。

## 次のステップ

- [MCP 接続](../readme-ja.md#mcp-model-context-protocol-接続) – 外部ツール
- [プリインストール済みツール](../readme-ja.md#プリインストール済みツール) – イメージの中身
- [DevContainer サポート](../readme-ja.md#devcontainer-サポート) – VS Code
- [CI パイプライン](../readme-ja.md#ci-パイプライン) – 自動ビルド
