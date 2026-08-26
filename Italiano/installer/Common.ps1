#requires -version 5.1
Set-StrictMode -Version 2.0

function Write-Section {
    param([Parameter(Mandatory=$true)][string]$Text)
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor DarkCyan
}

function Get-SafePropertyValue {
    param(
        [Parameter(Mandatory=$true)][object]$InputObject,
        [Parameter(Mandatory=$true)][string]$Name
    )
    if ($null -eq $InputObject) { return $null }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-QTTabBarEntries {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($path in $paths) {
        $items = @(Get-ItemProperty -Path $path -ErrorAction SilentlyContinue)
        foreach ($item in $items) {
            $name = [string](Get-SafePropertyValue -InputObject $item -Name 'DisplayName')
            if (-not [string]::IsNullOrWhiteSpace($name) -and $name -match 'QTTabBar') {
                Write-Output $item
            }
        }
    }
}

function Test-MsiCompoundFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $buffer = New-Object byte[] 8
        if ($stream.Read($buffer, 0, 8) -ne 8) { return $false }
        $expected = [byte[]](0xD0,0xCF,0x11,0xE0,0xA1,0xB1,0x1A,0xE1)
        for ($i = 0; $i -lt 8; $i++) {
            if ($buffer[$i] -ne $expected[$i]) { return $false }
        }
        return $true
    }
    finally {
        $stream.Dispose()
    }
}

function Get-MsiProperty {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$PropertyName
    )
    $installer = $null
    $database = $null
    $view = $null
    $record = $null
    try {
        $installer = New-Object -ComObject WindowsInstaller.Installer
        $database = $installer.OpenDatabase($Path, 0)
        $query = "SELECT ``Value`` FROM ``Property`` WHERE ``Property``='$PropertyName'"
        $view = $database.OpenView($query)
        $view.Execute()
        $record = $view.Fetch()
        if ($null -ne $record) { return [string]$record.StringData(1) }
    }
    catch {
        return $null
    }
    finally {
        if ($null -ne $record) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($record) }
        if ($null -ne $view) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($view) }
        if ($null -ne $database) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($database) }
        if ($null -ne $installer) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($installer) }
    }
    return $null
}

function Test-QTLanguageFile {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File lingua non trovato: $Path"
    }

    $document = New-Object System.Xml.XmlDocument
    $document.PreserveWhitespace = $true
    try {
        $document.Load($Path)
    }
    catch {
        throw "XML non leggibile: $($_.Exception.Message)"
    }

    if ($null -eq $document.DocumentElement -or $document.DocumentElement.Name -ne 'root') {
        throw 'Elemento radice XML non valido: deve essere <root>.'
    }

    $languageNode = $document.SelectSingleNode('/root/Language')
    if ($null -eq $languageNode) {
        throw 'Nodo /root/Language assente.'
    }

    $languageCode = [string]$languageNode.InnerText
    if ($languageCode.Trim() -ne 'it_IT') {
        throw "Codice lingua non valido: '$($languageCode.Trim())'."
    }

    $requiredCounts = @{
        'ButtonBar_BtnName' = 22
        'DialogButtons' = 16
        'Options_Page13_Language' = 12
        'ShortcutKeys_ActionNames' = 80
        'TabBar_Menu' = 36
        'TabBar_Option_Genre' = 14
        'UpdateCheck' = 8
    }

    foreach ($tag in $requiredCounts.Keys) {
        $node = $document.SelectSingleNode("/root/$tag")
        if ($null -eq $node) {
            throw "Sezione lingua obbligatoria assente: $tag"
        }
        $lines = @($node.InnerText -split "(`r`n|`n|`r)" | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        })
        if ($lines.Count -ne $requiredCounts[$tag]) {
            throw "Numero di voci non valido in $tag. Attese $($requiredCounts[$tag]), rilevate $($lines.Count)."
        }
    }

    return [pscustomobject]@{
        Language = $languageCode.Trim()
        Sections = $document.DocumentElement.ChildNodes.Count
        SHA256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
}

function Copy-ItalianLanguageFile {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [switch]$OpenFolder
    )

    $validation = Test-QTLanguageFile -Path $Source
    $targetDirectory = Join-Path $env:LOCALAPPDATA 'QTTabBar-Italiano\I18N'
    $target = Join-Path $targetDirectory 'Lng_QTTabBar_it_IT.xml'

    New-Item -Path $targetDirectory -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $target -Force

    $copiedHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if ($copiedHash -cne $validation.SHA256) {
        throw 'La copia del file lingua non supera il controllo SHA-256.'
    }

    # Remove only the unsupported helper values created by package versions 0.2.x.
    $obsoleteHelperKey = 'HKCU:\Software\QTTabBar\Config\Lang'
    if (Test-Path -LiteralPath $obsoleteHelperKey) {
        Remove-ItemProperty -LiteralPath $obsoleteHelperKey -Name 'UseLangFile' -ErrorAction SilentlyContinue
        Remove-ItemProperty -LiteralPath $obsoleteHelperKey -Name 'LangFile' -ErrorAction SilentlyContinue
    }

    $metadataKey = 'HKCU:\Software\QTTabBar-Italiano'
    New-Item -Path $metadataKey -Force | Out-Null
    New-ItemProperty -Path $metadataKey -Name 'LanguageFilePath' -Value $target -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $metadataKey -Name 'PackageVersion' -Value '0.3.0' -PropertyType String -Force | Out-Null

    try {
        Set-Clipboard -Value $target
    }
    catch {
        $target | clip.exe
    }

    if ($OpenFolder) {
        Start-Process explorer.exe -ArgumentList "/select,`"$target`""
    }

    return [pscustomobject]@{
        Target = $target
        SHA256 = $copiedHash
        Sections = $validation.Sections
    }
}

function Restart-ExplorerSafely {
    Get-Process explorer -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
        Start-Process (Join-Path $env:WINDIR 'explorer.exe')
    }
}
