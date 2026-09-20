<!-- Translated from readme.md at 4892c7a -->
<div align="center">
  
  # jyje/claude-docker
  
  <!-- center logo -->
  <img width="150" src="https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/light/claude-color.png" alt="Claude" title="Claude"/>
  
  Claude Code: コミュニティ製 Docker イメージ

  [![release](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml/badge.svg?branch=main)](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml)
  [![test](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml/badge.svg?branch=develop)](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml)
  [![cron](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml/badge.svg)](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml)
  [![GitHub Repo stars](https://img.shields.io/github/stars/jyje/claude-docker)](https://github.com/jyje/claude-docker)

  [English](readme.md) / [한국어](readme-ko.md) / [简体中文](readme-zh-CN.md) / [日本語](readme-ja.md)

</div>

> [!NOTE]
> この翻訳は AI の支援で作成したもので、ネイティブスピーカーによるレビューはまだ受けていません。修正の PR を歓迎します。内容に差異がある場合は、英語版の [readme.md](readme.md) が正です。

⭐ **このプロジェクトが役に立ったら、ぜひ GitHub で Star をお願いします！**

🤖 このリポジトリは、コミュニティが提供する [Claude Code](https://code.claude.com/docs) の Docker イメージです。Node.js 26 でビルドされており、`linux/amd64` と `linux/arm64` に対応しています。

> [!IMPORTANT]
> このリポジトリは Anthropic とは無関係です。Claude Code ユーザー向けに Docker イメージを提供する、コミュニティ運営のプロジェクトです。公式情報は [code.claude.com/docs](https://code.claude.com/docs) をご覧ください。

> [!NOTE]
> **Anthropic 公式 Dockerfile がベース**  
> この Docker イメージは [Anthropic 公式の Claude Code devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile) をベースにしており、Node.js 26、自動化された CI/CD パイプライン、マルチアーキテクチャ対応など、コミュニティ向けの改良が加えられています。

## 📚 ドキュメント

**はじめに**
- [クイックスタートと基本的な使い方](docs/getting-started-ja.md) - 環境設定、Docker の使い方、API 認証、クイックテスト

**上級ガイド**
- [上級ガイド](docs/advanced-guide.md)（英語）- Argo Workflows、Kubernetes Job/CronJob、CI/CD 連携

## 環境変数

Claude Code は多くの環境変数を読み取ります。以下の表は、このイメージを Docker、Kubernetes、CI で実行するときに特に重要なものをまとめたものです。

> [!NOTE]
> サポートされている変数の完全な一覧は、公式リファレンス **[Claude Code の環境変数](https://code.claude.com/docs/en/env-vars)** を参照してください。

### 認証とエンドポイント

| 変数 | 必須 | 説明 |
|------|------|------|
| `ANTHROPIC_API_KEY` | はい\* | `X-Api-Key` ヘッダーとして送信される API キー。[console.anthropic.com](https://console.anthropic.com/) で取得できます |
| `ANTHROPIC_AUTH_TOKEN` | いいえ | `Authorization` ヘッダーの値を独自に指定します。先頭に `Bearer ` が自動で付きます。ゲートウェイ経由で認証するときによく使います |
| `ANTHROPIC_BASE_URL` | いいえ | プロキシやゲートウェイ経由でリクエストを送ります。ローカルモデル（例: Docker Model Runner）にも使えます |
| `ANTHROPIC_CUSTOM_HEADERS` | いいえ | `Name: Value` 形式の追加リクエストヘッダー。複数指定するときは改行で区切ります |
| `ANTHROPIC_BETAS` | いいえ | カンマ区切りの `anthropic-beta` の値。Claude Code が正式に対応する前に、API のベータ機能を試すために使います |

\* サブスクリプションでのログイン、ゲートウェイのトークン、後述のクラウドプロバイダーなど、別の方法で認証する場合を除き必須です。

> [!CAUTION]
> `ANTHROPIC_API_KEY` と `ANTHROPIC_AUTH_TOKEN` は機密情報です。`-e VAR`（シェルの値を読み取る）または `--env-file` で渡してください。`Dockerfile` やコミットする compose ファイルに値を直接書き込まないでください。

### モデル選択

| 変数 | 説明 |
|------|------|
| `ANTHROPIC_MODEL` | セッションで使用するモデル |
| `ANTHROPIC_DEFAULT_MODEL` | 新しいセッションがデフォルトで開始するモデル（Claude Code v2.1.236 以降が必要） |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `opus` エイリアスが指すモデル ID |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `sonnet` エイリアスが指すモデル ID |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `haiku` エイリアスが指すモデル ID。バックグラウンド機能にも使われます |

### クラウドプロバイダー

| 変数 | 説明 |
|------|------|
| `CLAUDE_CODE_USE_BEDROCK` | [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock) を使用する |
| `CLAUDE_CODE_USE_VERTEX` | [Google Cloud の Agent Platform](https://code.claude.com/docs/en/google-vertex-ai) を使用する |
| `ANTHROPIC_VERTEX_PROJECT_ID` | GCP プロジェクト ID。`GCLOUD_PROJECT`、`GOOGLE_CLOUD_PROJECT`、または認証情報ファイル内のプロジェクトが優先されます |
| `ANTHROPIC_BEDROCK_BASE_URL` | Amazon Bedrock のエンドポイントを上書きします。カスタムエンドポイントや LLM ゲートウェイ向けです |
| `ANTHROPIC_VERTEX_BASE_URL` | Google Cloud のエンドポイントを上書きします。カスタムエンドポイントや LLM ゲートウェイ向けです |

### ネットワーク、プロキシ、ゲートウェイ互換性

| 変数 | 説明 |
|------|------|
| `HTTP_PROXY` | ネットワーク接続に使用する HTTP プロキシサーバー |
| `HTTPS_PROXY` | ネットワーク接続に使用する HTTPS プロキシサーバー |
| `NO_PROXY` | プロキシを経由せず直接接続するドメインと IP |
| `API_TIMEOUT_MS` | API リクエストのタイムアウト（ミリ秒）。デフォルトは `600000`（10 分）。低速なネットワークやプロキシ経由の場合に延ばします |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | `1` を設定すると、リクエストから `anthropic-beta` ヘッダーとベータ版のツールスキーマのフィールドを取り除きます。ゲートウェイがそれらを拒否するときに使います。`ANTHROPIC_BETAS` と対になる設定で、MCP ツール検索も無効になります |

> [!TIP]
> ネットワークサンドボックス（`--cap-add=NET_ADMIN --cap-add=NET_RAW`）でこのイメージを実行する場合、`init-firewall.sh` が外向きの通信を制限することに注意してください。ここで設定するプロキシのホストも、そのファイアウォールを通って到達できる必要があります。

### 実行制限とトークン予算

| 変数 | 説明 |
|------|------|
| `BASH_DEFAULT_TIMEOUT_MS` | 長時間実行される bash コマンドのデフォルトのタイムアウト（デフォルト `120000`、2 分） |
| `BASH_MAX_TIMEOUT_MS` | モデルが bash コマンドに設定できるタイムアウトの上限（デフォルト `600000`、10 分） |
| `BASH_MAX_OUTPUT_LENGTH` | 結果として読み戻される bash 出力の最大文字数（デフォルト `30000`、上限 `150000`） |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | ほとんどのリクエストにおける出力トークンの上限。デフォルト値と上限はモデルによって異なります |
| `MAX_THINKING_TOKENS` | 拡張思考に割り当てる固定のトークン予算 |
| `MCP_TIMEOUT` | MCP サーバーの起動タイムアウト（ミリ秒）。デフォルトは `30000`（30 秒） |
| `MAX_MCP_OUTPUT_TOKENS` | MCP ツールのレスポンスで許容される最大トークン数 |

CI での非対話実行（`claude -p`）では、デフォルトの値が長いビルドや応答の遅い MCP サーバーには厳しすぎることが多いため、これらの変数は調整する価値があります。

### コンテナ運用、アップデート、プライバシー

| 変数 | 説明 |
|------|------|
| `CLAUDE_CONFIG_DIR` | 設定ディレクトリを上書きします（デフォルト `~/.claude`）。設定、セッション履歴、プラグインがここに保存されるため、ボリュームマウントはこのパスに向けてください |
| `DISABLE_AUTOUPDATER` | `1` を設定すると、バックグラウンドの自動アップデートを無効にします。手動の `claude update` は引き続き使えます |
| `DISABLE_UPDATES` | `1` を設定すると、手動の `claude update` を含むすべてのアップデートをブロックします。`DISABLE_AUTOUPDATER` より厳格で、バージョンを固定したイメージでは通常こちらが適しています |
| `DISABLE_TELEMETRY` | テレメトリーを無効にします。下の警告を参照してください |
| `DO_NOT_TRACK` | `1` を設定するとテレメトリーを無効にします。効果は `DISABLE_TELEMETRY` と同じです。通常の真偽値として解釈されるため、`0` ならテレメトリーは有効のままです |
| `DISABLE_ERROR_REPORTING` | エラーレポートを無効にします。下の警告を参照してください |
| `CLAUDECODE` | Claude Code が起動するサブプロセスの中で `1` に設定されます。スクリプトが Claude Code の配下で動いているかどうかを判定するのに使えます |

> [!WARNING]
> `DISABLE_TELEMETRY` と `DISABLE_ERROR_REPORTING` は、**`0` や `false` を含め、空でない値であれば何でも**無効化として扱われます。`-e DISABLE_TELEMETRY=0` を渡してもテレメトリーは有効に戻らず、無効のままです。再び有効にするには、この変数を完全に未設定にしてください。`DO_NOT_TRACK` だけは例外で、通常の真偽値として解釈されるため、`DO_NOT_TRACK=0` ならテレメトリーは有効のままです。
>
> どちらのテレメトリー無効化も、フィーチャーフラグの取得も止めるため、Remote Control など、フィーチャーフラグに依存する機能が使えなくなります。

> [!TIP]
> このイメージはバージョンを固定して配布しているため、`DISABLE_UPDATES=1` を設定すると、実行時に Claude Code が自分自身を更新するのを防ぎ、タグ付きイメージの再現性を保てます。

> [!TIP]
> Docker、Kubernetes、API キー認証を含む詳しい使用例は、**[クイックスタートガイド](docs/getting-started-ja.md)** を参照してください。

## プリインストール済みツール

このイメージには次のツールがあらかじめ入っています。

```
- @anthropic-ai/claude-code (latest or specified version)
- node 26
- npm

- git + git-delta (diff viewer)
- zsh + powerline10k theme
- fzf (fuzzy finder)
- gh (GitHub CLI)
- jq, curl, wget
- nano, vim
- iptables, ipset, iproute2 (for network sandbox)
```

## MCP (Model Context Protocol) 接続

Claude Code は [MCP](https://modelcontextprotocol.io/) に対応しており、GitHub、データベース、各種 API などの外部ツールやデータソースに接続できます。

### コンテナ内で MCP サーバーを追加する

```bash
# Start container
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  -v claude-mcp-config:/home/node/.claude \
  ghcr.io/jyje/claude-docker

# Inside container: Add MCP servers
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://user:pass@host:5432/db"

# List configured servers
claude mcp list

# Check server status
/mcp
```

### .mcp.json による設定

プロジェクトのルートに `.mcp.json` を作成すると、チームで MCP 設定を共有できます。

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub", "--dsn", "${DATABASE_URL}"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

作成したら、コンテナにマウントします。

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -v $(pwd):/workspace \
  -v $(pwd)/.mcp.json:/home/node/.mcp.json:ro \
  ghcr.io/jyje/claude-docker
```

### 人気の MCP サーバー

| サーバー | コマンド |
|----------|----------|
| GitHub | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| PostgreSQL | `claude mcp add --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://..."` |
| Filesystem | `claude mcp add --transport stdio fs -- npx -y @modelcontextprotocol/server-filesystem /workspace` |

そのほかの MCP サーバーは、[GitHub の MCP Servers](https://github.com/modelcontextprotocol/servers) を参照してください。

## DevContainer サポート

このリポジトリには、VS Code Dev Containers 用の `.devcontainer` 設定が含まれています。使い方は次のとおりです。

1. [Dev Containers 拡張機能](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)をインストールする
2. このリポジトリをクローンする
3. ホスト側で `ANTHROPIC_API_KEY` 環境変数を設定する
4. VS Code で開き、"Reopen in Container" をクリックする

devcontainer は次のことを自動で行います。
- ネットワークサンドボックス（ファイアウォール）のセットアップ
- zsh と powerline10k の設定
- ワークスペースを `/workspace` にマウント
- コマンド履歴と Claude の設定の永続化

## CI パイプライン

このリポジトリは、自動化された CI パイプラインを通じて Claude Code の Docker イメージをビルド・管理しています。デプロイ戦略は主に 2 つです。

### `main` ブランチ（本番リリース）
- **自動実行**: `main` ブランチへのコミットで、リリース用イメージが自動的にビルド・公開されます。
- **タグ戦略**: 標準的なバージョンタグ（例: `v2.0.0`）を生成します。`latest` と `major`/`minor` のタグは、そのバージョンが絶対的に最新のときだけ付与されるため、古いパッチリリースが現在のデプロイを上書きすることはありません。
- **リリースノート**: 詳細な変更履歴付きの GitHub Release を自動生成します。

### `develop` ブランチ（開発ビルド）
- **自動実行**: `develop` ブランチへのコミットで、テスト用イメージが自動的にビルド・公開されます。
- **タグ戦略**: `-dev:[20 文字の SHA]` と `-dev:latest` のタグを使い、ハッシュの衝突を完全に防ぎます。
- **ストレージ管理**: 自動ガベージコレクション（GC）により、GHCR には直近 20 個の開発用イメージだけを残し、ストレージを最適化します。

### 共通機能
- **マルチアーキテクチャ**: ビルドは `linux/amd64` と `linux/arm64` の両方に対応しています。
- **自動アップデート**: cron ジョブが 6 時間ごとに Claude Code の新バージョンを確認し、Pull Request を自動で作成します。リリースの直後にも実行されるため、溜まったバージョンは 1 つずつ PR で順番に処理されます。各 PR は両プラットフォームでネイティブにビルドされて `version-check` ステータスを報告し、マージは常に手動です。
- **スキップ**: コミットメッセージに `--no-ci` フラグを含めると、そのコミットでは CI パイプラインをスキップできます。

## コントリビューション

このプロジェクトへの貢献方法は、[コントリビューションガイドライン](contributing.md)を参照してください。

## ライセンス

このプロジェクトは MIT ライセンスで公開されています。詳細は [license.md](license.md) を参照してください。

Claude Code は [Anthropic](https://www.anthropic.com/) の製品です。このプロジェクトは Anthropic とは無関係です。
