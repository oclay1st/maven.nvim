#!/bin/env bash

if ! command -v nvim &>/dev/null; then
  echo "nvim command not found"
  exit 1
fi

nvim --headless --noplugin -u tests/minit.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minit.lua'}" tests
