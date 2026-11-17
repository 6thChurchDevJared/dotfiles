#!/bin/bash
# Deep Work ON — calm the environment. Everything here is reversible via off.sh.
# Does NOT touch Focus/Slack directly (only the Shortcuts UI can toggle Focus); if you
# create a "Deep Work On" Shortcut, this runs it to also flip Focus + Slack DND.
set +e

# 1) Dock → auto-hide (off-screen until you push into the corner)
defaults write com.apple.dock autohide -bool true
killall Dock 2>/dev/null

# 2) Desktop icons → hidden (clean wallpaper)
defaults write com.apple.finder CreateDesktop -bool false
killall Finder 2>/dev/null

# 3) Bring the terminal forward (open Ghostty if it isn't running)
open -a Ghostty 2>/dev/null

# 4) Focus + Slack DND — only a Shortcut can toggle macOS Focus. Runs it if present;
#    silently no-ops until you create the "Deep Work On" Shortcut (see the recipe).
shortcuts run "Deep Work On" 2>/dev/null || true

echo "🎯  Deep Work ON — dock hidden, desktop cleared, Ghostty up."
echo "    (Create a 'Deep Work On' Shortcut to also flip Focus + Slack DND.)"
