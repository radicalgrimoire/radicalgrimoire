# LOREサーバーの構築について

https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.sh

これを確認すると、

でインストールできるらしい。ドキュメント見ると

```
curl -fsSL https://raw.githubusercontent.com/EpicGames/lore/main/scripts/install.sh | bash -s -- --server
```

デフォルトはこんな感じなってるけど…

```
  --demo               LORE_DEMO          also install and launch a local loreserver (1/true/yes/on/enabled)
  --server             LORE_SERVER        only install loreserver (skip the lore CLI and auto-launch)
  --version <v>        LORE_VERSION       install a specific release tag (default: latest)
  --install-dir <dir>  LORE_INSTALL_DIR   where binaries go (default: ~/.local/bin)
  --repo <owner/repo>  LORE_REPO          source repository (default: EpicGames/lore)
  --token <t>          GITHUB_TOKEN       token for private repos / higher rate limit (defaults to `gh auth token`)
  -h, --help                              show this help
```

lore-server環境で、lore の cli も併せてインストールした方が良いと思うので、
