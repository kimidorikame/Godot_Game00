# 夜湯 — 開発メモ

> 実装時は `D:\Projects\GODOT\Game00\夜湯_技術設計書_v0.2.md` のコードと規約に従う。

## ゲーム概要
会話ADV × 軽経営シム。深夜の屋台でスープを売りながら客との対話を楽しむゲーム。

## 技術スタック
- Godot 4.7 / GL Compatibility
- 解像度: 1920 × 1080（canvas_items stretch）
- 言語: GDScript（静的型付け徹底・class_name 全クラスに付与）
- 会話エンジン: Dialogic 2 アドオン（自作しない）

## フォルダ構成

```
res://
├── autoload/
│   ├── game_state.gd        # 進行状態（日数・金・評判・在庫・フラグ）
│   ├── event_bus.gd         # グローバルシグナル置き場
│   └── save_manager.gd      # セーブ／ロード（M4で実装）
├── core/                    # 純粋ロジック Node非依存（M1で追加）
│   ├── pot.gd
│   ├── soup_serving.gd
│   └── evaluator.gd
├── resources/               # Resourceクラス定義
│   ├── customer_resource.gd
│   ├── recipe_resource.gd
│   └── day_schedule_resource.gd
├── data/                    # .tres データ本体
│   ├── customers/
│   ├── recipes/
│   └── schedule/
├── dialogue/                # Dialogic 2 タイムライン
├── scenes/
│   ├── title/               # タイトル画面（メインシーン）
│   │   ├── Title.tscn
│   │   ├── title.gd
│   │   └── exit.gd
│   ├── night/               # 夜営業（本編仮）
│   │   ├── Game.tscn
│   │   └── game.gd
│   ├── home/                # 結果・セーブ・翌日へ
│   │   ├── Result.tscn
│   │   └── result.gd
│   ├── market/              # 市場（昼）
│   ├── prep/                # 仕込み（昼）
│   └── ui/                  # 共通UI部品
└── assets/
    ├── fonts/
    ├── images/
    │   ├── bg/
    │   └── chara/
    ├── bgm/
    └── sfx/
```

## 画面遷移

```
scenes/title/Title.tscn
  ──[NEWGAME]──► scenes/night/Game.tscn
                   ──[営業終了]──► scenes/home/Result.tscn
                                     ──[翌日へ]──► scenes/night/Game.tscn
                                     ──[タイトルへ]──► scenes/title/Title.tscn
```

## 命名規則
- ファイル名: snake_case（`game_state.gd`）
- シーン名・クラス名: PascalCase（`Title.tscn` / `class_name TitleScreen`）
- ノード名: PascalCase
- シグナル名: 過去形（`soup_served`・`day_ended`）
- マジックナンバー禁止: 閾値・係数はすべて `const` か `.tres` に置く

## 実装マイルストーン
| # | 内容 | 完了条件 |
|---|---|---|
| M1 | コアロジック | Pot / Evaluator / SoupAttrs が UI 無しテストで動く |
| M2 | 夜営業の縦切り | 1晩・客3人が通しプレイ可能 |
| M3 | 昼パート | 市場・仕込み・金欠→残り湯が動く |
| M4 | 7日ループ | セーブ・エンディング分岐まで通し可能 |
| M5 | ポリッシュ | 本番素材・SE/BGM・演出 |
| M6 | 体験版 | Day1〜3・客4人のビルド書き出し |

## TODO
- **NEWGAME 押下時に GameState をリセットする処理**（セーブ/ニューゲーム設計時にまとめて実装）
- **ADVパート**: 会話システムは Dialogic 2 を使用
- **経営パート**: 食材購入・メニュー選択・売り上げ計算
- **日数サイクル**: 複数日進行とエンディング分岐（Day7 は評判閾値でルート分岐）
