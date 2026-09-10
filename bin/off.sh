#!/bin/bash
# Deep Work OFF — restore the normal environment. Mirror of on.sh.
set +e

# 1) Dock → back to always-visible
defaults write com.apple.dock autohide -bool false
killall Dock 2>/dev/null

# 2) Desktop icons → shown again
defaults write com.apple.finder CreateDesktop -bool true
killall Finder 2>/dev/null

# 3) Focus + Slack DND off — runs the paired Shortcut if you made one.
shortcuts run "Deep Work Off" 2>/dev/null || true

echo "☕  Deep Work OFF — dock + desktop restored."
