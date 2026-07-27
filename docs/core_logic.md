# 夜湯 — M1 コアロジック設計メモ

作成日: 2026-07-25
対象: 数週間後の自分、新しく参加する人
対応ファイル: `core/` と `resources/` 以下

---

## このメモの目的

「スープを一杯出して、客に評価される」という夜湯のコアな仕組みが、
実際にどのファイルがどう連携して動いているかをまとめる。

設計書の転記ではなく、**今日のデバッグUIで実際に動いた実装**を元に書いている。

---

## 登場するクラスと役割

```
SoupAttrs          スープの「数値」を持つ箱。rich / light / umami の3つの整数。
RecipeResource     食材のデータ。種類（ベース/トッピング/薬味）と SoupAttrs を持つ。
Pot                鍋そのもの。SoupAttrs と残り杯数（volume）を管理する。
SoupServing        「一杯分」の記録。Pot.serve() が作って返す一時オブジェクト。
CustomerResource   客のデータ。「理想の SoupAttrs」と満足度の閾値を持つ。
Evaluator          判定担当。SoupServing と CustomerResource を比べて結果を返す。
```

クラス間の依存関係はこう：

```
RecipeResource ──(食材の属性値を提供)──► Pot
                                          │
                                          │ .serve()
                                          ▼
                               SoupServing（一杯分）
                                          │
                         ┌────────────────┘
                         │
                    Evaluator.evaluate()
                         │
                         ├── SoupServing.attrs と
                         └── CustomerResource.ideal を比べて Result を返す
```

SoupAttrs はデータの入れ物なので、Pot・SoupServing・CustomerResource・RecipeResource
いずれも「中に SoupAttrs を持つ」という形で使っている。

---

## 一杯が生まれて評価されるまでの流れ

### ステップ 1 ── 仕込み（Pot.setup）

ベース食材（RecipeResource）を鍋に投入し、鍋の初期状態を作る。

```
RecipeResource（豚骨ベース）
  attrs: SoupAttrs { rich=5, light=0, umami=3 }
  base_volume: 8

         ↓  Pot.setup(base, []) を呼ぶ

Pot の状態
  attrs: SoupAttrs { rich=5, light=0, umami=3 }   ← ベースのコピー
  volume: 8                                         ← 残り 8 杯
```

`attrs` は参照を共有しないよう `duplicate_attrs()` でコピーしている。
共有したままだと、後でカップに値を足したとき鍋の数値まで変わってしまうため。

### ステップ 2 ── サーブ（Pot.serve）

客が来たらサーブする。トッピングと薬味を指定して一杯を作る。

```
Pot.serve( topping=チャーシュー, yakumi=生姜 ) を呼ぶ

鍋の状態（Pot.attrs）のコピーを作り、
  チャーシューの attrs { rich=+2, umami=+1 } を足す
  生姜の attrs    { light=+1, umami=+1 }   を足す

→ SoupServing が生まれる
     attrs: SoupAttrs { rich=7, light=1, umami=5 }
     topping: チャーシュー
     yakumi:  生姜

鍋の volume: 8 → 7（1 杯減る）
```

鍋の `attrs` 自体は変わらない。カップに乗る補正は「カップのコピー」に対して加算する。

### ステップ 3 ── 評価（Evaluator.evaluate）

SoupServing と客の CustomerResource を渡すと Result が返ってくる。

```
評価の計算式:

  d = |カップのrich − 客の理想rich|
    + |カップのlight − 客の理想light|
    + |カップのumami − 客の理想umami|

  d がこの値以下なら → グレード
  ─────────────────────────────
  great_threshold 以下  →  GREAT（大満足）
  ok_threshold 以下     →  OK（普通）
  それより大きい        →  BAD（不満）
```

`d` はマンハッタン距離と呼ぶ。3軸の「ずれ」を合計した値で、
「どれくらい好みから外れているか」を1つの数字で表す。

グレードごとの支払いと評判変動:

| グレード | 支払い                     | 評判（rep_delta） |
|----------|---------------------------|-------------------|
| GREAT    | base_price + tip           | +1                |
| OK       | base_price                 | ±0                |
| BAD      | base_price × 0.5（半額）   | −1                |

評価と同時に「どの軸が一番外れていたか（worst_axis）」と
「多すぎたか少なすぎたか（over / under）」も計算される。
プレイヤーへのフィードバック表示に使う予定。

---

## 鍋がどう変化するか

鍋は「仕込んだらそのまま」ではなく、営業中に状態が変わっていく。

### 煮詰まり（on_turn_end）

客が一人帰るごとに `Pot.on_turn_end()` を呼ぶ（M2 で実装予定）。
呼ぶたびに `rich += 1` される。

```
仕込み直後:  rich=5, light=0, umami=3
1ターン後:   rich=6, light=0, umami=3
2ターン後:   rich=7, light=0, umami=3  ← あっさり系の客には BAD になり始める
```

→ 何もしないと鍋はどんどん濃くなる。

### 水差し（add_water）

`Pot.add_water()` を呼ぶと volume +2、rich −2、umami −1（下限 0）になる。

```
水差し前: volume=3, rich=8, umami=4
水差し後: volume=5, rich=6, umami=3
```

**トレードオフ**: 量は増えて濃さは下がるが、旨味も少し損なわれる。
カップ数を稼ぎたいが旨味を落としたくない、という判断がゲームの面白さになる部分。

---

## 3 キャラで実際に確認できたこと（デバッグ UI より）

今日の DebugPot で確認した実例：

**客: 老人**（理想: rich=1, light=5, umami=2 / great≤2, ok≤5）

| ベース | 薬味 | カップ属性        | d  | 判定 |
|--------|------|-------------------|----|------|
| 精進   | なし | r=0 l=5 u=2       | 1  | GREAT |
| 豚骨   | なし | r=5 l=0 u=3       | 10 | BAD   |
| 精進   | 生姜 | r=0 l=6 u=3       | 3  | OK    |

老人は light 重視なので、精進ベース（light=5）で仕込むと即 GREAT を取れる。
豚骨ベースでは距離 10 になり、どんな薬味を足しても OK 以上にならない。

これで「ベース選択がゲームの核心」という設計の意図が実際に動作として確認できた。

---

## 今後の接続ポイント（M2 以降で実装予定）

- `Pot.on_turn_end()` の呼び出しタイミング → 夜営業シーン（game.gd）
- `Evaluator.Result` から `GameState.money += result.payment` などへの反映
- `CustomerResource` の .tres ファイル化（現在は debug_pot.gd にコード直書き）
- `worst_axis` と `over/under` を使ったプレイヤーへのフィードバック表示

---

## ファイル早見表

| ファイル                          | 役割                     |
|-----------------------------------|--------------------------|
| `core/soup_attrs.gd`              | 3軸の数値データ           |
| `core/soup_serving.gd`            | 一杯分の記録オブジェクト  |
| `core/pot.gd`                     | 鍋の状態管理              |
| `core/evaluator.gd`               | 評価計算（副作用なし）    |
| `resources/recipe_resource.gd`    | 食材データ                |
| `resources/customer_resource.gd`  | 客データ                  |
