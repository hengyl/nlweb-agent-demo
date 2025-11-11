 #!/bin/sh

echo 'Creating Python virtual environment ".venvsh"...'
python3 -m venv .venvsh

echo 'Installing dependencies from "requirements.txt" into virtual environment...'
.venvsh/bin/python -m pip --disable-pip-version-check install -r scripts/nlweb-data/requirements.txt
