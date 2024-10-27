#!/bin/env bash

if ! command -v nvim &>/dev/null; then
	echo "nvim command not found"
	exit 1
fi

nvim -l tests/minit.lua tests
