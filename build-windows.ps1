$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
function Run-Flutter { & flutter @args; if ($LASTEXITCODE -ne 0) { throw "Flutter failed: $args" } }
if (!(Test-Path windows/runner)) {
  $seed = Join-Path ([IO.Path]::GetTempPath()) ("sahm-" + [Guid]::NewGuid())
  Run-Flutter create --no-pub --platforms=windows --project-name sahm $seed
  Copy-Item -Recurse (Join-Path $seed 'windows') windows
}
Copy-Item -Force assets/app_icon.ico windows/runner/resources/app_icon.ico
Run-Flutter pub get
Run-Flutter test
Run-Flutter build windows --release
if (Get-Command ISCC.exe -ErrorAction SilentlyContinue) {
  & ISCC.exe installer.iss
  if ($LASTEXITCODE -ne 0) { throw "Installer compilation failed" }
}
