#!/bin/sh
# https://snippets.martinwagner.co/2018-03-04/vim-anywhere

file=$(mktemp)
gvim --nofork "$file"

xdotool type --delay 0 --file "$file"
rm "$file"
