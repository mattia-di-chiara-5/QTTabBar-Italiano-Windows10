# QTTabBar Italiano — Windows 10 Edition 0.6.0

Edizione italiana basata sui sorgenti upstream **QTTabBar 1.6.3** (tag `v1.6.3`, commit `8e5434b`). La 0.6.0 corregge il lavoro ripetuto sul percorso mouse/disegno di Explorer. Resta una release preliminare: i test non garantiscono la risoluzione di ogni rallentamento.

## Correzioni

- Cache degli elementi aggiornata in modo asincrono, senza attendere il provider UI Automation durante il passaggio del mouse.
- Un solo lavoro in corso, richieste accorpate ogni 33 ms e risultati superati ignorati.
- Client COM creato e usato sul medesimo thread MTA.
- Percorsi UNC e unita di rete rifiutati prima dei controlli sincroni dei menu delle sottocartelle.
- Protezioni per geometrie incomplete e conteggi di pagina nulli.
- Microsoft System.Text.Encoding.CodePages aggiornato a 10.0.12 e incorporato nella DLL.
- Mantenute le correzioni 0.5.0: icone separate per thread STA e pennelli delle schede riutilizzati.

La ricerca nei fork, i confronti e i limiti sono descritti nell'[audit](Italiano/docs/AUDIT_PRESTAZIONI_0.6.0.md). Alcune operazioni esplicite mantengono chiamate UI Automation sincrone.

## Installazione

Richiesti Windows 10 x64 e .NET Framework 4.8. Scaricare dalla [release italiana](https://github.com/mattia-di-chiara-5/QTTabBar-Italiano-Windows10/releases) `QTTabBar-Italiano-Windows10-v0.6.0.zip`, estrarre e avviare **INSTALLA_STABILITA.cmd**. Accettare l'elevazione UAC. Terminare prima copie ed estrazioni: l'aggiornamento riavvia Esplora file nella sessione corrente. Riavviare Windows se richiesto.

Migrazione automatica dalla **0.5.0 verificata** oppure nuova installazione. Le versioni precedenti devono prima passare alla 0.5.0. Versioni/DLL sconosciute vengono rifiutate. L'italiano integrato viene selezionato automaticamente. Se necessario, abilitare la barra da Visualizza > Opzioni > QTTabBar.

Il profilo rapido predefinito mostra anteprime e menu delle sottocartelle tenendo premuto **Maiusc (Shift)**. Per conservare le impostazioni delle anteprime automatiche, eseguire invece da PowerShell `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Installa-Stabilita.ps1 -MantieniAnteprimeAutomatiche`. Le opzioni rimangono modificabili nella configurazione di QTTabBar.

Versione dell'edizione **0.6.0**, base **1.6.3**, versione file **1.6.3.6**. L'identita COM resta `1.6.3.0`; la versione interna MSI `1.6.5` serve all'aggiornamento e non indica una nuova base upstream.

## Ripristino

Avviare **RIPRISTINA_VERSIONE_PRECEDENTE.cmd** con lo stesso account Windows. Rimuove la 0.6.0 e reinstalla la 0.5.0 verificata, se presente prima, ripristinando la configurazione salvata. Backup protetti in `%ProgramData%\QTTabBar-Italiano\v0.6.0`. I precedenti backup della 0.5.0 restano disponibili separatamente. Non pubblicare backup o log personali.

## Compilazione e verifica

Usare Visual Studio Build Tools/MSBuild, targeting pack .NET 4.8, SDK Windows, NuGet e WiX 3.14.1. Il workflow `italiano-stability.yml` documenta ripristino pacchetti, build, test e creazione del pacchetto. Eseguire `Italiano/tests/Run-Regression.ps1`, quindi `Italiano/scripts/Build-StabilityPackage.ps1` e `Italiano/tests/Test-OfflinePackage.ps1`.

Input fissati tramite SHA-256: installer ufficiale 1.6.3 `2F91AD5B04DE7518C9BDE708768E88BE4EBF8EB92AA3649B1FEED1B3DF239FDF`; MSI di ripristino 0.5.0 `675C49C0681304CC537D3626AF5794BAA035610DA321A8CC9934A2A67332522E`.

Test: icone su quattro thread STA, 2.000 ridisegni, risorse italiane, dipendenze incorporate, 10.000 richieste accorpate, provider lento e percorso UNC irraggiungibile. L'isolamento DEVPATH/developmentMode riguarda soltanto i processi di test; non modifica Explorer o il sistema. Il pacchetto non ha firma Authenticode; la DLL conserva lo strong name del progetto.

Licenza GNU GPL v3: vedere LICENSE.txt. Crediti a Quizo, Paul Accisano, indiff e ai contributori upstream; localizzazione italiana dall'edizione 0.4.0.