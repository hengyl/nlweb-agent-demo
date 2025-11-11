 #!/bin/sh

. ./scripts/load_python_env.sh

echo 'Running "load_data.py"'

./.venvsh/bin/python3 ./scripts/nlweb-data/load_data.py 
