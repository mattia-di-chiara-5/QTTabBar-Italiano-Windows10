#requires -version 5.1
param([Parameter(Mandatory=$true)][string]$PackageDirectory)
$ErrorActionPreference = 'Stop'
$msi = Join-Path $PackageDirectory 'QTTabBar-Italiano-v0.7.1.msi'
$hash = (Get-FileHash $msi).Hash
$script = Get-Content (Join-Path $PackageDirectory 'Installa-Stabilita.ps1') -Raw
if (!$script.Contains($hash) -or $script.Contains('__DLL_SHA256__') -or $script.Contains('__MSI_SHA256__')) { throw 'Installer hash stamping failed.' }
if ((Get-FileHash (Join-Path $PackageDirectory 'Rollback\QTTabBar-Italiano-v0.6.0.msi')).Hash -ne '7773086005FF2675E4994C895C7A828EC20966D83A0268C9AD61EE11DC837767') { throw 'Rollback MSI mismatch.' }
$installer = New-Object -ComObject WindowsInstaller.Installer
. (Join-Path $PackageDirectory 'MigrationTargets.ps1')
foreach ($product in @('{540B7E57-F7A0-4AA5-A362-736892574234}','{F70E079A-2E71-4B23-B8F2-854D700B7DAF}','{3EB8D8B3-A96E-49B0-824A-707E6CF60273}')) {
    $previous = Get-PreviousQtRelease $product
    $previousMsi = Join-Path $PackageDirectory ('Rollback\QTTabBar-Italiano-v'+$previous.Version+'.msi')
    if ((Get-FileHash $previousMsi).Hash -ne $previous.MsiHash) { throw 'Previous MSI hash mismatch.' }
    $previousDb = $installer.OpenDatabase((Resolve-Path $previousMsi).Path,0)
    $view = $previousDb.OpenView('SELECT `Value` FROM `Property` WHERE `Property`=''ProductCode''')
    $record = $null
    try {
        [void]$view.Execute(); $record=$view.Fetch()
        if ($record.StringData(1) -ne $previous.ProductCode) { throw 'Rollback selects the wrong installed product.' }
    } finally {
        if ($record) { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($record) }
        [void]$view.Close(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($view)
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($previousDb)
    }
}
$rejected=$false
try { Get-PreviousQtRelease '{00000000-0000-0000-0000-000000000000}' } catch { $rejected=$true }
if (!$rejected) { throw 'Unknown installed products must be rejected.' }
Write-Host 'PASS: all three migration targets map to exact released MSI hashes and product identities; unknown products rejected'
$db = $installer.OpenDatabase((Resolve-Path $msi).Path,0)
function Query([string]$Sql, [int]$ColumnCount = 1) {
    $view = $db.OpenView($Sql)
    try {
        [void]$view.Execute()
        while ($null -ne ($record = $view.Fetch())) {
            try { $values = @(); for ($i=1; $i -le $ColumnCount; $i++) { $values += $record.StringData($i) }; ,$values }
            finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($record) }
        }
    } finally { [void]$view.Close(); [void][Runtime.InteropServices.Marshal]::ReleaseComObject($view) }
}
try {
    $upgrades = @(Query 'SELECT `UpgradeCode`, `VersionMin`, `VersionMax`, `Language`, `Attributes` FROM `Upgrade`' 5)
    $migration = @($upgrades | Where-Object { $_[0] -eq '{EC9BAFF7-58FB-40CB-9F67-1C438A7524A5}' -and $_[2] -eq '1.6.8' -and !$_[3] -and (([int]$_[4] -band 2) -eq 0) })
    if ($migration.Count -ne 1) { throw 'Major upgrade must include the old English-language MSI.' }
    $tables = @(Query 'SELECT `Name` FROM `_Tables`' | ForEach-Object { $_[0] })
    $actions = @()
    if ($tables -contains 'CustomAction') { $actions = @(Query 'SELECT `Action` FROM `CustomAction`') }
    if (@($actions | Where-Object { $_[0] -match 'KillExplorer|StartExplorer|WaitAfterKill' }).Count) { throw 'MSI must not restart Explorer.' }
    $removals = @()
    if ($tables -contains 'RemoveRegistry') { $removals = @(Query 'SELECT `Key` FROM `RemoveRegistry`') }
    $removals += @(Query 'SELECT `Key` FROM `Registry` WHERE `Name`=''-'' OR `Name`=''*''')
    if (@($removals | Where-Object { $_[0] -eq 'Software\Microsoft\Internet Explorer\Toolbar' }).Count) { throw 'MSI deletes the shared Toolbar key.' }
    $assembly = @(Query 'SELECT `Value` FROM `Registry` WHERE `Name`=''Assembly''')
    if (@($assembly | Where-Object { $_[0] -ne 'QTTabBar, Version=1.6.3.0, Culture=neutral, PublicKeyToken=973461f1cd23d8eb' }).Count) { throw 'COM assembly identity mismatch.' }
    Write-Host 'PASS: package hashes, upgrade across installer languages, COM identity, shared registry preservation, no MSI Explorer restart'
} finally {
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($db)
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($installer)
}
