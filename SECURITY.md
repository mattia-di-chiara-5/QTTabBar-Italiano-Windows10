# Sicurezza

## Ambito supportato

La release italiana it-v0.4.0 è validata solo su Windows 10 x64 con QTTabBar
1.5.6.x. Su Windows 11 o con altre versioni l'installer interrompe
l'operazione senza sostituire la DLL.

## Garanzie dell'installer

- nessun download o accesso di rete;
- hash SHA-256 obbligatorio per DLL e MSI;
- staging in una directory amministrativa prima dell'installazione;
- backup della DLL GAC e della sola configurazione lingua;
- stato scrivibile soltanto da Administrators e SYSTEM;
- rollback vincolato alla baseline prevista;
- rollback automatico se l'installazione non termina correttamente;
- riavvio del solo Explorer della sessione corrente.

La DLL è strong-name valida, ma non è firmata Authenticode. Verificare l'hash
dell'asset indicato nella GitHub Release e il file SHA256SUMS.txt contenuto
nello ZIP.

## Segnalazioni

Per un problema di sicurezza, non pubblicare dati personali, backup o file di
registro. Aprire una segnalazione nel repository descrivendo versione di
Windows, versione QTTabBar, fase interessata e messaggio d'errore; per dettagli
sensibili usare una GitHub Security Advisory privata, se disponibile.
