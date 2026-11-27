# C++、PHP と比べる Rust の特徴

Rust は、C++ のように native binary を作れる一方で、メモリ安全性と並行性の一部をコンパイル時に確認する言語である。PHP のように Web アプリケーションを素早く作るための言語ではないが、常駐 service、CLI、network protocol を扱う基盤ソフトウェアでは強みがある。

重要なのは、Rust が常に最適ということではない。守りたいものと払える開発コストによって選択は変わる。

## まず比較

### C++

- native binary として配布しやすい。
- RAII と smart pointer を使えば、安全なリソース管理を書ける。ただし、どの安全な書き方を採るかは開発者とチームが選ぶ。
- thread、mutex、atomic を使った同期は強力だが、データ競合を避ける設計は開発者が担う。
- 高度な抽象化を使える一方、言語機能と設計の選択肢が広い。
- 高性能 service、ゲーム、既存の C++ 資産と結び付く開発に向く。

### PHP

- 主に VM 上で動作し、PHP 本体、拡張、依存パッケージ、Web 実行環境を管理する。
- GC とランタイムがメモリを管理する。
- Web request 単位の処理を組み立てやすい。並行処理の扱いは利用する実行環境による。
- 開発の反復速度を優先しやすい。
- Web UI、業務アプリ、CMS、迅速な CRUD 開発に向く。

### Rust

- native binary として配布しやすい。
- 所有権・借用をコンパイル時に検証する。
- safe Rust では、データ競合をコンパイル時に防ぐ。
- generics と trait による抽象化を、最適化後も低い実行時コストで使えるよう目指している。
- 基盤 service、CLI、network service に向く。

## 同じ処理を3言語で比べる

認証・認可 service では、repository 名のような外部入力を正規化してから扱う場面がある。ここでは次の同じ条件を実装する。

- 前後の空白を除く
- 空文字列と 64 文字を超える名前を拒否する
- ASCII の英数字と `-` 以外を拒否する
- 小文字へ正規化して返す

### C++

```cpp
#include <algorithm>
#include <stdexcept>
#include <string>
#include <string_view>

std::string normalize_repository_name(std::string_view raw) {
    // 空白・タブ・改行以外で最初と最後にある文字の位置を探す。
    // 2つの位置の間だけを切り出し、trim 相当の文字列を作る。
    const auto first = raw.find_first_not_of(" \t\r\n");
    const auto last = raw.find_last_not_of(" \t\r\n");
    const std::string name =
        first == std::string_view::npos ? "" : std::string(raw.substr(first, last - first + 1));

    // std::string は所有する文字列なので、ここで以降の処理に使う値を確保する。
    if (name.empty() || name.size() > 64) {
        throw std::invalid_argument("repository name must be 1 to 64 characters");
    }

    // std::all_of は、全ての文字が条件を満たすときだけ true を返す。
    if (!std::all_of(name.begin(), name.end(), [](unsigned char ch) {
            return (ch >= 'A' && ch <= 'Z')
                || (ch >= 'a' && ch <= 'z')
                || (ch >= '0' && ch <= '9')
                || ch == '-';
        })) {
        throw std::invalid_argument("repository name contains an invalid character");
    }

    // 元の name は残したままコピーを小文字化して返す。
    std::string normalized = name;
    std::transform(normalized.begin(), normalized.end(), normalized.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return normalized;
}
```

C++ でも `std::string_view` により、入力文字列をコピーせず参照できる。標準アルゴリズムと lambda によって検証も書けるが、文字種関数へ渡す値の型、例外をどこで捕捉するか、文字列の所有権をどこに置くかは、設計と規約で決める部分が大きい。

### PHP

```php
<?php

function normalizeRepositoryName(string $raw): string
{
    $name = trim($raw);

    if (
        $name === ''
        || strlen($name) > 64
        || preg_match('/\A[a-zA-Z0-9-]+\z/D', $name) !== 1
    ) {
        throw new InvalidArgumentException('invalid repository name');
    }

    return strtolower($name);
}
```

PHP は正規表現と例外を使って、同じ request validation を短く書ける。Web framework の request、validation、DB、template とつなげる場合は、この書き方の速さが大きな利点になる。

### Rust

```rust
fn normalize_repository_name(raw: &str) -> Result<String, String> {
    // raw は引数として受け取った文字列への参照。
    // trim 後の name も、新しい文字列を作らず raw の一部を参照している。
    let name = raw.trim();

    // 条件に合わない場合は Err を返し、成功値を作らない。
    if name.is_empty() || name.len() > 64 {
        return Err("repository name must be 1 to 64 characters".to_owned());
    }

    // bytes を順に調べ、全ての文字が ASCII 英数字または - かを確認する。
    if !name
        .bytes()
        .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-')
    {
        return Err("repository name contains an invalid character".to_owned());
    }

    // 小文字化した新しい String を Ok に包んで返す。
    Ok(name.to_ascii_lowercase())
}
```

Rust では、入力は呼び出し側が所有する文字列への参照 `&str`、成功または失敗は `Result<String, String>` として関数の型に現れる。`bytes().all(...)` は文字列を走査する iterator であり、条件を満たすかをそのまま式として書ける。

`&str`、`Result`、closure、iterator が一つの短い関数に同居するので、C++、PHP の例を読んだ後だと最初は「めっちゃ独特」と感じる。ただし、どの値を借りていて、どこで失敗し得るか、何を返すかが型と式にまとまっているのは面白い。

### 何が違って見えるのか

3つとも同じ結果を返せる。違いは「失敗、入力の所有権、文字列操作の方針をどこで表現するか」である。

- **C++**: `string_view`、標準アルゴリズム、例外など、目的に応じた強力な道具を選べる。チームが選択を統一することが重要になる。
- **PHP**: 入力検証と例外処理を簡潔に書き、Web application の flow へ素早く組み込める。
- **Rust**: `Result` と借用を関数の型へ表す。iterator と closure を使う書き方は独特だが、処理の境界を読み取りやすい。

## Rust の特徴

### 所有権と借用で、メモリの扱いをコンパイル時に確認する

Rust には GC がなく、C++ のように native code として動作する。一方で、値の所有者を一つに定める所有権と、参照の有効期間を確認する借用の仕組みを持つ。

safe Rust の範囲では、解放済みメモリへのアクセス、二重解放、無効な参照といった問題をコンパイル時に防げる。C++ でもレビュー、テスト、RAII、smart pointer、sanitizer によって減らせるが、Rust はそれらの一部を言語の標準的な書き方に組み込んでいる。

```rust
struct Token {
    value: String,
}

fn redact(token: &Token) -> String {
    // &Token は値を借用するだけなので、呼び出し側の token は消費しない。
    format!("{}...", token.value.chars().take(4).collect::<String>())
}

// to_owned で、&str から Token が所有する String を作る。
let token = Token {
    value: "abcd1234".to_owned(),
};
// &token を渡すため、呼び出し後も token を使える。
let preview = redact(&token);
println!("{}", token.value);
```

`redact` は `&Token` を借用するため、関数が終わっても呼び出し側は `token` を使える。一方、`Token` を値として関数へ渡すと所有権が移るため、呼び出し側での再利用はコンパイルエラーになる。token のコピーや所有権移動を、コード上で意識させる仕組みである。

### 並行処理の不正な共有を早く見つける

Rust では、複数の実行単位から安全に共有できる型かどうかも型システムで表現される。safe Rust では、同じ可変データを無秩序に共有するコードは通らない。

C++ では、mutex、atomic、thread の API を正しく使えば同じことは実現できる。ただし、同期漏れや lifetime の誤りは実行時まで見つからないことがある。Rust でも deadlock や業務上の競合までは防げないが、「データ競合」という低レイヤーの誤りを減らせる。

```rust
use std::sync::{Arc, Mutex};
use std::thread;

// Arc は複数 thread で所有できる参照カウント、Mutex は可変値への排他アクセスを表す。
let issued = Arc::new(Mutex::new(0_u32));
// worker 用に同じ Arc の参照カウントを増やす。
let worker_state = Arc::clone(&issued);

let worker = thread::spawn(move || {
    // lock を取得している間だけ、カウンターを可変で参照する。
    *worker_state.lock().unwrap() += 1;
});

// worker の完了を待ってから、同じ値を確認する。
worker.join().unwrap();
assert_eq!(*issued.lock().unwrap(), 1);
```

共有する可変値は `Arc<Mutex<_>>` で明示する。`Mutex` を使わずに可変値を複数 thread で共有しようとすると、safe Rust ではコンパイルが通らない。なお、この例でも lock の順序を誤れば deadlock は起こり得るため、型検査だけで設計上の競合がなくなるわけではない。

### error を値として扱うことを促す

Rust は `Result<T, E>` と `Option<T>` によって、失敗や値の不在を型として表す。呼び出し側は成功だけを前提にできず、失敗を返すか、変換するか、処理するかを選ぶ必要がある。

C++ では例外または `expected` 系の型、PHP では例外や `null` などで同様の表現ができる。Rust が特徴的なのは、標準ライブラリと慣習が `Result` を中心に揃っており、失敗を見落としにくい書き方が自然になる点である。

```rust
fn parse_port(value: &str) -> Result<u16, String> {
    // 文字列を u16 へ変換する。変換失敗は説明付きの String に変える。
    let port: u16 = value
        .parse()
        .map_err(|_| format!("invalid port: {value}"))?;

    // 0 は変換できても、この設定では不正な値として扱う。
    if port == 0 {
        return Err("port must not be zero".to_owned());
    }

    // 検証済みの port を成功値として返す。
    Ok(port)
}
```

呼び出し側は `Result` を受け取り、成功時と失敗時をどちらも処理する必要がある。`?` は失敗を上位の呼び出し側へ返す記法であり、エラーを握りつぶすためのものではない。

### zero-cost abstraction を目指す

Rust の trait、generics、iterator は高水準の記述を可能にしつつ、多くの場合はコンパイル後に余分な実行時コストを残さないことを目指している。この考え方は C++ の template や RAII と近い。

ただし「zero-cost」は無料という意味ではない。コンパイル時間、型エラーを理解する学習コスト、generic code による binary size は考慮が必要である。また、実際の性能はアルゴリズム、I/O、DB、network latency に大きく左右される。

## C++、PHP と比べたときの選びどころ

### C++ と比べる

C++ は Rust より長い歴史を持ち、ゲーム、金融、高性能 server、既存ライブラリの領域で大きな資産がある。RAII、smart pointer、`std::string`、標準コンテナを使えば、安全性と表現力を高められる。既存 C++ コードや ABI との互換性が主目的なら、C++ を選ぶ合理性がある。

一方で C++ は後方互換性を保ちながら発展してきたため、古い記法から新しい記法まで選択肢が広い。安全な所有権モデル、例外、template、build system、ABI の方針をチームで決めて守る必要がある。Rust は言語設計によって、所有権と thread safety の既定をより強く定めている。

```cpp
#include <memory>

class Session {};
void run_session(std::unique_ptr<Session> session);

auto session = std::make_unique<Session>();
run_session(std::move(session));

// session は nullptr になり、ここでは Session を使えない。
```

`std::unique_ptr` は所有者が一つであることを表し、RAII により scope を抜けると自動で解放される。`std::move` による所有権移動も明示できる。Rust はこのような所有権の扱いを smart pointer の利用規約ではなく、通常の値と参照にも適用する。

### PHP と比べる

PHP は Web の request/response と業務アプリケーションを早く作ることに強い。フレームワーク、ORM、template、認証周辺の資産が豊富で、管理画面や CRUD を短い反復で作るなら有力である。開発者の採用や引き継ぎも、組織によっては PHP の方がしやすい。

一方で、常駐 service、CLI、network protocol、低い常駐リソース、単体 binary での配置を重視するなら、Rust の方が自然である。これは PHP が認証や API を実装できないという意味ではない。変化の速い管理画面を PHP で作り、Rust の core service が提供する API を呼ぶ構成も十分にあり得る。

```php
<?php

function findUser(array $users, string $id): ?array
{
    foreach ($users as $user) {
        if ($user['id'] === $id) {
            return $user;
        }
    }

    return null;
}

$user = findUser($users, $requestId);
if ($user === null) {
    throw new RuntimeException('user not found');
}
```

PHP では nullable 型と例外を用いて、見つからない値を呼び出し側で処理できる。request handler や管理画面のように、入力を受けて DB を操作し画面や JSON を返す flow を、短いコードで組み立てやすい。

## まとめ

Rust を選ぶ理由は性能だけではない。

- native binary を作りながら、メモリ安全性の一部をコンパイル時に確認できる
- 不正な共有によるデータ競合を safe Rust で減らせる
- `Result` と `Option` により、失敗や値の不在を API の型に含めやすい
- C++ に近い抽象化と性能を目指しつつ、安全な既定を強く持つ

ただし、学習コストとコンパイル時間は小さくない。既存資産、チームの経験、UI の変更頻度、配布と運用の形を見て、C++、PHP を含めて使い分けるべきである。
