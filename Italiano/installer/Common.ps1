#requires -version 5.1
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:QtExpectedCandidateHash = '77F1351E8672FD5C8EBDC49C9A28E4D66EA267BC7FF8B2BF872AADD62EBA7B36'
$script:QtExpectedBaselineHash = 'CB11DC758CF1E52107281CDBB8A645F68541046B21BF789E2CE9B291212F0A54'
$script:QtExpectedMsiHash = 'AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287'

function Write-Section {
    param([Parameter(Mandatory=$true)][string]$Text)
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor DarkCyan
}

function Get-SafePropertyValue {
    param(
        [Parameter(Mandatory=$true)]$InputObject,
        [Parameter(Mandatory=$true)][string]$Name,
        $Default = $null
    )
    if ($null -eq $InputObject) { return $Default }
    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return $Default }
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
        foreach ($item in @(Get-ItemProperty -Path $path -ErrorAction SilentlyContinue)) {
            $name = [string](Get-SafePropertyValue -InputObject $item -Name 'DisplayName' -Default '')
            if ($name -match '(?i)QTTabBar') { Write-Output $item }
        }
    }
}

function Get-QTTabBarGacFiles {
    $roots = @(
        "$env:WINDIR\assembly\GAC_MSIL\QTTabBar",
        "$env:WINDIR\assembly\GAC_32\QTTabBar",
        "$env:WINDIR\assembly\GAC_64\QTTabBar",
        "$env:WINDIR\Microsoft.NET\assembly\GAC_MSIL\QTTabBar",
        "$env:WINDIR\Microsoft.NET\assembly\GAC_32\QTTabBar",
        "$env:WINDIR\Microsoft.NET\assembly\GAC_64\QTTabBar"
    )
    foreach ($root in $roots) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -LiteralPath $root -Filter 'QTTabBar.dll' -File -Recurse -ErrorAction SilentlyContinue
        }
    }
}

function Get-QTTabBarGacFile {
    $files = @(Get-QTTabBarGacFiles | Sort-Object FullName -Unique)
    if ($files.Count -ne 1) {
        throw "Attesa una sola QTTabBar.dll nella GAC; rilevate $($files.Count)."
    }
    return $files[0]
}

function Get-FileRecord {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File non trovato: $Path"
    }
    $item = Get-Item -LiteralPath $Path
    return [pscustomobject]@{
        Path = $item.FullName
        Bytes = $item.Length
        SHA256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
        FileVersion = $item.VersionInfo.FileVersion
        ProductVersion = $item.VersionInfo.ProductVersion
    }
}

function Install-GacAssembly {
    param([Parameter(Mandatory=$true)][string]$Path)
    Add-Type -AssemblyName System.EnterpriseServices
    $publisher = New-Object System.EnterpriseServices.Internal.Publish
    $publisher.GacInstall((Resolve-Path -LiteralPath $Path).Path)
}

function Enter-QTTabBarMaintenance {
    $mutex = New-Object System.Threading.Mutex($false,'Global\QTTabBarItaliano_v0_4_0')
    try {
        try {
            $acquired = $mutex.WaitOne(0,$false)
        }
        catch [System.Threading.AbandonedMutexException] {
            $acquired = $true
        }
        if (-not $acquired) {
            throw "È già in corso una installazione o un ripristino di QTTabBar Italiano."
        }
        return $mutex
    }
    catch {
        $mutex.Dispose()
        throw
    }
}

function Exit-QTTabBarMaintenance {
    param([System.Threading.Mutex]$Mutex)
    if ($null -eq $Mutex) { return }
    try { $Mutex.ReleaseMutex() } catch {}
    $Mutex.Dispose()
}

function Protect-AdministratorDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)
    $item = Get-Item -LiteralPath $Path
    if (-not $item.PSIsContainer) { throw "Non è una directory: $Path" }
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "La directory protetta non può essere un collegamento: $Path"
    }

    $inheritance = [Security.AccessControl.InheritanceFlags]'ContainerInherit,ObjectInherit'
    $propagation = [Security.AccessControl.PropagationFlags]::None
    $allow = [Security.AccessControl.AccessControlType]::Allow
    $fullControl = [Security.AccessControl.FileSystemRights]::FullControl
    $acl = New-Object Security.AccessControl.DirectorySecurity
    $acl.SetAccessRuleProtection($true,$false)
    $administrators = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $system = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
    $acl.SetOwner($administrators)
    [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($administrators,$fullControl,$inheritance,$propagation,$allow)))
    [void]$acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($system,$fullControl,$inheritance,$propagation,$allow)))
    Set-Acl -LiteralPath $item.FullName -AclObject $acl
}

function Test-AdministratorDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)
    $item = Get-Item -LiteralPath $Path
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        return $false
    }
    $allowed = @('S-1-5-18','S-1-5-32-544')
    foreach ($rule in (Get-Acl -LiteralPath $item.FullName).Access) {
        $sid = $rule.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value
        if ($rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow -and
            $sid -notin $allowed) {
            return $false
        }
    }
    return $true
}

function Test-LanguageRegistryBackup {
    param([Parameter(Mandatory=$true)][string]$Path)
    $headers = @(Get-Content -LiteralPath $Path | Where-Object { $_ -match '^\[.*\]$' })
    return ($headers.Count -eq 1 -and
        $headers[0] -ceq '[HKEY_CURRENT_USER\Software\QTTabBar\Config\Lang]')
}

function Export-RegistryKey {
    param(
        [Parameter(Mandatory=$true)][string]$NativePath,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    $quotedDestination = '"{0}"' -f $Destination
    $process = Start-Process -FilePath (Join-Path $env:WINDIR 'System32\reg.exe') -ArgumentList @('export',$NativePath,$quotedDestination,'/y') -Wait -PassThru -WindowStyle Hidden
    return ($process.ExitCode -eq 0 -and (Test-Path -LiteralPath $Destination))
}

function Restore-LanguageRegistry {
    param(
        [Parameter(Mandatory=$true)][bool]$Existed,
        [string]$BackupFile
    )
    $key = 'HKCU:\Software\QTTabBar\Config\Lang'
    if (Test-Path -LiteralPath $key) {
        Remove-Item -LiteralPath $key -Recurse -Force
    }
    if ($Existed) {
        if ([string]::IsNullOrWhiteSpace($BackupFile) -or -not (Test-Path -LiteralPath $BackupFile)) {
            throw 'Il backup della configurazione lingua è assente.'
        }
        $quotedBackup = '"{0}"' -f $BackupFile
        $process = Start-Process -FilePath (Join-Path $env:WINDIR 'System32\reg.exe') -ArgumentList @('import',$quotedBackup) -Wait -PassThru -WindowStyle Hidden
        if ($process.ExitCode -ne 0) {
            throw "Ripristino registro non riuscito. Codice $($process.ExitCode)."
        }
    }
}

function Set-BuiltInItalian {
    $key = 'HKCU:\Software\QTTabBar\Config\Lang'
    New-Item -Path $key -Force | Out-Null
    New-ItemProperty -LiteralPath $key -Name 'UseLangFile' -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -LiteralPath $key -Name 'LangFile' -Value '' -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $key -Name 'BuiltInLang' -Value 'Italiano' -PropertyType String -Force | Out-Null
    New-ItemProperty -LiteralPath $key -Name 'BuiltInLangSelectedIndex' -Value 8 -PropertyType DWord -Force | Out-Null
}

function Restart-ExplorerSafely {
    $currentSession = (Get-Process -Id $PID).SessionId
    Get-Process explorer -ErrorAction SilentlyContinue |
        Where-Object { $_.SessionId -eq $currentSession } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $sessionExplorer = @(Get-Process explorer -ErrorAction SilentlyContinue |
        Where-Object { $_.SessionId -eq $currentSession })
    if ($sessionExplorer.Count -eq 0) {
        Start-Process (Join-Path $env:WINDIR 'explorer.exe') | Out-Null
    }
    Start-Sleep -Seconds 5
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Text
    )
    [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($false)))
}
