#requires -version 5.1
param([Parameter(Mandatory=$true)][string]$PackageDirectory)
$ErrorActionPreference = 'Stop'
$msi = Join-Path $PackageDirectory 'QTTabBar-Italiano-v0.5.0.msi'
$hash = (Get-FileHash $msi).Hash
$script = Get-Content (Join-Path $PackageDirectory 'Installa-Stabilita.ps1') -Raw
if (!$script.Contains($hash) -or $script.Contains('__DLL_SHA256__') -or $script.Contains('__MSI_SHA256__')) { throw 'Installer hash stamping failed.' }
if ((Get-FileHash (Join-Path $PackageDirectory 'Rollback\QTTabBar-1.5.6.1.msi')).Hash -ne 'AAE4F2BEC2F4CA0EDE488638B9F31543B7CFCBFC90F1C6DDB74F5FB47B890287') { throw 'Rollback MSI mismatch.' }
$installer = New-Object -ComObject WindowsInstaller.Installer
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
    $migration = @($upgrades | Where-Object { $_[0] -eq '{EC9BAFF7-58FB-40CB-9F67-1C438A7524A5}' -and $_[2] -eq '1.6.4' -and !$_[3] -and (([int]$_[4] -band 2) -eq 0) })
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
