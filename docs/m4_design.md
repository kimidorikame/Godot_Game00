# 夜湯 — M4 設計メモ（骨子）

作成日: 2026-08-05
対象: 数週間後の自分、新しく参加する人
対応ファイル: `autoload/save_manager.gd` / `autoload/game_state.gd` / `resources/day_schedule_resource.gd`（新規） / `scenes/home/result.gd` / `scenes/title/`

---

## このメモの目的

M4「セーブ・7日ループ・エンディング分岐」の骨子部分の設計を確定させる。
拡張（客データ充実・クズ食材脱出動線）は骨子の外とし、別途M4後半以降で乗せる。

## M4骨子の完了条件

NEWGAMEから7日間、就寝時にセーブしながら通しでプレイでき、Day7で評判に応じて
エンディングA/Bに分岐する。タイトルからCONTINUEで再開できる。
客・会話は現状のダミー3人使い回しのままでよい。

---

## 確定した設計方針

- 就寝時セーブのみ（Result画面でのみセーブ。日の途中セーブなし）。
  よって phase は保存対象に含めない（phase enum は将来用に器だけ残す）
- エンディング分岐は reputation 1軸のみ（設計書11章準拠）。
  story_flags は保存対象に入れるが中身は骨子では使わない（会話フェーズで使用）
- セーブは1スロット（SAVE_PATH固定）
- 客データ拡充・クズ食材脱出動線は骨子外（この基盤の上に後日乗せる）

---

## 実装する5要素

### 1. SaveManager（セーブ本体）

- 保存対象: GameStateの day / money / reputation / inventory / story_flags（phase は除外）
- `save()`: 対象プロパティを Dictionary に集約し JSON.stringify して SAVE_PATH に書く
- `load_game()`: SAVE_PATH を読んで GameState に流し込む。ファイルが無ければ false を返す
  （呼び出し側がセーブ有無を判断できるように）

why: 全プロパティが単純型なのでJSON化が最も簡単。就寝時のみ保存なので phase の保存は不要。

### 2. DaySchedule（7日ループの骨格）

- `day_schedule_resource.gd` を新規作成
  （設計書3.4節: `day:int` / `visitors:Array[StringName]` / `previewed:Array[StringName]` / `note:String`）
- `data/schedule/` に7日分の .tres を配置。骨子では客が3人（roujin/haitatsuin/keiji）のみなので、
  Day1〜7すべて3人使い回しの仮データ。設計書8章の本来のマトリクスは客データが揃ってから差し替える
- `game.gd` の `_customers` 固定配列を、`GameState.day` に応じて DaySchedule から引く形に差し替える

why: 「7日通しで動く」ことを骨子で検証したいので、仮データでも全7日分を用意する。

### 3. タイトル画面 NEWGAME / CONTINUE 呼び分け

- NEWGAME: `reset_for_new_game()` で初期化 → Day1の昼（DestinationSelect）へ。
  既存セーブは上書きでよい（確認ダイアログはMVPでは省略）
- CONTINUE: `load_game()` を呼び、成功したら保存された day の昼へ。
  失敗（セーブ無し）ならボタン無効 or 押しても無反応

注: 現状 `reset_for_new_game()` の呼び出し実態を実装前に再確認すること
（現状把握では「どこからも呼ばれていない」との指摘あり）。

### 4. Day7判定・エンディング分岐

骨子の分岐条件（簡略版・1段階）:

- Day7の営業終了時点で `reputation >= REP_ENDING_THRESHOLD(=5)` → エンディングA
- 未満 → エンディングB

骨子で作らないもの（後日）: 謎の男の実来店、「最後の一杯がGREATか」の2段目判定。
これらは客・会話が揃ってから足す。

エンディング画面: 専用シーンを1つ作り、A/Bでテキストを差し替える
（例 `Ending.tscn` に結末テキストを渡す）。表示後タイトルへ戻る。

why: Resultは日々の精算画面、エンディングは別物なので分離する。
2段目判定を省いても「2種類に分岐する」ことは検証できる。

### 5. Result画面のセーブ配線と Day7 特殊遷移

- 「翌日へ」押下時（就寝時）に `next_day()` → `save()` の順で実行
  - why: ロード時に「次にプレイすべき日」の状態で復元したいため。
    Day3終了時のセーブは day=4 の状態を保存し、ロードするとDay4の昼から始まる
- Day7 特殊分岐: 現在の day が7なら「翌日へ」ではなく Day7判定（要素4）を走らせてエンディングへ遷移。
  Day7はセーブしない（クリア後のセーブ管理はMVP不要）
- Day1〜6は従来通り DestinationSelect へ

---

## 実装順（依存関係順・次回はこの順で小分けに進める）

1. SaveManager本体（save/load_game）。単体でテスト可能
2. DaySchedule（クラス＋7日分仮.tres）＋ game.gd の客参照切り替え
3. Result画面のセーブ配線（next_day→save、Day7分岐の受け皿）
4. Day7判定＋エンディング専用シーン（Ending.tscn とA/B遷移）
5. タイトルの NEWGAME/CONTINUE 呼び分け（load_game接続）

各ステップ完了ごとに動作確認し、通ったら次へ。
全部通ったら「NEWGAME→7日→エンディング→タイトル→CONTINUE」の通しテストで骨子完了とする。

---

## 骨子の外（M4後半以降）

- 客データ拡充（3人→設計書8章の6人、来店マトリクス本実装）
- 会話の客ごと・日ごと出し分けと本文（会話全面改訂フェーズ）
- クズ食材脱出動線（日またぎの鍋持ち越し状態をGameStateにどう持たせるか含め未設計。
  セーブ基盤ができてから設計。詳細は `docs/poverty_fallback_design.md`）
- Day7エンディングの2段目判定（謎の男の来店＋最後の一杯GREAT判定）
