
& "$PSScriptRoot/load_python_env.ps1"

$venvPythonPath = "./.venv/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./.venv/bin/python"
}

Write-Host 'Running "create_app.py"'

Start-Process -FilePath $venvPythonPath -ArgumentList "create_app.py" -Wait -NoNewWindow -workingDirectory "$PSScriptRoot/app-deploy"
