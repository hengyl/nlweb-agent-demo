#!/bin/bash

# Check if RUN_LOAD_DATA environment variable is set to true
if [ "$RUN_LOAD_DATA" == "false" ]; then
    echo "Skipping data loading script. Set RUN_LOAD_DATA to 'true' to run this script."
    exit 0
fi

. ./scripts/load_python_env.sh

echo 'Running "load_data.py"'

./.venvsh/bin/python3 ./scripts/nlweb-data/load_data.py 
