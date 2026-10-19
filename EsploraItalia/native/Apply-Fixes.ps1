#requires -version 5.1
param([Parameter(Mandatory=$true)][string]$SourceDirectory)
$ErrorActionPreference='Stop'
$baseline=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'base.lock.json') -Raw|ConvertFrom-Json
function Read-PinnedText($relative,$expected){
 $path=Join-Path $SourceDirectory $relative
 $text=[IO.File]::ReadAllText($path).Replace("`r`n","`n")
 $digest=[Security.Cryptography.SHA256]::Create()
 try{$actual=[BitConverter]::ToString($digest.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).Replace('-','')}finally{$digest.Dispose()}
 if($actual -ne $expected){throw ('Sorgente non previsto: '+$relative)}
 return $text
}
$path=Join-Path $SourceDirectory 'Explorer++\Explorer++\ComStaThreadPoolExecutor.cpp'
$text=Read-PinnedText 'Explorer++\Explorer++\ComStaThreadPoolExecutor.cpp' $baseline.ExecutorOriginalNormalizedSHA256
$start=$text.IndexOf('ComStaThreadPoolExecutor::ComStaThreadPoolExecutor(int numThreads)')
$end=$text.IndexOf('void ComStaThreadPoolExecutor::enqueue',$start)
if($start -lt 0 -or $end -lt 0){throw 'Costruttore non trovato.'}
$constructor=@"
ComStaThreadPoolExecutor::ComStaThreadPoolExecutor(int numThreads) :
`tconcurrencpp::derivable_executor<ComStaThreadPoolExecutor>("ComStaThreadPoolExecutor")
{
`t// Publish valid wait handles before any worker can enter WaitForWork().
`tm_taskQueuedEvent.create(wil::EventOptions::None);
`tm_shutDownEvent.create(wil::EventOptions::ManualReset);

`tfor (int i = 0; i < numThreads; i++)
`t{
`t`tauto thread = std::jthread(&ComStaThreadPoolExecutor::ThreadMain, this);
`t`tm_threads.push_back(std::move(thread));
`t}
}

"@
$text=$text.Substring(0,$start)+$constructor.Replace("`r`n","`n")+"`n"+$text.Substring($end)
$wait='MsgWaitForMultipleObjectsEx(std::size(handles), handles, INFINITE, QS_ALLINPUT, 0);'
if(@([regex]::Matches($text,[regex]::Escape($wait))).Count -ne 1){throw 'Attesa nativa non trovata univocamente.'}
$text=$text.Replace($wait,('auto result = '+$wait+"`n`tFAIL_FAST_LAST_ERROR_IF(result == WAIT_FAILED);"))
[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false))
$path=Join-Path $SourceDirectory 'Explorer++\TestExplorer++\ComStaThreadPoolExecutorTest.cpp'
$text=Read-PinnedText 'Explorer++\TestExplorer++\ComStaThreadPoolExecutorTest.cpp' $baseline.TestOriginalNormalizedSHA256
$extra=@"

TEST_F(ComStaThreadPoolExecutorTest, RepeatedConstructionRunsTasksAndStops)
{
`tfor (int attempt = 0; attempt < 64; attempt++)
`t{
`t`tauto executor = std::make_shared<ComStaThreadPoolExecutor>(2);
`t`tbool ran = false;
`t`tRunTaskOnExecutorForTest(executor, [&ran] { ran = true; });
`t`tEXPECT_TRUE(ran);
`t`texecutor->shutdown();
`t`tEXPECT_TRUE(executor->shutdown_requested());
`t}
}
"@
[IO.File]::WriteAllText($path,$text+$extra.Replace("`r`n","`n"),[Text.UTF8Encoding]::new($false))
Write-Output 'Correzione avvio pool COM e controllo WAIT_FAILED applicati; aggiunto stress test di costruzione/uscita.'