# Audit delle prestazioni 0.6.0

## Ricerca upstream

Ricerca pubblica dell'11 ottobre 2026: inventario di 334 fork distinti della rete GitHub di indiff/qttabbar e 27 repository indipendenti con QTTabBar nel nome. L'inventario individua i rami pertinenti; non equivale a una revisione di ogni riga di tutti i fork.

Confrontati i rami pertinenti e le segnalazioni pubbliche:

- [indiff/qttabbar](https://github.com/indiff/qttabbar), master `9b81f72`, e tag v1.6.3 `8e5434b`;
- [niklas2233/qttabbar](https://github.com/niklas2233/qttabbar), `9042e94`;
- [JNylson/qttabbar](https://github.com/JNylson/qttabbar), `8be8056`;
- [akaydev-coder/qttabbar_native_enhanced](https://github.com/akaydev-coder/qttabbar_native_enhanced), `40b5ca0`;
- [kingpeter2015/QTTabBar](https://github.com/kingpeter2015/QTTabBar), `b446973`.

Native Enhanced mantiene chiamate sincrone a DoQuery/Dispatcher.Invoke nel percorso di aggiornamento della cache. Il numero di versione e le nuove funzioni grafiche non dimostrano una riduzione degli scatti. Master upstream e tag di release divergono: nessun merge indiscriminato. La [segnalazione #437](https://github.com/indiff/qttabbar/issues/437) riguarda il ritardo di Win+E, sintomo diverso dagli scatti durante selezione e scorrimento.

## Correzioni implementate

Il percorso mouse/disegno aggiornava la cache aspettando UI Automation sul thread di Explorer. La cache viene ora interrogata su un worker MTA, con completamento sul thread proprietario. Timer da 33 ms, un solo lavoro in corso e scarto dei risultati superati limitano le richieste. Il client COM viene creato sul worker che lo usa.

I menu automatici delle sottocartelle rifiutano percorsi UNC e unita di rete prima di Directory.Exists. Corrette geometrie incomplete e divisioni per zero nel conteggio delle pagine. Il profilo rapido richiede Maiusc per anteprime e menu delle sottocartelle. Le funzioni esplicite che richiedono una risposta immediata mantengono alcuni percorsi legacy DoQuery: non tutto il software e stato convertito ad asincrono.

System.Text.Encoding.CodePages passa da 4.7.1 a 10.0.12; le altre cinque dipendenze incorporate risultavano gia alla versione stabile piu recente controllata. Nessuna voce pertinente ai sei ID nel database NuGet delle vulnerabilita consultato: questo non garantisce assenza di vulnerabilita sconosciute.

## Verifiche e limiti

Test: 10.000 richieste diventano due lavori, risultati superati/disposti ignorati; provider artificiale da 250 ms con richiesta che ritorna senza aspettarlo, messaggi UI elaborati e appartamenti MTA/STA corretti; percorso UNC irraggiungibile rifiutato prima dell'accesso. Restano i controlli di icone su quattro thread STA, 2.000 ridisegni e risorse/dipendenze incorporate. DEVPATH e developmentMode sono usati soltanto dai processi di test isolati, senza cambiare Explorer o il sistema.

Prima delle correzioni, 150 selezioni COM su una cartella locale di 500 file hanno dato media 45 ms e massimo 130 ms. Una prova barra visibile/nascosta in ordine ABBA ha dato medie 45,7 / 34,8 / 39,2 / 32,0 ms: non basta ad attribuire il rallentamento alla barra. Nascondere la barra non scarica necessariamente la sua DLL.

Le tracce ETW includono Explorer, QTTabBar e altre estensioni. Il costo inclusivo di NativeWindowController.WndProc comprende anche il codice nativo di Explorer e non misura il costo esclusivo di QTTabBar. Tracce e dati personali restano fuori dal repository.

Il test con provider lento dimostra il comportamento del percorso corretto, non un guadagno universale nell'uso reale. La release resta preliminare finche il comportamento sul PC, sulle cartelle di rete e durante estrazioni ZIP non viene osservato a sufficienza.
