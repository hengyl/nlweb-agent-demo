# Check if run_load_data environment variable is set to true
if ($env:RUN_LOAD_DATA -ne "true") {
    Write-Host "Skipping data loading script. Set env:RUN_LOAD_DATA to 'true' to run this script." -ForegroundColor Yellow
    exit 0
}

./scripts/load_python_env.ps1

$venvPythonPath = "./.venv/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./.venv/bin/python"
}

Write-Host 'Running "data_loading.db_load"'


# python -m data_loading.db_load https://feeds.libsyn.com/121695/rss Behind-the-Tech
$cwd = (Get-Location)
$dataArg = "https://feeds.libsyn.com/121695/rss Behind-the-Tech"
$argumentList = "-m data_loading.db_load $dataArg"

$venvPythonPath
$argumentList

$securePassword = Read-Host "Enter Azure AI Search key" -AsSecureString
$plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

$env:AZURE_AI_SEARCH_API_KEY = $plainPassword


$envList = azd env list --output json | ConvertFrom-Json
$defaultEnv = $envList | Where-Object { $_.isDefault -eq $true }
if (-not $defaultEnv) {
    Write-Host "No default azd environment found." -ForegroundColor Red
    exit 1
}

Write-Host "Default environment:" $defaultEnv.name
$envFile = Join-Path -Path ".azure" -ChildPath "$($defaultEnv.name)\.env"

if (-not (Test-Path $envFile)) {
    Write-Host "Could not find .env file at $envFile" -ForegroundColor Red
    exit 1
}
Copy-Item -Path $envFile -Destination "$cwd/scripts/nlwebdata/.env" -Force

Start-Process -FilePath $venvPythonPath -ArgumentList $argumentList -Wait -NoNewWindow -workingDirectory "$cwd/scripts/nlwebdata"
