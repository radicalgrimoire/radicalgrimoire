# lore-auth-bridge を Rust で作った理由を振り返る

`lore-auth-bridge` は、OIDC のログインだけを担当する小さな Web アプリではない。Lore の UCS Auth / ReBAC protocol を実装し、ログイン用トークン、repository ごとの token exchange、JWKS、repository 権限、`loreserver` との同期、運用用 CLI まで持つ認証・認可サービスである。

そのため、Lore 本体をフォークした後に bridge まで Rust で作ったのは、単に「Rust が好きだから」というより、Lore との接続面を同じ技術スタックで保つためだったのだと思う。

## Rust に寄せる利点

### Lore 本体との距離が近い

Lore 本体は Rust の Cargo workspace である。bridge も Rust にすると、gRPC と protobuf、TLS、JWT の境界を同じ言語とツールチェーンで追える。

認証の不具合は、IdP、bridge、Lore CLI、`loreserver` のどこでも起こり得る。bridge だけ別の言語にすると、問題の切り分け時に API の仕様だけでなく、別の非同期実行系、依存管理、デバッグ方法まで切り替える必要がある。小規模に運用するほど、この切り替えのコストは意外に大きい。

### protocol 実装と単体配布の相性がよい

bridge が使う部品は、非同期 HTTP / gRPC、OIDC、JWT、SQLite、CLI、設定ファイルである。Rust にはこれらを組み合わせるためのライブラリがあり、release build を単体バイナリとして Ubuntu のサーバーへ配置できる。

Node.js や Python でも実装は可能であり、Web 開発の速度では有利な場合がある。ただし本番サーバーにランタイムと依存関係を維持する前提になる。bridge のように常駐し、認証トークンと秘密鍵を扱う小さな基盤サービスでは、実行環境を少なくできる価値がある。

### 認証・認可の変更を型とテストで閉じやすい

認証・認可では、claim の解釈、token の audience、有効期限、repository ごとの権限のように、似た名前でも混同すると危険な値を多く扱う。型で表現できる境界を増やし、Rust のテストで token flow や protocol contract を固定しておく方針は相性がよい。

もちろん Rust を使っただけで安全になるわけではない。IdP の信頼条件、redirect URI、token をログに出さないこと、秘密鍵の保管、reverse proxy の設定などは、実装言語とは別に設計と運用で確認する必要がある。

## いま見直すなら

core bridge を Rust のままにする判断は、今でも妥当だと思う。Lore との protocol 互換性と、Ubuntu 上で常駐する単体サービスとしての運用を重視するためである。

一方で、管理画面を大きく育てる、IdP ごとの導入画面を多く作る、利用者向けの UI を頻繁に改善するといった部分まで Rust に寄せる必要はない。そうした UI は TypeScript など別の得意な技術で実装し、bridge の HTTP / gRPC API を明確な境界として使えばよい。

大事なのは「全部を Rust にする」ことではなく、Lore と認証・認可の protocol を守る core を Rust に置き、変化が速い UI や周辺ツールは必要に応じて分けられるようにすることである。

## まとめ

Rust を選んだ理由は、性能だけではない。

- Lore 本体と同じ言語で protocol の互換性を追いやすい
- gRPC、JWT、OIDC、CLI、SQLite を一つの workspace で扱える
- Ubuntu に単体バイナリとして配置しやすい
- 認証・認可の重要な値と flow を、型とテストで固定しやすい

bridge の core に Rust を選ぶのは、実装速度だけでなく、将来の調査・保守・運用まで含めた選択だったと考えられる。
