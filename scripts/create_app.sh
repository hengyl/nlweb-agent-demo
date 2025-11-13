#!/bin/bash

. ./scripts/load_python_env.sh

echo 'Running "create_app.py"'

./.venvsh/bin/python3 ./scripts/app-deploy/create_app.py
