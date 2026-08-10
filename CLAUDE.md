# 夜湯 — 開発メモ

> 実装時は `D:\Projects\GODOT\Game00\夜湯_技術設計書_v0.2.md` のコードと規約に従う。

## ゲーム概要
会話ADV × 軽経営シム。深夜の屋台でスープを売りながら客との対話を楽しむゲーム。

## 技術スタック
- Godot 4.7 / GL Compatibility
- 解像度: 1920 × 1080（canvas_items stretch）
- 言語: GDScript（静的型付け徹底・class_name 全クラスに付与）
- 会話エンジン: Dialogic 2 アドオン（自作しない）

## 開発環境
- Godot 実行ファイル（エディタ実機プレイ・ヘッドレス実行/テスト共通、4.7.1）:
  `E:/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`

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
  ──[NEWGAME]──► scenes/market/DestinationSelect.tscn（行き先選択・昼）
				   ──[市場へ]──► scenes/market/Shop.tscn（市場・仕入れ）
								   ──[夜営業へ]──► scenes/night/Game.tscn（仕込み→夜営業）
													 ──[営業終了]──► scenes/home/Result.tscn
																	   ──[翌日へ]──► scenes/market/DestinationSelect.tscn
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
| M3 | 昼パート | 市場・仕込み・金欠→残り湯が動く ✅完了 |
| M4 | 7日ループ | セーブ・エンディング分岐まで通し可能 ✅完了 |
| M5 | ポリッシュ | 本番素材・SE/BGM・演出 |
| M6 | 体験版 | Day1〜3・客4人のビルド書き出し |

## TODO
- **ADVパート**: 会話システムは Dialogic 2 を使用
- **経営パート**: 食材購入・メニュー選択・売り上げ計算
- **夜営業ループへのリアクション会話追加**: 提供後の客のリアクション会話をループに追加する（客登場会話→味付け→提供→評価→「リアクション会話」→次の客）。Dialogic導入フェーズで、提供前会話とセットで実装。BADのときは worst_axis からヒント台詞を出す（設計書9章）
- **会話全面改訂（Dialogicダミー導入からの本実装）**: 夜営業の会話は現在ダミー1本（`d1_roujin`）を全客で固定再生している。今後の会話全面改訂フェーズで、客ごと・日ごとのタイムライン（設計書7章の `d{日}_{客id}` 規約）を用意し、`game.gd` で現在の客に応じて再生するタイムラインを切り替える処理を実装する。提供後リアクション会話・会話分岐（reputation/story_flags 同期）もこのフェーズでまとめて対応する
- **困窮脱出動線（クズ食材ベース）**: 「所持金0＆ベース素材0」の継続的な詰み状態を救う脱出ハッチ。M3の「その日限り残り湯」とは別役割。日またぎの鍋持ち越し・状態判定が前提のためM4（セーブ・7日ループ）実装時にまとめて設計・実装する。詳細は `docs/poverty_fallback_design.md`
- **セーブ再開位置のUX調整（M5検討）**: 日の途中（営業終了画面）からのLOADで当日頭に戻る違和感の解消。詳細は progress_log 参照
