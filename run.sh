#!/usr/bin/env bash
cd "$(dirname "$0")"
source .venv/bin/activate
[ -f .env ] && set -a && source .env && set +a
python main_improved.py
