Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "        INSTALADOR AUTOMATICO - A7 PHARMA         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------
# 0. VERIFICACAO DE ADMINISTRADOR
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
# FUNCAO INTERNA DE SEGURANCA
# ----------------------------------------------------------------
function Get-DecodedString ($b64) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
}

# ----------------------------------------------------------------
# 1. CONTROLE DE ACESSO POR SENHA
# ----------------------------------------------------------------
$senhaOculta = "c3VwZXJ0dXg="
$senhaCorreta = Get-DecodedString $senhaOculta

# A senha digitada sera exibida com asteriscos
$senhaSegura = Read-Host "Por favor, digite a senha de autorizacao" -AsSecureString
$ponteiroSenha = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($senhaSegura)
$senhaDigitada = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ponteiroSenha)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ponteiroSenha)

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

# Cria uma pasta temporaria no disco C:
$tempDir = "C:\TempInstaladores"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# ----------------------------------------------------------------
# 2. LINKS DE DOWNLOAD DIRETO (OFUSCADOS EM BASE64)
# ----------------------------------------------------------------
$urlA7PDV = Get-DecodedString "aHR0cHM6Ly93d3cuZHJvcGJveC5jb20vc2NsL2ZpLzRhbzRpazR3aWZ1enk0Z3lmYmM5Yy9BN1BoYXJtYS1QRFYtMy4xMDQuMTEuMC5leGU/cmxrZXk9enV1Mzk4cjIxbXZ6amxlOTl1cGlseTRwaiZzdD1iZ252eDl5NSZkbD0x"

$urlA7Retag = Get-DecodedString "aHR0cHM6Ly9kb3dubG9hZC5hNy5uZXQuYnIvYXJxdWl2b3MvSW5zdGFsYWRvcl9BN1BoYXJtYS5leGU="

$urlNotepad = Get-DecodedString "aHR0cHM6Ly93d3cuZHJvcGJveC5jb20vc2NsL2ZpL3dvdm5jZHZiMnA4cnA5Mmw2anVkMC9ucHAuOC45LjYuMi5JbnN0YWxsZXIueDY0LmV4ZT9ybGtleT1zdjR1ejFoMmt0MWthcTlhcWY4enN1dHpjJnN0PXVpZDV3MHUwJmRsPTE="

# ----------------------------------------------------------------
# 3. BAIXANDO OS ARQUIVOS
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Baixando instaladores na velocidade MAXIMA da sua internet..." -ForegroundColor Yellow
Write-Host "[i] A barra de progresso foi desativada propositalmente para evitar lentidao." -ForegroundColor Gray
Write-Host ""

# Evita problemas de conexao HTTPS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$webClient = New-Object System.Net.WebClient

Write-Host " -> Baixando A7 PDV (Aguarde alguns segundos)..." -ForegroundColor Cyan
$webClient.DownloadFile($urlA7PDV, "$tempDir\a7pdv.exe")

Write-Host " -> Baixando A7 Retaguarda (Aguarde)..." -ForegroundColor Cyan
$webClient.DownloadFile($urlA7Retag, "$tempDir\a7retag.exe")

Write-Host " -> Baixando Notepad++..." -ForegroundColor Cyan
$webClient.DownloadFile($urlNotepad, "$tempDir\npp.exe")

$webClient.Dispose()

# ----------------------------------------------------------------
# 4. EXECUTANDO AS INSTALACOES
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Instalando A7 PDV silenciosamente..." -ForegroundColor Yellow

$argumentosA7 = "-q"

Start-Process -FilePath "$tempDir\a7pdv.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

Write-Host "=> Instalando A7 Retaguarda silenciosamente..." -ForegroundColor Yellow

Start-Process -FilePath "$tempDir\a7retag.exe" -ArgumentList $argumentosA7 -Wait -NoNewWindow

Write-Host "=> Instalando Notepad++ silenciosamente..." -ForegroundColor Yellow

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

        # Altera o endereco do servidor e numero do caixa
        $conteudo = $conteudo -replace "^servidor\.webServicesURL=.*", "servidor.webServicesURL=http://${ipDigitado}:8080/chinchila-chinchila-ejb-core/PDVWebServices?wsdl"
        $conteudo = $conteudo -replace "^servidor\.numeroCaixa=.*", "servidor.numeroCaixa=$caixaDigitado"

        # Descomenta as configuracoes da NFC-e e impressora Epson
        $conteudo = $conteudo -replace "^#\s*pdv\.tipoDocumentoFiscal=NFCE", "pdv.tipoDocumentoFiscal=NFCE"
        $conteudo = $conteudo -replace "^#\s*impressora\.modelo=epson", "impressora.modelo=epson"

        # Configura o endereco da impressora
        $conteudo = $conteudo -replace "^#\s*impressora\.endereco=.*ENDERECO_IP_MAQUINA.*", "impressora.endereco=\\${ipImpressora}\${compImpressora}"

        Set-Content -Path $caminhoProperties -Value $conteudo

        Write-Host "[+] Arquivo pdv.properties configurado com precisao!" -ForegroundColor Green
    }
    else {
        Write-Host "[-] ERRO: Arquivo pdv.properties nao encontrado no caminho: $caminhoProperties" -ForegroundColor Red
    }
}
else {
    Write-Host ""
    Write-Host "[i] Configuracao ignorada. O arquivo pdv.properties foi mantido no padrao." -ForegroundColor Gray
}

# ----------------------------------------------------------------
# 6. CRIANDO ATALHOS NA AREA DE TRABALHO
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Criando atalhos na Area de Trabalho..." -ForegroundColor Yellow

$desktop = [Environment]::GetFolderPath("Desktop")
$pastaIcones = "C:\ProgramData\A7Pharma\Icones"

New-Item -ItemType Directory -Force -Path $pastaIcones | Out-Null

$logoA7Png = "$pastaIcones\Alpha7.png"
$logoA7Ico = "$pastaIcones\Alpha7.ico"
$aprendaIco = "$pastaIcones\Aprenda7.ico"

# Baixa os icones oficiais
$iconClient = New-Object System.Net.WebClient
$iconClient.DownloadFile(
    "https://chat.a7.net.br/assets/img/logo_alpha7.png",
    $logoA7Png
)

$iconClient.DownloadFile(
    "https://aprenda.a7.net.br/pluginfile.php/1/theme_moove/favicon/1783685431/Favicon.ico",
    $aprendaIco
)

$iconClient.Dispose()

# Converte a logo Alpha7 de PNG para ICO
Add-Type -AssemblyName System.Drawing

$imagem = [System.Drawing.Bitmap]::FromFile($logoA7Png)
$icone = [System.Drawing.Icon]::FromHandle($imagem.GetHicon())
$arquivoIcone = New-Object System.IO.FileStream(
    $logoA7Ico,
    [System.IO.FileMode]::Create
)

$icone.Save($arquivoIcone)
$arquivoIcone.Close()
$arquivoIcone.Dispose()
$icone.Dispose()
$imagem.Dispose()

Remove-Item $logoA7Png -Force

$atalhos = @(
    @{
        Nome = "Alpha7 Suporte"
        Url = "https://chat.a7.net.br/"
        Icone = $logoA7Ico
    },
    @{
        Nome = "Base de Conhecimento"
        Url = "https://kb.a7.net.br/P%C3%A1gina_principal"
        Icone = $logoA7Ico
    },
    @{
        Nome = "Aprenda7"
        Url = "https://aprenda.a7.net.br/login/index.php"
        Icone = $aprendaIco
    }
)

foreach ($atalho in $atalhos) {
    $caminhoAtalho = "$desktop\$($atalho.Nome).url"

    # Remove o atalho antigo para evitar cache do icone
    if (Test-Path $caminhoAtalho) {
        Remove-Item $caminhoAtalho -Force
    }

    $conteudoAtalho = @"
[InternetShortcut]
URL=$($atalho.Url)
IconFile=$($atalho.Icone)
IconIndex=0
"@

    Set-Content `
        -Path $caminhoAtalho `
        -Value $conteudoAtalho `
        -Encoding ASCII

    Write-Host "[+] Atalho criado: $($atalho.Nome)" -ForegroundColor Green
}

# Solicita ao Windows que atualize os icones
Start-Process `
    -FilePath "$env:SystemRoot\System32\ie4uinit.exe" `
    -ArgumentList "-show" `
    -WindowStyle Hidden `
    -ErrorAction SilentlyContinue
# ----------------------------------------------------------------
# 7. LIMPEZA DOS ARQUIVOS TEMPORARIOS
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Finalizando e limpando arquivos temporarios..." -ForegroundColor Gray

Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "     [OK] TODOS OS PROGRAMAS FORAM INSTALADOS!    " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
