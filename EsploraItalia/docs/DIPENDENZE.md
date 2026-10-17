# Dipendenze dichiarate dal sorgente selezionato

Rilevazione del 17 ottobre 2026. Commit Explorer++ `adf72c76b883271427ba16c39f9d6f5011488a42`; baseline vcpkg `8ce02b3d9a447071083436ad36f318dd19dd19ad`. Fonti: [manifest upstream](https://github.com/derceg/explorerplusplus/blob/adf72c76b883271427ba16c39f9d6f5011488a42/vcpkg.json), [baseline Microsoft](https://github.com/microsoft/vcpkg/blob/8ce02b3d9a447071083436ad36f318dd19dd19ad/versions/baseline.json) e overlay nello stesso commit.

Questo inventario riguarda le 32 dipendenze dirette dichiarate per la build, incluse librerie per i test. Non e un SBOM completo del binario: non comprende tutte le dipendenze transitive e non dimostra quali parti siano state effettivamente collegate. Non e un risultato SCA "nessuna vulnerabilita".

| Dipendenza | Versione | Revisione port | Origine |
| --- | --- | --- | --- |
| better-enums | 0.11.3 | 0 | Microsoft vcpkg baseline |
| boost-algorithm | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-bimap | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-circular-buffer | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-container-hash | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-date-time | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-functional | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-integer | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-interprocess | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-iterator | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-lexical-cast | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-locale | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-multi-index | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-numeric-conversion | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-outcome | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-pfr | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-range | 1.89.0 | 0 | Microsoft vcpkg baseline |
| boost-signals2 | 1.89.0 | 0 | Microsoft vcpkg baseline |
| cereal | 1.3.2 | 1 | Microsoft vcpkg baseline |
| cli11 | 2.5.0 | 0 | Microsoft vcpkg baseline |
| concurrencpp | 0.1.7 | 1 | Pinned upstream overlay |
| cppcodec | 0.2 | 4 | Pinned upstream overlay |
| cppwinrt | 2.0.250303.1 | 0 | Microsoft vcpkg baseline |
| detours | 4.0.1 | 8 | Microsoft vcpkg baseline |
| fmt | 12.0.0 | 0 | Microsoft vcpkg baseline |
| glog | 0.7.1 | 0 | Microsoft vcpkg baseline |
| gtest | 1.17.0 | 2 | Microsoft vcpkg baseline |
| lua | 5.4.8 | 0 | Microsoft vcpkg baseline |
| nlohmann-json | 3.12.0 | 1 | Microsoft vcpkg baseline |
| pegtl | 3.2.8 | 0 | Microsoft vcpkg baseline |
| sol2 | 3.5.0 | 0 | Microsoft vcpkg baseline |
| wil | 1.0.250325.1 | 0 | Microsoft vcpkg baseline |

## Punto da aggiornare nella prossima build del core

Il baseline contiene Lua 5.4.8. Il progetto Lua ha pubblicato la 5.4.9 il 25 agosto 2026 come rilascio di correzioni: [notizia ufficiale](https://www.lua.org/news.html), [difetti conosciuti](https://www.lua.org/bugs.html), [differenze di sorgente](https://www.lua.org/work/diffs-lua-5.4.8-lua-5.4.9.html). Sono quindi presenti correzioni successive al baseline. Non si deduce automaticamente una vulnerabilita sfruttabile aprendo una cartella: il percorso d'uso di Lua e quello dei plug-in, non abilitati dal collegamento di questa edizione.

La confezione 0.2.0 ricompila il core per correggere il pool COM ma mantiene il baseline delle librerie. Lua resta 5.4.8; non si puo aggiornare una libreria statica sostituendo una DLL. Un suo aggiornamento richiede una nuova build con test e nuova provenienza. Non e dichiarato completato un audit di tutte le librerie.