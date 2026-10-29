#!/bin/zsh
# 必要なものを入れて、ログイン時に自動で動くよう登録する。使い方: ./install.sh
set -e
cd ${0:A:h}

brew install ffmpeg blackhole-2ch   # BlackHoleのインストールでMacのパスワードを聞かれる
[[ -e .venv ]] || python3 -m venv .venv
.venv/bin/pip install -q pyannote.audio mlx-whisper
swiftc -O micuse.swift -o micuse

plist=~/Library/LaunchAgents/local.meet-autorec.plist
sed "s#__DIR__#$PWD#g" launchagent.plist > $plist
launchctl unload $plist 2>/dev/null || true
launchctl load $plist

echo "インストール完了。残りの手順は README の「初回の設定」を見てください。"
