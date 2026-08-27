# QTTabBar Italiano v0.4.0

Prima release con la lingua italiana integrata nella DLL di QTTabBar 1.5.6.1.

## Novità

- italiano built-in, senza file XML esterno;
- selezione automatica su Windows con interfaccia it-IT;
- migrazione reversibile dalle impostazioni v0.3 con UseLangFile attivo;
- installazione controllata con verifica SHA-256;
- copia protetta di DLL e MSI prima dell'uso con privilegi amministrativi;
- stato di rollback scrivibile solo da Administrators e SYSTEM;
- blocco delle esecuzioni simultanee di installazione/ripristino;
- backup della DLL GAC e della configurazione lingua;
- rollback automatico in caso di errore e comando di ripristino manuale.

## Compatibilità

- Windows 10 x64;
- QTTabBar 1.5.6.x;
- baseline sorgente upstream: 44a83bef8cdf5fb67c6d7f6434821c6f602542e7.

## Hash della RC1

QTTabBar.dll:

77F1351E8672FD5C8EBDC49C9A28E4D66EA267BC7FF8B2BF872AADD62EBA7B36

Verificare anche SHA256SUMS.txt incluso nell'asset ZIP.

## Sicurezza e firma

L'installer non scarica file e non esegue codice dalla rete. Accetta solo la
DLL e l'MSI con gli hash fissati nel sorgente, limita il riavvio di Explorer
alla sessione corrente e convalida anche i backup usati dal rollback.

La DLL è strong-name valida, ma questa release comunitaria non dispone di un
certificato Authenticode commerciale. Windows può quindi mostrare un avviso:
verificare sempre lo SHA-256 dell'asset pubblicato prima dell'installazione.

## Installazione

1. Estrarre completamente lo ZIP.
2. Eseguire INSTALLA_QTTABBAR_ITALIANO.cmd.
3. Accettare la richiesta UAC.
4. Aprire Esplora file e verificare QTTabBar in italiano.

Per tornare alla DLL e alle impostazioni precedenti eseguire
RIPRISTINA_QTTABBAR_ORIGINALE.cmd.
