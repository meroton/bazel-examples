#!/bin/sh

file=$1; shift

"$@" && touch "$file"
