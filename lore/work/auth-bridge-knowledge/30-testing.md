# 開発・互換性テスト

**統合先案:** `lore/work/bridge-validation.md`（新規候補）  
**根拠:** [bridge README](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/README.md#開発時の確認)、[E2E harness](https://github.com/radicalgrimoire/lore-auth-bridge/blob/b332e35b42204c23271f02bbb6f4aa6ae9e25f71/crates/lore-auth-e2e/README.md)

## 統合文案

bridge の開発確認には `cargo build --workspace`、`cargo test --workspace`、`cargo clippy --all-targets -- -D warnings`、`cargo fmt --check` が案内されている。Rust E2E harness は明示的に `LORE_E2E=1` と bridge / authctl binary path を指定し、実際の Lore binary を `PATH` に用意して実行する。固定 port `41337` / `41339` の競合を避けるため `--test-threads=1` で直列実行する。

実行結果には対象 revision、binary と環境、command、成功・失敗を記録する。harness の成功と Entra 実 tenant での browser login は別の検証である。
