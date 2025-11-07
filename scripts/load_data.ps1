# Check if run_load_data environment variable is set to false
if ($env:RUN_LOAD_DATA -eq "false") {
    Write-Host "Skipping data loading script. Set env:RUN_LOAD_DATA to 'true' to run this script." -ForegroundColor Yellow
    exit 0
}

& "$PSScriptRoot/load_python_env.ps1"

$venvPythonPath = "./.venv/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./.venv/bin/python"
}

Write-Host 'Running "load_data.py"'

Start-Process -FilePath $venvPythonPath -ArgumentList "load_data.py" -Wait -NoNewWindow -workingDirectory "$PSScriptRoot/nlweb-data"
