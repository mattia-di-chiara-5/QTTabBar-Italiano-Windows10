# Pubblicazione GitHub v0.4.0

La release deve partire dal branch feature/italian-built-in, basato sul
commit upstream 44a83bef8cdf5fb67c6d7f6434821c6f602542e7.

## File da versionare

- i sei file sorgente/risorsa della localizzazione built-in;
- la directory Italiano/;
- il workflow .github/workflows/validate-italian.yml.

Non versionare snapshot GAC, file .reg, log locali, cartelle bin/obj o il
payload MSI. Il pacchetto offline va allegato alla GitHub Release.

## Sequenza

1. eseguire validazione risorse, build Release Any CPU e audit ILDASM;
2. completare il test runtime e il test di rollback;
3. creare un commit sorgente atomico;
4. creare un secondo commit per installer e documentazione;
5. eseguire push del branch;
6. aprire una pull request verso una nuova linea stabile release/0.4;
7. unire solo dopo il workflow verde;
8. creare il tag annotato it-v0.4.0;
9. creare una GitHub Release dal tag;
10. allegare lo ZIP offline e pubblicarne lo SHA-256.

Non modificare o spostare il tag storico it-v0.3.0.

## Asset definitivo verificato

Nome:

    QTTabBar-Italiano-Windows10-v0.4.0.zip

Dimensione: 2.044.074 byte

SHA-256:

    D31D917E3C41342F27D24E7310C82700567D162FADD8EF4B564F416B2C79B221
