Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "        INSTALADOR AUTOMATICO - A7 PHARMA         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------
# 0. VERIFICACAO DE ADMINISTRADOR (EVITA ERRO DE ELEVACAO)
# ----------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[-] ERRO: O PowerShell NAO esta executando como Administrador!" -ForegroundColor Red
    Write-Host "[!] Feche esta janela, clique com o botao direito no PowerShell e escolha 'Executar como Administrador'." -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Seconds 5
    exit
}

# ----------------------------------------------------------------
# FUNCAO INTERNA DE SEGURANCA (Desembaralha os dados em Base64)
# ----------------------------------------------------------------
function Get-DecodedString ($b64) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
}

# ----------------------------------------------------------------
# 1. CONTROLE DE ACESSO POR SENHA
# ----------------------------------------------------------------
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
# 3. BAIXANDO OS ARQUIVOS (MODO ULTRA-RAPIDO WebClient)
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Baixando instaladores na velocidade MAXIMA da sua internet..." -ForegroundColor Yellow
Write-Host "[i] A barra de progresso foi desativada propositalmente para evitar lentidao." -ForegroundColor Gray
Write-Host ""

$webClient = New-Object System.Net.WebClient

Write-Host " -> Baixando A7 PDV (Aguarde alguns segundos)..." -ForegroundColor Cyan
$webClient.DownloadFile($urlA7PDV, "$tempDir\a7pdv.exe")

Write-Host " -> Baixando A7 Retaguarda (Aguarde)..." -ForegroundColor Cyan
$webClient.DownloadFile($urlA7Retag, "$tempDir\a7retag.exe")

Write-Host " -> Baixando Notepad++..." -ForegroundColor Cyan
$webClient.DownloadFile($urlNotepad, "$tempDir\npp.exe")

# ----------------------------------------------------------------
# 4. EXECUTANDO AS INSTALACOES (MODO SILENCIOSO)
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Instalando A7 PDV silenciosamente..." -ForegroundColor Yellow

# ===> AQUI ESTA A ALTERACAO PARA O PADRAO JAVA <===
$argumentosA7 = "-q"

Start-Process -FilePath "$tempDir\a7pdv.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

Write-Host "=> Instalando A7 Retaguarda silenciosamente..." -ForegroundColor Yellow
Start-Process -FilePath "$tempDir\a7retag.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

Write-Host "=> Instalando Notepad++..." -ForegroundColor Yellow
Start-Process -FilePath "$tempDir\npp.exe" -ArgumentList "/S" -Wait -NoNewWindow

# ----------------------------------------------------------------
# 5. CONFIGURANDO O ARQUIVO PDV.PROPERTIES
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

    $caminhoProperties = "C:\Alpha7\A7Pharma-PDV\pdv.properties"

    if (Test-Path $caminhoProperties) {
        Write-Host "Injetando informacoes e descomentando campos especificos..." -ForegroundColor Yellow
        
        $conteudo = Get-Content $caminhoProperties
        
        # 1. Altera Servidor e Caixa normalmente
        $conteudo = $conteudo -replace "^servidor\.webServicesURL=.*", "servidor.webServicesURL=http://${ipDigitado}:8080/chinchila-chinchila-ejb-core/PDVWebServices?wsdl"
        $conteudo = $conteudo -replace "^servidor\.numeroCaixa=.*", "servidor.numeroCaixa=$caixaDigitado"
        
        # 2. Descomenta EXATAMENTE as linhas da NFCE e Epson (Ignorando SAT, Daruma, etc)
        $conteudo = $conteudo -replace "^#\s*pdv\.tipoDocumentoFiscal=NFCE", "pdv.tipoDocumentoFiscal=NFCE"
        $conteudo = $conteudo -replace "^#\s*impressora\.modelo=epson", "impressora.modelo=epson"
        
        # 3. Altera APENAS a linha de endereço que contém o texto de exemplo de rede
        $conteudo = $conteudo -replace "^#\s*impressora\.endereco=.*ENDERECO_IP_MAQUINA.*", "impressora.endereco=\\\\${ipImpressora}\\${compImpressora}"
        
        Set-Content -Path $caminhoProperties -Value $conteudo
        
        Write-Host "[+] Arquivo pdv.properties configurado com precisao!" -ForegroundColor Green
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
