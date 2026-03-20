Write-Host "==> Iniciando a instalacao do A7 e Notepad++..." -ForegroundColor Cyan

# Cria uma pasta temporária no disco C: para baixar os instaladores
$tempDir = "C:\TempInstaladores"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# ----------------------------------------------------------------
# 1. DEFINA OS LINKS DO SEU GITHUB RELEASES AQUI
# ----------------------------------------------------------------
$urlNotepad = "https://github.com/FelipeSouza0/InstaladorAlpha/releases/download/v.1/npp.8.9.2.Installer.x64.exe"
$urlA7PDV = "https://github.com/FelipeSouza0/InstaladorAlpha/releases/download/v.1/Instalador_A7Pharma-PDV.exe"
$urlA7Retag = "https://github.com/FelipeSouza0/InstaladorAlpha/releases/download/v.1/Instalador_A7Pharma.exe"

# ----------------------------------------------------------------
# 2. BAIXANDO OS ARQUIVOS
# ----------------------------------------------------------------
Write-Host "Baixando Notepad++..."
Invoke-WebRequest -Uri $urlNotepad -OutFile "$tempDir\npp.exe"

Write-Host "Baixando A7 PDV..."
Invoke-WebRequest -Uri $urlA7PDV -OutFile "$tempDir\a7pdv.exe"

Write-Host "Baixando A7 Retaguarda..."
Invoke-WebRequest -Uri $urlA7Retag -OutFile "$tempDir\a7retag.exe"

# ----------------------------------------------------------------
# 3. EXECUTANDO AS INSTALAÇÕES (MODO SILENCIOSO)
# ----------------------------------------------------------------
Write-Host "Instalando Notepad++..."
Start-Process -FilePath "$tempDir\npp.exe" -ArgumentList "/S" -Wait -NoNewWindow

Write-Host "Instalando A7 PDV silenciosamente..."
# Testando o parâmetro silencioso padrão (Inno Setup)
$argumentosA7 = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
Start-Process -FilePath "$tempDir\a7pdv.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

Write-Host "Instalando A7 Retaguarda silenciosamente..."
Start-Process -FilePath "$tempDir\a7retag.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

# ----------------------------------------------------------------
# 4. LIMPEZA
# ----------------------------------------------------------------
Write-Host "Limpando arquivos temporarios..."
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "==> Instalacao concluida com sucesso!" -ForegroundColor Green
