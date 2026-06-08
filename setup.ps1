Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "        INSTALADOR AUTOMATICO - A7 PHARMA         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------
# FUNCAO INTERNA DE SEGURANCA (Desembaralha os dados em Base64)
# ----------------------------------------------------------------
function Get-DecodedString ($b64) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
}

# ----------------------------------------------------------------
# 1. CONTROLE DE ACESSO POR SENHA
# ----------------------------------------------------------------
# Senha configurada: 
$senhaOculta = "c3VwZXJ0dXg="
$senhaCorreta = Get-DecodedString $senhaOculta

$senhaDigitada = Read-Host "Por favor, digite a senha de autorizacao"

if ($senhaDigitada -cne $senhaCorreta) {
    Write-Host ""
    Write-Host "[-] ACESSO NEGADO: Senha incorreta!" -ForegroundColor Red
    Write-Host "[!] A instalacao foi cancelada pelo sistema." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    exit
}

Write-Host ""
Write-Host "[+] Senha aceita com sucesso!" -ForegroundColor Green
Write-Host "[+] Iniciando a preparacao do ambiente..." -ForegroundColor Cyan

# Cria uma pasta temporária no disco C: para baixar os instaladores
$tempDir = "C:\TempInstaladores"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# ----------------------------------------------------------------
# 2. LINKS DE DOWNLOAD DIRETO - DROPBOX (OFUSCADOS EM BASE64)
# ----------------------------------------------------------------
$urlA7PDV   = Get-DecodedString "aHR0cHM6Ly93d3cuZHJvcGJveC5jb20vc2NsL2ZpLzRhbzRpazR3aWZ1enk0Z3lmYmM5Yy9BN1BoYXJtYS1QRFYtMy4xMDQuMTEuMC5leGU/cmxrZXk9enV1Mzk4cjIxbXZ6amxlOTl1cGlseTRwaiZzdD1iZ252eDl5NSZkbD0x"
$urlA7Retag = Get-DecodedString "aHR0cHM6Ly93d3cuZHJvcGJveC5jb20vc2NsL2ZpLzIzdW4xdzNmMTNiZWpuaHZ2bXB0My9JbnN0YWxhZG9yX0E3UGhhcm1hLmV4ZT9ybGtleT16bHRqZTNyZmx0ZnZyNW1mNWR3bHVvaGxlJnN0PW9veWttMXZ3JmRsPTE="
$urlNotepad = Get-DecodedString "aHR0cHM6Ly93d3cuZHJvcGJveC5jb20vc2NsL2ZpL3dvdm5jZHZiMnA4cnA5Mmw2anVkMC9ucHAuOC45LjYuMi5JbnN0YWxsZXIueDY0LmV4ZT9ybGtleT1zdjR1ejFoMmt0MWthcTlhcWY4enN1dHpjJnN0PXVpZDV3MHUwJmRsPTE="

# ----------------------------------------------------------------
# 3. BAIXANDO OS ARQUIVOS
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Baixando instalador do A7 PDV..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $urlA7PDV -OutFile "$tempDir\a7pdv.exe" -UseBasicParsing

Write-Host "=> Baixando instalador do A7 Retaguarda..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $urlA7Retag -OutFile "$tempDir\a7retag.exe" -UseBasicParsing

Write-Host "=> Baixando instalador do Notepad++..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $urlNotepad -OutFile "$tempDir\npp.exe" -UseBasicParsing

# ----------------------------------------------------------------
# 4. EXECUTANDO AS INSTALACOES (MODO 100% SILENCIOSO)
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Instalando A7 PDV silenciosamente..." -ForegroundColor Cyan
$argumentosA7 = "/S"
Start-Process -FilePath "$tempDir\a7pdv.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

Write-Host "=> Instalando A7 Retaguarda silenciosamente..." -ForegroundColor Cyan
Start-Process -FilePath "$tempDir\a7retag.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

Write-Host "=> Instalando Notepad++..." -ForegroundColor Cyan
Start-Process -FilePath "$tempDir\npp.exe" -ArgumentList "/S" -Wait -NoNewWindow

# ----------------------------------------------------------------
# 5. CONFIGURANDO O ARQUIVO PDV.PROPERTIES (OPCIONAL)
# ----------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
$desejaConfigurar = Read-Host "Deseja configurar o arquivo pdv.properties neste momento? (S/N)"

if ($desejaConfigurar -match "^[sS]$") {
    Write-Host ""
    Write-Host "=> Iniciando configuracao do PDV..." -ForegroundColor Cyan

    $ipDigitado = Read-Host "Digite APENAS o IP do Servidor (ex: 192.168.0.10)"
    $caixaDigitado = Read-Host "Digite o Numero do Caixa (ex: 01)"
    $ipImpressora = Read-Host "Digite o IP do comp. da impressora (ex: 192.168.0.10)"
    $compImpressora = Read-Host "Digite o Compartilhamento da impressora (ex: epson)"

    # Caminho padrão onde o arquivo é gerado
    $caminhoProperties = "C:\A7Pharma\PDV\pdv.properties"

    if (Test-Path $caminhoProperties) {
        Write-Host "Injetando informacoes e descomentando campos..." -ForegroundColor Yellow
        
        $conteudo = Get-Content $caminhoProperties
        
        $conteudo = $conteudo -replace "^servidor\.webServicesURL=.*", "servidor.webServicesURL=http://${ipDigitado}:8080/chinchila-chinchila-ejb-core/PDVWebServices?wsdl"
        $conteudo = $conteudo -replace "^servidor\.numeroCaixa=.*", "servidor.numeroCaixa=$caixaDigitado"
        $conteudo = $conteudo -replace "^#\s*pdv\.tipoDocumentoFiscal=.*", "pdv.tipoDocumentoFiscal=NFCE"
        $conteudo = $conteudo -replace "^#\s*impressora\.modelo=.*", "impressora.modelo=epson"
        $conteudo = $conteudo -replace "^#\s*impressora\.endereco=.*", "impressora.endereco=\\\\${ipImpressora}\\${compImpressora}"
        
        Set-Content -Path $caminhoProperties -Value $conteudo
        
        Write-Host "[+] Arquivo pdv.properties configurado e ativado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "[-] ERRO: Arquivo pdv.properties nao encontrado no caminho: $caminhoProperties" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "[i] Configuracao ignorada. O arquivo pdv.properties foi mantido no padrao." -ForegroundColor Gray
}

# ----------------------------------------------------------------
# 6. LIMPEZA DOS ARQUIVOS TEMPORARIOS
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Finalizando e limpando arquivos temporarios..." -ForegroundColor Gray
Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "     [✓] TODOS OS PROGRAMAS FORAM INSTALADOS!     " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
