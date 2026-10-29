#!/bin/zsh
# 自動録音の登録を外す（録音データとこのフォルダは残る）
plist=~/Library/LaunchAgents/local.meet-autorec.plist
launchctl unload $plist && rm $plist && echo "自動録音を止めました"
