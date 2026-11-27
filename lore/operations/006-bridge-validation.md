# bridge の開発・互換性検証

bridge `b332e35` の文書に記載された検証方法。対象 revision と環境で利用可能な command を
確認し、実行した revision、binary、環境、command と成功・失敗を記録する。このページは
現在の revision でテストが成功したことを示さない。

bridge の source checkout で実行する workspace の確認:

```bash
cargo build --workspace
cargo test --workspace
cargo clippy --all-targets -- -D warnings
cargo fmt --check
```

実際の Lore binary を `PATH` に用意し、明示的に有効化して Rust E2E harness を実行する。
固定 port `41337` / `41339` の競合を避けるため直列実行する。

```bash
cargo build -p lore-auth-server -p lore-authctl
LORE_E2E=1 \
LORE_E2E_BRIDGE_BIN="$PWD/target/debug/lore-auth-server" \
LORE_E2E_AUTHCTL_BIN="$PWD/target/debug/lore-authctl" \
cargo test -p lore-auth-e2e -- --test-threads=1
```

新しい Lore binary との JWT claim contract は `lore-claimprobe` の対象 revision の `--help`
を確認して検証する。E2E harness の成功と Entra 実 tenant での browser login、
実際の repository 操作は別の検証である。
