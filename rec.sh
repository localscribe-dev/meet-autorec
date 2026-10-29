#!/bin/zsh
# Meetの録音。自分（マイク）と相手（BlackHole＝Meetの出力）を別ファイルに録る。
# 使い方: rec.sh start [会議名] / rec.sh stop
# 前提: Meetの設定 → 音声 → スピーカーを「Meet録音用」にしておく
D=${0:A:h}/recordings
mkdir -p $D
case $1 in
start)
  out=$D/$(date +%Y%m%d_%H%M)_${2:-meet}
  mkdir -p $out
  # 1本のffmpegに2入力を渡すとマイク側が途中で止まるので、2本に分ける
  ffmpeg -nostdin -hide_banner -loglevel error -f avfoundation -i ":default" \
    -ac 1 -ar 16000 $out/me.wav 2> $out/ffmpeg_me.log &
  pids=$!
  ffmpeg -nostdin -hide_banner -loglevel error -f avfoundation -i ":BlackHole 2ch" \
    -ac 1 -ar 16000 $out/them.wav 2> $out/ffmpeg_them.log &
  echo "$pids $!" > $D/.pid
  echo $out > $D/.current
  echo "録音開始: $out"
  ;;
stop)
  for pid in $(cat $D/.pid); do
    kill -INT $pid
    while kill -0 $pid 2>/dev/null; do sleep 0.5; done
  done
  echo "録音終了: $(cat $D/.current)"
  ;;
*) echo "使い方: $0 start [会議名] | stop" ;;
esac
