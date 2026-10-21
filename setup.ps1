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
