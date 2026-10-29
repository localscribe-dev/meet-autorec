# meet-autorec

Google Meet に入ると自動で録音を始め、退出すると止めて、話者付きの文字起こしを作る Mac 用ツール。
すべて Mac の中で処理し、音声を外部サービスに送らない。

Auto-record Google Meet on macOS (Apple Silicon) and produce a speaker-labeled transcript locally,
using BlackHole, ffmpeg, mlx-whisper and pyannote.audio.

## 仕組み

- `micuse` が5秒ごとに「いまマイクを使っているアプリ」を調べる（CoreAudio）
- Chrome がマイクを使い始めたら録音開始。使わなくなって20秒たったら停止する
- 自分の声はマイクから、相手の声は BlackHole（Meet の出力）から、別々のファイルに録る
  - `me.wav`（自分）／ `them.wav`（相手）
- 停止後、pyannote で話している区間を切り出し、区間ごとに whisper で文字にする
  - 相手が複数人なら pyannote が `SPEAKER_00` などに分ける
- 結果は `recordings/<日時>_meet/transcript.txt`

```
[00:02] 自分: よろしくお願いします。
[00:05] SPEAKER_00: よろしくお願いします。では進捗から。
```

1分未満の録音は会議ではないとみなして捨てる。開始・停止・完了は Mac の通知で知らせる。

## 必要なもの

- Apple Silicon の Mac（mlx-whisper のため）、macOS 14 以降
- Homebrew、Python 3.10 以降、Xcode Command Line Tools（`swiftc`）
- Hugging Face のアカウント（無料）
- イヤホン（スピーカーだと相手の声がマイクにも入る）

## インストール

```bash
git clone https://github.com/localscribe-dev/meet-autorec.git
cd meet-autorec
./install.sh
```

ffmpeg・BlackHole・Python ライブラリを入れ、ログイン時に自動で動くよう登録する。
BlackHole のインストールで Mac のパスワードを聞かれる。

## 初回の設定

1. **複数出力装置を作る**
   「Audio MIDI 設定」アプリで左下の「＋」→「複数出力装置を作成」。
   ふだん使うイヤホンと「BlackHole 2ch」にチェックを入れ、BlackHole の「同期」にもチェックを入れる。
   名前は「Meet録音用」などにしておく。
2. **Meet の出力先を変える**
   Meet の「設定 → 音声 → スピーカー」で、1 で作った装置を選ぶ。
   Mac 全体の出力先は変えなくてよい（変えると音量キーが効かなくなる）。
3. **pyannote のモデルを使えるようにする**
   - https://huggingface.co/pyannote/speaker-diarization-community-1 で利用条件に同意する
   - `.venv/bin/hf auth login` でログインする
4. **マイクの許可**
   最初の録音で「マイクへのアクセス」を聞かれたら許可する。

## 使い方

Chrome で Meet に入るだけ。手動で録る・文字起こしすることもできる。

```bash
./rec.sh start 会議名
./rec.sh stop
.venv/bin/python transcribe.py recordings/<フォルダ> 2   # 最後の数字は相手の人数（省略可。1なら話者分けしない）
```

止めるときは `./uninstall.sh`。

## 設定

`watch.sh` の先頭で変えられる。

- `APP_PATTERN`：録音のきっかけにするアプリ。Chrome 以外のブラウザを使うなら、会議中に `./micuse` を実行し、出てきた ID に合わせる

## 注意

- **録音する前に、相手の同意を取ること。**
- Chrome がマイクを使うと、Meet 以外（音声入力など）でも録音が始まる。1分未満なら自動で捨てる。
- 録音は `recordings/` にそのまま残る。不要になったら消すこと。

## 使っているもの

このリポジトリには含まない。各自のライセンスに従う。

- [BlackHole](https://github.com/ExistentialAudio/BlackHole)（GPL-3.0）
- [FFmpeg](https://ffmpeg.org/)
- [mlx-whisper](https://github.com/ml-explore/mlx-examples)（MIT）、モデル `mlx-community/whisper-large-v3-turbo`
- [pyannote.audio](https://github.com/pyannote/pyannote-audio)（MIT）、モデル `pyannote/speaker-diarization-community-1`（CC-BY-4.0）

## ライセンス

MIT
