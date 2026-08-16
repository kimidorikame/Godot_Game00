# キャラクター／会話 ファイル形式仕様

> 状態: 仕様確定・実装未着手。2026-08-16、客6人への再編方針とファイル形式を確定した。
> この文書に記録した再編（roujin→rouba、keiji→keikan、chinpira/shoufu/kisha新規追加）は
> まだコードには一切反映されていない。

## 位置づけ

このドキュメントが定めるのは「プログラムが読み込む入れ物の形式」だけ。

- **このドキュメント（形式担当）**: id体系、ファイル命名規則、データ構造、実装時の影響範囲
- **別セッション（ストーリー担当）**: 各キャラの性格・口調・背景の詳細、具体的なセリフ・会話内容、
  会話の演出方針（話者構文を使うか／立ち絵を出すか）、同席掛け合いのドラマ

開発状況を見失わないための切り分け: このドキュメント＝入れ物の形式、ストーリー側＝入れ物に入る中身。
ストーリー側で中身が固まったら、この形式仕様に沿って実装（ファイル作成・改変）を行う。

## 客6人の設定（役割の骨格のみ）

詳細な性格・口調・具体的なセリフは別セッションで決定する。ここでは役割の骨格のみを定める。

| id | 呼称 | 役割 | 機能 |
|---|---|---|---|
| `rouba` | 路上生活者の老婆 | この街に60年以上いる生き証人 | チュートリアル・街の過去 |
| `haitatsuin` | 配達人 | 白黒問わず荷物を運び街の動線を知る | 翌日の予告・現在の街 |
| `keikan` | 新米警官 | 黒社会から警察へ送り込まれた内通者 | メインドラマA |
| `chinpira` | チンピラ | 警察の潜入捜査官 | メインドラマB |
| `shoufu` | 娼婦 | 誰にも属さない夜の観察者 | 人間関係・噂の真偽 |
| `kisha` | フリーの配信記者 | 「真実を撮る」こと自体に危うさを抱える | 世界観・終盤の引き |

補足: `keikan` と `chinpira` は「表の肩書きと実際の所属がねじれている」対の関係（警官が黒社会側の
内通者、チンピラが警察側の潜入捜査官）。メインドラマA/Bとして対になる。

## 既存3人からの再編

現状実装済みの `CustomerResource` は3人（`roujin`/`haitatsuin`/`keiji`）。これを6人へ再編する。

- `roujin` → `rouba` に切り替え（`roujin` は廃止）。老人から老婆へ
- `haitatsuin` → 流用（変更なし）
- `keiji` → `keikan` に切り替え（`keiji` は廃止）。前回 `keiji` の `display_name` は
  「刑事（元料理人）」の仮データだったが、新設定で新米警官 `keikan` に置き換わる
- `chinpira` / `shoufu` / `kisha` を新規追加

※この再編に伴う実際のファイル改変（`.tres` リネーム・id書き換え・`game.gd` カタログ更新・
`day*.tres` の `visitors`/`companion_scenes` 更新・既存 `.dtl`/`.dch` の扱い）は未実施。
別途実装する（下記「実装時の影響範囲」参照）。

## id体系とファイル命名規則（プログラムが読む形式）

- **客id（StringName）**: `rouba` / `haitatsuin` / `keikan` / `chinpira` / `shoufu` / `kisha`
- **CustomerResource**: `data/customers/{id}.tres`（例: `data/customers/rouba.tres`）。
  `id` フィールドも同じ `{id}`
- **会話タイムライン `.dtl` の命名規則**:
  - 同席なし（メインのみ）: `d{日}_{メインid}`（例: `d1_rouba`）
  - 同席あり（掛け合い）: `d{日}_{メインid}_{同席id}`
    （例: `d1_rouba_haitatsuin` = 1日目、老婆メインに配達人が同席する掛け合い）
  - 同じ顔ぶれで複数バリエーション: 末尾に連番 `_1` `_2`
    （例: `d1_rouba_haitatsuin_1`, `d1_rouba_haitatsuin_2`）
- **`.dtl` の置き場所**: `res://dialogue/`（現状踏襲、フラット）
- `CompanionPattern` の `timeline_ids` には、上記命名の `.dtl` id を `Array[StringName]` で指定する。
  抽選でパターンが選ばれた後、`timeline_ids` からランダムで1本再生される（実装済みの仕組み）。
- `.dtl` の記法（Dialogicの正式な話者構文「`id: セリフ`」＋キャラクター `.dch` ＋立ち絵を使うか、
  地の文で書くか）は**未定**。これは会話の見せ方・演出に関わる判断のため、別セッション
  （ストーリー・演出側）で決定する。決まったらこのドキュメントに追記し、必要なら `.dch` 作成等の
  形式準備を行う。
- **Dialogicキャラクター `.dch`**: 上記の記法判断が「話者構文を使う」になった場合、6人分の `.dch`
  （`dialogue/{id}.dch` 等）が必要になる。現状は旧 `roujin` 用の `.dch` が1つあるのみ（実質未使用）。
  未定事項。

## 実装時の影響範囲（今回は未実施。別途実装する際のチェックリスト）

id再編（`roujin`→`rouba`、`keiji`→`keikan`）と6人化を実装する際に触るもの:

- `data/customers/` の `.tres`: `roujin.tres`→`rouba.tres`（リネーム＋id書き換え）、
  `keiji.tres`→`keikan.tres`、`chinpira`/`shoufu`/`kisha`.tres 新規作成
- `game.gd` の `_customer_catalog`（`roujin`/`haitatsuin`/`keiji` の `preload` を新idに更新、
  新規3人を追加）
- `data/schedule/day1〜7.tres` の `visitors`（`["roujin","haitatsuin","keiji"]` を新idに）
- `data/schedule/day1.tres` の `companion_scenes`（`main=&"roujin"`、`companions=[&"keiji"]` 等を
  新idに）
- 既存の会話 `dialogue/d1_roujin.dtl` / `d1_roujin.dch`（命名規則に合わせ `d1_rouba` へ扱いを
  見直す。会話の中身作成と合わせて別途）
- `game.gd` の `CONVERSATION_TIMELINE_ID = "d1_roujin"`（フォールバック用デフォルト。新idに合わせ
  見直し）

## 役割分担のまとめ

- **このドキュメント（このセッション/プログラム形式担当）**: id体系、ファイル命名規則、データ構造、
  実装影響範囲
- **別セッション（ストーリー担当）**: 各キャラの性格・口調・背景の詳細、具体的なセリフ・会話内容、
  会話の演出方針（話者構文/立ち絵の可否）、同席掛け合いのドラマ

別セッションで中身が固まったら、この形式仕様に沿って実装（ファイル作成・改変）を行う。
