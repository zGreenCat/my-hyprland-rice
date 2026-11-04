#!/bin/sh
# Compara la traducción Lua del repo contra los .conf vivos (~/.config/hypr), efecto por efecto.
set -e
here=$(cd "$(dirname "$0")" && pwd)
cd "$here/../../../.config/hypr"
lua5.4 -e "package.path='./?.lua;'..package.path; dofile('$here/mock.lua')" hyprland.lua > /tmp/lua-migration-calls.tsv
cut -f1 /tmp/lua-migration-calls.tsv | sort | uniq -c
python3 -I "$here/compare.py" /tmp/lua-migration-calls.tsv
Hyprland --verify-config -c "$PWD/hyprland.lua" 2>&1 | sed -n '/parsing result/,$p'
