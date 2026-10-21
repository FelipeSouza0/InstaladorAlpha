        $conteudo = Get-Content $caminhoProperties

        # Altera o endereco do servidor e numero do caixa
        $conteudo = $conteudo -replace "^servidor\.webServicesURL=.*", "servidor.webServicesURL=http://${ipDigitado}:8080/chinchila-chinchila-ejb-core/PDVWebServices?wsdl"
        $conteudo = $conteudo -replace "^servidor\.numeroCaixa=.*", "servidor.numeroCaixa=$caixaDigitado"

        # Descomenta as configuracoes da NFC-e e impressora Epson
        $conteudo = $conteudo -replace "^#\s*pdv\.tipoDocumentoFiscal=NFCE", "pdv.tipoDocumentoFiscal=NFCE"
        $conteudo = $conteudo -replace "^#\s*impressora\.modelo=epson", "impressora.modelo=epson"

        # Configura o endereco da impressora
        $conteudo = $conteudo -replace "^#\s*impressora\.endereco=.*ENDERECO_IP_MAQUINA.*", "impressora.endereco=\\\\${ipImpressora}\\${compImpressora}"

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
# 7. CRIANDO ATALHOS NA AREA DE TRABALHO
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Criando atalhos na Area de Trabalho..." -ForegroundColor Yellow

$desktop = [Environment]::GetFolderPath("Desktop")
$pastaIcones = "C:\ProgramData\A7Pharma\Icones"

New-Item -ItemType Directory -Force -Path $pastaIcones | Out-Null
Add-Type -AssemblyName System.Drawing

# Converte PNG para ICO no tamanho padrao 48x48
function Convert-PngToIco {
    param (
        [string]$OrigemPng,
        [string]$DestinoIco
    )

    $imagemOriginal = [System.Drawing.Image]::FromFile($OrigemPng)
    $imagemRedimensionada = New-Object System.Drawing.Bitmap -ArgumentList 48, 48
    $grafico = [System.Drawing.Graphics]::FromImage($imagemRedimensionada)

    $grafico.Clear([System.Drawing.Color]::Transparent)
    $grafico.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $grafico.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $grafico.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $grafico.DrawImage($imagemOriginal, 0, 0, 48, 48)

    $icone = [System.Drawing.Icon]::FromHandle($imagemRedimensionada.GetHicon())
    $arquivoIcone = [System.IO.File]::Open($DestinoIco, [System.IO.FileMode]::Create)

    $icone.Save($arquivoIcone)

    $arquivoIcone.Close()
    $arquivoIcone.Dispose()
    $icone.Dispose()
    $grafico.Dispose()
    $imagemRedimensionada.Dispose()
    $imagemOriginal.Dispose()
}

$suportePng = "$pastaIcones\Suporte.png"
$suporteIco = "$pastaIcones\Suporte_48.ico"

$kbPng = "$pastaIcones\BaseConhecimento.png"
$kbIco = "$pastaIcones\BaseConhecimento_48.ico"

$aprendaIco = "$pastaIcones\Aprenda7.ico"

# Baixa os icones oficiais
$iconClient = New-Object System.Net.WebClient

$iconClient.DownloadFile(
    "https://chat.a7.net.br/assets/img/logo_alpha7.png",
    $suportePng
)

# O KB utiliza a mesma identidade visual do Alpha7.
# A copia local evita bloqueios no download direto do site do KB.
Copy-Item -Path $suportePng -Destination $kbPng -Force

$iconClient.DownloadFile(
    "https://aprenda.a7.net.br/pluginfile.php/1/theme_moove/favicon/1783685431/Favicon.ico",
    $aprendaIco
)

$iconClient.Dispose()

# Converte os PNGs de 1024x1024 para ICO 48x48
Convert-PngToIco -OrigemPng $suportePng -DestinoIco $suporteIco
Convert-PngToIco -OrigemPng $kbPng -DestinoIco $kbIco

# Os arquivos PNG nao sao mais necessarios
Remove-Item $suportePng -Force
Remove-Item $kbPng -Force

$atalhos = @(
    @{
        Nome = "Alpha7 Suporte"
        Url = "https://chat.a7.net.br/"
        Icone = $suporteIco
    },
    @{
        Nome = "Base de Conhecimento"
        Url = "https://kb.a7.net.br/P%C3%A1gina_principal"
        Icone = $kbIco
    },
    @{
        Nome = "Aprenda7"
        Url = "https://aprenda.a7.net.br/login/index.php"
        Icone = $aprendaIco
    }
)

foreach ($atalho in $atalhos) {
    $caminhoAtalho = "$desktop\$($atalho.Nome).url"

    # Remove o atalho antigo para evitar o cache anterior
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

# Limpa e atualiza o cache de icones do Windows
Start-Process `
    -FilePath "$env:SystemRoot\System32\ie4uinit.exe" `
    -ArgumentList "-ClearIconCache" `
    -WindowStyle Hidden `
    -Wait `
    -ErrorAction SilentlyContinue

Start-Process `
    -FilePath "$env:SystemRoot\System32\ie4uinit.exe" `
    -ArgumentList "-show" `
    -WindowStyle Hidden `
    -ErrorAction SilentlyContinue

# ----------------------------------------------------------------
# 8. LIMPEZA DOS ARQUIVOS TEMPORARIOS
# ----------------------------------------------------------------
Write-Host ""
Write-Host "=> Finalizando e limpando arquivos temporarios..." -ForegroundColor Gray

Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "     [OK] TODOS OS PROGRAMAS FORAM INSTALADOS!    " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
