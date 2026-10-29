#!/bin/zsh
# Chromeがマイクを使い始めたら録音を始め、使い終わって20秒たったら止めて文字起こしする。
# install.sh が登録する LaunchAgent から常駐で動く。
cd ${0:A:h}

# 録音のきっかけにするアプリ（バンドルIDの正規表現）。
# Chrome以外のブラウザを使うなら、会議中に ./micuse を実行して出てきたIDに合わせる

APP_PATTERN='^com\.google\.Chrome'
PYTHON=./.venv/bin/python
notify() { osascript -e "display notification \"$1\" with title \"Meet録音\" sound name \"Glass\""; }

rec=0 idle=0 started=0
while true; do
  if ./micuse | grep -qE "$APP_PATTERN"; then
    idle=0
    if (( !rec )); then
      ./rec.sh start meet
      rec=1 started=$SECONDS
      notify "録音を開始しました"
    fi
  elif (( rec )); then
    (( idle += 5 ))
    if (( idle >= 20 )); then
      ./rec.sh stop
      rec=0 idle=0
      dir=$(cat recordings/.current)
      if (( SECONDS - 20 - started < 60 )); then
        # 1分未満は会議ではない（音声入力や接続テスト）とみなして捨てる
        rm -rf $dir
      else
        notify "録音を止めました。文字起こし中です"
        $PYTHON transcribe.py $dir > $dir/transcribe.log 2>&1 &&
          notify "文字起こしが終わりました" || notify "文字起こしに失敗しました（transcribe.log を確認）"
      fi
    fi
  fi
  sleep 5
done
