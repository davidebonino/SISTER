DECLARE
  Azione       OBJ_Azione;
  Utente       OBJ_Utente;
  Profilo      OBJ_Profilo;
  Privilegio   OBJ_Privilegio;
  Abilitazione OBJ_Abilitazione;
  Ruolo        OBJ_Ruolo;
  Sessione     OBJ_Sessione;


  -- TEST: AZIONE -------------------------------------------
  PROCEDURE TAZ1(pIdAzione NUMBER) AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TAZ1 - TEST AZIONE');

    -- Caricamento azione
    Azione := OBJ_Azione.Carica(pIdAzione);
    IF Azione.Esito.StatusCode = 200 THEN

      -- Creazione azione
      DBMS_OUTPUT.PUT_LINE('Azione caricata con successo');
      Azione.Tipo := 'VISUALIZZA';
      Azione.Nome := 'VISUALIZZA AZIONE';
      Azione.Descrizione := 'Visualizza i dettagli di un''azione';
      Azione.Oggetto := 'AZIONE';
      Azione.Ambito := '';
      Azione.Crea;
      IF Azione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE(Azione.Esito.Messaggio);
        DBMS_OUTPUT.PUT_LINE('Nuovo IdAzione: ' || Azione.IdAzione);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella creazione dell''azione: ' || Azione.Esito.StatusCode  || ' - ' || Azione.Esito.Messaggio || ' - ' || Azione.Esito.DebugInfo);
      END IF;

      -- Modifica azione
      Azione.Nome := 'VISUALIZZA AZIONE MODIFICATA';
      Azione.Descrizione := 'Visualizza i dettagli di un''azione (modificata)';
      Azione.Modifica;
      IF Azione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Azione modificata con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella modifica dell''azione: ' || Azione.Esito.StatusCode || ' - ' || Azione.Esito.Messaggio || ' - ' || Azione.Esito.DebugInfo);
      END IF;

      -- Eliminazione azione
      Azione.Elimina;
      IF Azione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Azione eliminata con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nell''eliminazione dell''azione: ' || Azione.Esito.StatusCode || ' - ' || Azione.Esito.Messaggio || ' - ' || Azione.Esito.DebugInfo);
      END IF;

    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nel caricamento dell''azione: ' || Azione.Esito.StatusCode || ' - ' || Azione.Esito.Messaggio || ' - ' || Azione.Esito.DebugInfo);
    END IF;

  END;


  -- TEST: UTENTE -------------------------------------------
  PROCEDURE TUT1(pIdUtente NUMBER) AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TUT1 - TEST UTENTE');

    -- Caricamento utente
    Utente := OBJ_Utente.Carica(pIdUtente);
    IF Utente.Esito.StatusCode = 200 THEN

      -- Creazione utente
      DBMS_OUTPUT.PUT_LINE('Utente caricato con successo');
      Utente.Login := 'nuovo_login_test' || TO_CHAR(SYSDATE, 'SSSSS');
      Utente.Cognome := 'Nuovo Cognome Test';
      Utente.Crea;
      IF Utente.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE(Utente.Esito.Messaggio);
        DBMS_OUTPUT.PUT_LINE('Nuovo IdUtente: ' || Utente.IdUtente);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella creazione dell''utente: ' || Utente.Esito.StatusCode || ' - ' || Utente.Esito.DebugInfo);
      END IF;

      -- Modifica utente
      Utente.Cognome := 'Cognome Modificato Test';
      Utente.Modifica;
      IF Utente.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Utente modificato con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella modifica dell''utente: ' || Utente.Esito.StatusCode || ' - ' || Utente.Esito.DebugInfo);
      END IF;

      -- Eliminazione utente
      Utente.IdUtente := 8555;
      Utente.Elimina;
      IF Utente.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Utente eliminato con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nell''eliminazione dell''utente: ' || Utente.Esito.StatusCode || ' - ' || Utente.Esito.DebugInfo);
      END IF;

    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nel caricamento dell''utente: ' || Utente.Esito.StatusCode || ' - ' || Utente.Esito.DebugInfo);
    END IF;

  END;


  -- TEST: PROFILO -------------------------------------------
  PROCEDURE TPR1(pIdProfilo NUMBER) AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TPR1 - TEST PROFILO');

    -- Caricamento profilo
    Profilo := OBJ_Profilo.Carica(pIdProfilo);
    IF Profilo.Esito.StatusCode = 200 THEN

      -- Creazione profilo
      DBMS_OUTPUT.PUT_LINE('Profilo caricato con successo');
      Profilo.Nome := 'Nuovo Nome Profilo Test';
      Profilo.Crea;
      IF Profilo.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE(Profilo.Esito.Messaggio);
        DBMS_OUTPUT.PUT_LINE('Nuovo IdProfilo: ' || Profilo.IdProfilo);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella creazione del profilo: ' || Profilo.Esito.StatusCode || ' - ' || Profilo.Esito.DebugInfo);
      END IF;

      -- Modifica profilo
      Profilo.Nome := 'Nome Profilo Modificato Test';
      Profilo.Modifica;
      IF Profilo.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Profilo modificato con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella modifica del profilo: ' || Profilo.Esito.StatusCode || ' - ' || Profilo.Esito.DebugInfo);
      END IF;

      -- Eliminazione profilo
      Profilo.IdProfilo := 8555;
      Profilo.Elimina;
      IF Profilo.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Profilo eliminato con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nell''eliminazione del profilo: ' || Profilo.Esito.StatusCode || ' - ' || Profilo.Esito.DebugInfo);
      END IF;

    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nel caricamento del profilo: ' || Profilo.Esito.StatusCode || ' - ' || Profilo.Esito.DebugInfo);
    END IF;

  END;


  -- TEST: PRIVILEGIO -------------------------------------------
  PROCEDURE TPV1(pIdPrivilegio NUMBER) AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TPV1 - TEST PRIVILEGIO');

    -- Caricamento privilegio
    Privilegio := OBJ_Privilegio.Carica(pIdPrivilegio);
    IF Privilegio.Esito.StatusCode = 200 THEN

      -- Creazione privilegio
      DBMS_OUTPUT.PUT_LINE('Privilegio caricato con successo');
      Privilegio.IdAzione := Privilegio.IdAzione;
      Privilegio.IdRuolo  := Privilegio.IdRuolo;
      Privilegio.Crea;
      IF Privilegio.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE(Privilegio.Esito.Messaggio);
        DBMS_OUTPUT.PUT_LINE('Nuovo IdPrivilegio: ' || Privilegio.IdPrivilegio);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella creazione del privilegio: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio || ' - ' || Privilegio.Esito.DebugInfo);
      END IF;

      -- Modifica privilegio
      Privilegio.Attivo := 'S';
      Privilegio.Modifica;
      IF Privilegio.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Privilegio modificato con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella modifica del privilegio: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio || ' - ' || Privilegio.Esito.DebugInfo);
      END IF;

      -- Eliminazione privilegio (soft delete)
      Privilegio.Elimina;
      IF Privilegio.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Privilegio eliminato con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nell''eliminazione del privilegio: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio || ' - ' || Privilegio.Esito.DebugInfo);
      END IF;

    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nel caricamento del privilegio: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio || ' - ' || Privilegio.Esito.DebugInfo);
    END IF;

  END;


  -- TEST: ABILITAZIONE -------------------------------------------
  PROCEDURE TAB1(pIdSessione VARCHAR2, pIdAbilitazione NUMBER) AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TAB1 - TEST ABILITAZIONE');

    -- Caricamento abilitazione
    Abilitazione := OBJ_Abilitazione.Carica(pIdSessione, pIdAbilitazione);
    IF Abilitazione.Esito.StatusCode = 200 THEN

      -- Creazione abilitazione
      DBMS_OUTPUT.PUT_LINE('Abilitazione caricata con successo');
      Abilitazione.IdProfilo := Abilitazione.IdProfilo;
      Abilitazione.Tipo      := 1;
      Abilitazione.Chiave    := 'TEST_CHIAVE';
      Abilitazione.Valore    := 'TEST_VALORE';
      Abilitazione.Operatore := '=';
      Abilitazione.Crea;
      IF Abilitazione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE(Abilitazione.Esito.Messaggio);
        DBMS_OUTPUT.PUT_LINE('Nuovo IdChiave: ' || Abilitazione.IdChiave);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella creazione dell''abilitazione: ' || Abilitazione.Esito.StatusCode || ' - ' || Abilitazione.Esito.Messaggio || ' - ' || Abilitazione.Esito.DebugInfo);
      END IF;

      -- Modifica abilitazione
      Abilitazione.Valore := 'TEST_VALORE_MODIFICATO';
      Abilitazione.Modifica;
      IF Abilitazione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Abilitazione modificata con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nella modifica dell''abilitazione: ' || Abilitazione.Esito.StatusCode || ' - ' || Abilitazione.Esito.Messaggio || ' - ' || Abilitazione.Esito.DebugInfo);
      END IF;

      -- Eliminazione abilitazione (delete fisico)
      Abilitazione.Elimina;
      IF Abilitazione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Abilitazione eliminata con successo');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nell''eliminazione dell''abilitazione: ' || Abilitazione.Esito.StatusCode || ' - ' || Abilitazione.Esito.Messaggio || ' - ' || Abilitazione.Esito.DebugInfo);
      END IF;

    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nel caricamento dell''abilitazione: ' || Abilitazione.Esito.StatusCode || ' - ' || Abilitazione.Esito.Messaggio || ' - ' || Abilitazione.Esito.DebugInfo);
    END IF;

  END;


  -- TEST: RUOLO -------------------------------------------
  PROCEDURE TRU1(pIdRuolo NUMBER) AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TRU1 - TEST RUOLO');

    -- Caricamento ruolo
    Ruolo := OBJ_Ruolo.Carica(pIdRuolo);
    IF Ruolo.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('Ruolo caricato con successo');
      DBMS_OUTPUT.PUT_LINE('IdRuolo: '            || Ruolo.IdRuolo);
      DBMS_OUTPUT.PUT_LINE('Descrizione: '         || Ruolo.Descrizione);
      DBMS_OUTPUT.PUT_LINE('DataInizioValidita: '  || TO_CHAR(Ruolo.DataInizioValidita, 'DD/MM/YYYY'));
      DBMS_OUTPUT.PUT_LINE('DataFineValidita: '    || TO_CHAR(Ruolo.DataFineValidita,   'DD/MM/YYYY'));
    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nel caricamento del ruolo: ' || Ruolo.Esito.StatusCode || ' - ' || Ruolo.Esito.Messaggio || ' - ' || Ruolo.Esito.DebugInfo);
    END IF;

  END;


  -- TEST: SESSIONE -------------------------------------------
  PROCEDURE TSE1(pUsername VARCHAR2, pKeyword VARCHAR2, pIdProfilo NUMBER) AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TSE1 - TEST SESSIONE');

    -- Creazione sessione
    Sessione := OBJ_Sessione.Crea(pUsername, pKeyword, pIdProfilo);
    IF Sessione.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('Sessione creata con successo');
      DBMS_OUTPUT.PUT_LINE('IdSessione: ' || RAWTOHEX(Sessione.IdSessione));
      DBMS_OUTPUT.PUT_LINE('IdProfilo: '  || Sessione.IdProfilo);
      DBMS_OUTPUT.PUT_LINE('IdRuolo: '    || Sessione.IdRuolo);

      -- Caricamento sessione appena creata
      Sessione := OBJ_Sessione.Carica(RAWTOHEX(Sessione.IdSessione));
      IF Sessione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Sessione ricaricata con successo');
        DBMS_OUTPUT.PUT_LINE('Stato: ' || Sessione.Stato);
        DBMS_OUTPUT.PUT_LINE('Data: '  || TO_CHAR(Sessione.Data, 'DD/MM/YYYY HH24:MI:SS'));
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nel caricamento della sessione: ' || Sessione.Esito.StatusCode || ' - ' || Sessione.Esito.Messaggio || ' - ' || Sessione.Esito.DebugInfo);
      END IF;

    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nella creazione della sessione: ' || Sessione.Esito.StatusCode || ' - ' || Sessione.Esito.Messaggio || ' - ' || Sessione.Esito.DebugInfo);
    END IF;

  END;


  ----------------------------------------------------------------------------
  -- TEST: BUILDWHERE — filtro singolo COGNOME LIKE
  -- Verifica che BuildWhere generi correttamente il predicato LIKE su VARCHAR2
  -- e che la clausola prodotta restituisca righe valide dalla tabella UTENTI.
  --
  -- Setup: inserisce in ctx_column_map la mappatura
  --          namespace=CTX_APP_FLT, attribute=COGNOME,
  --          table_name=UTENTI, column_name=COGNOME
  -- Filtro contesto: COGNOME = 'B%|LIKE|VARCHAR2'
  -- WHERE attesa: U.COGNOME LIKE 'B%'
  -- Cleanup: ROLLBACK TO SAVEPOINT + PulisciContesto
  ----------------------------------------------------------------------------
  PROCEDURE TBW1 AS
    vUtente  OBJ_Utente;
    vWhere   VARCHAR2(32767);
    vSql     VARCHAR2(32767);
    cRec     SYS_REFCURSOR;
    vCognome VARCHAR2(50);
    vNome    VARCHAR2(50);
    vLogin   VARCHAR2(100);
    vCount   NUMBER := 0;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TBW1: BuildWhere - filtro singolo COGNOME LIKE ''B%'' ---');
    vUtente := OBJ_Utente();

    -- Setup: salva il punto di ripristino per il rollback del mapping di test
    SAVEPOINT tbw1_start;

    -- Registra la mappatura attributo → colonna per il namespace di test
    INSERT INTO ctx_column_map (namespace, attribute, table_name, column_name)
    VALUES ('CTX_APP_FLT', 'COGNOME', 'UTENTI', 'COGNOME');

    -- Imposta il filtro nel contesto: formato valore|OPERATORE|TIPO
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'B%|LIKE|VARCHAR2');

    -- Genera la clausola WHERE tramite BuildWhere
    vWhere := vUtente.BuildWhere('CTX_APP_FLT', 'UTENTI', 'U');
    DBMS_OUTPUT.PUT_LINE('WHERE generata: ' || NVL(vWhere, '(vuota - nessun filtro attivo)'));

    IF vWhere IS NOT NULL THEN
      -- Esegue la query dinamica usando la WHERE prodotta (max 5 righe)
      vSql := 'SELECT U.COGNOME, U.NOME, U.LOGIN'
           || '  FROM UTENTI U'
           || ' WHERE ' || vWhere
           || '   AND ROWNUM <= 5';
      OPEN cRec FOR vSql;
      LOOP
        FETCH cRec INTO vCognome, vNome, vLogin;
        EXIT WHEN cRec%NOTFOUND;
        vCount := vCount + 1;
        DBMS_OUTPUT.PUT_LINE('  [' || vCount || '] ' || vCognome || ' ' || vNome || ' — login: ' || vLogin);
      END LOOP;
      CLOSE cRec;
      IF vCount = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Nessun utente trovato con il filtro applicato');
      ELSE
        DBMS_OUTPUT.PUT_LINE('  Totale righe restituite (max 5): ' || vCount);
      END IF;
    END IF;

    -- Cleanup: annulla l'INSERT nel mapping di test e svuota il contesto
    ROLLBACK TO SAVEPOINT tbw1_start;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    DBMS_OUTPUT.PUT_LINE('TBW1 completato.');

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Errore TBW1: ' || SQLERRM);
      IF cRec%ISOPEN THEN CLOSE cRec; END IF;
      ROLLBACK TO SAVEPOINT tbw1_start;
      PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW1;


  ----------------------------------------------------------------------------
  -- TEST: BUILDWHERE — filtro singolo ATTIVO = 'S'
  -- Verifica che BuildWhere gestisca correttamente il predicato di uguaglianza
  -- su VARCHAR2 e filtri solo gli utenti attivi.
  --
  -- Setup: inserisce in ctx_column_map la mappatura
  --          namespace=CTX_APP_FLT, attribute=ATTIVO,
  --          table_name=UTENTI, column_name=ATTIVO
  -- Filtro contesto: ATTIVO = 'S|=|VARCHAR2'
  -- WHERE attesa: U.ATTIVO = 'S'
  -- Cleanup: ROLLBACK TO SAVEPOINT + PulisciContesto
  ----------------------------------------------------------------------------
  PROCEDURE TBW2 AS
    vUtente  OBJ_Utente;
    vWhere   VARCHAR2(32767);
    vSql     VARCHAR2(32767);
    cRec     SYS_REFCURSOR;
    vCognome VARCHAR2(50);
    vNome    VARCHAR2(50);
    vAttivo  VARCHAR2(1);
    vCount   NUMBER := 0;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TBW2: BuildWhere - filtro singolo ATTIVO = ''S'' ---');
    vUtente := OBJ_Utente();

    SAVEPOINT tbw2_start;

    -- Registra la mappatura attributo → colonna per il namespace di test
    INSERT INTO ctx_column_map (namespace, attribute, table_name, column_name)
    VALUES ('CTX_APP_FLT', 'ATTIVO', 'UTENTI', 'ATTIVO');

    -- Imposta il filtro: solo utenti attivi
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO', 'S|=|VARCHAR2');

    -- Genera la clausola WHERE tramite BuildWhere
    vWhere := vUtente.BuildWhere('CTX_APP_FLT', 'UTENTI', 'U');
    DBMS_OUTPUT.PUT_LINE('WHERE generata: ' || NVL(vWhere, '(vuota - nessun filtro attivo)'));

    IF vWhere IS NOT NULL THEN
      -- Esegue la query dinamica (max 5 righe)
      vSql := 'SELECT U.COGNOME, U.NOME, U.ATTIVO'
           || '  FROM UTENTI U'
           || ' WHERE ' || vWhere
           || '   AND ROWNUM <= 5';
      OPEN cRec FOR vSql;
      LOOP
        FETCH cRec INTO vCognome, vNome, vAttivo;
        EXIT WHEN cRec%NOTFOUND;
        vCount := vCount + 1;
        DBMS_OUTPUT.PUT_LINE('  [' || vCount || '] ' || vCognome || ' ' || vNome || ' — attivo: ' || vAttivo);
      END LOOP;
      CLOSE cRec;
      IF vCount = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Nessun utente trovato con il filtro applicato');
      ELSE
        DBMS_OUTPUT.PUT_LINE('  Totale righe restituite (max 5): ' || vCount);
      END IF;
    END IF;

    ROLLBACK TO SAVEPOINT tbw2_start;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    DBMS_OUTPUT.PUT_LINE('TBW2 completato.');

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Errore TBW2: ' || SQLERRM);
      IF cRec%ISOPEN THEN CLOSE cRec; END IF;
      ROLLBACK TO SAVEPOINT tbw2_start;
      PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW2;


  ----------------------------------------------------------------------------
  -- TEST: BUILDWHERE — filtri multipli combinati (COGNOME LIKE + ATTIVO =)
  -- Verifica che BuildWhere concateni correttamente più predicati con AND
  -- quando il contesto contiene più attributi contemporaneamente.
  --
  -- Setup: inserisce in ctx_column_map due mappature per CTX_APP_FLT/UTENTI:
  --          COGNOME → COGNOME
  --          ATTIVO  → ATTIVO
  -- Filtri contesto:
  --   COGNOME = 'B%|LIKE|VARCHAR2'
  --   ATTIVO  = 'S|=|VARCHAR2'
  -- WHERE attesa: U.COGNOME LIKE 'B%' AND U.ATTIVO = 'S'
  --              (l'ordine dipende dall'iterazione di SESSION_CONTEXT)
  -- Cleanup: ROLLBACK TO SAVEPOINT + PulisciContesto
  ----------------------------------------------------------------------------
  PROCEDURE TBW3 AS
    vUtente  OBJ_Utente;
    vWhere   VARCHAR2(32767);
    vSql     VARCHAR2(32767);
    cRec     SYS_REFCURSOR;
    vCognome VARCHAR2(50);
    vNome    VARCHAR2(50);
    vLogin   VARCHAR2(100);
    vAttivo  VARCHAR2(1);
    vCount   NUMBER := 0;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- TBW3: BuildWhere - filtri multipli COGNOME LIKE + ATTIVO = (AND) ---');
    vUtente := OBJ_Utente();

    SAVEPOINT tbw3_start;

    -- Registra entrambe le mappature attributo → colonna
    INSERT INTO ctx_column_map (namespace, attribute, table_name, column_name)
    VALUES ('CTX_APP_FLT', 'COGNOME', 'UTENTI', 'COGNOME');

    INSERT INTO ctx_column_map (namespace, attribute, table_name, column_name)
    VALUES ('CTX_APP_FLT', 'ATTIVO', 'UTENTI', 'ATTIVO');

    -- Imposta entrambi i filtri nel contesto
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'B%|LIKE|VARCHAR2');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO',  'S|=|VARCHAR2');

    -- Genera la clausola WHERE tramite BuildWhere (deve contenere AND tra i predicati)
    vWhere := vUtente.BuildWhere('CTX_APP_FLT', 'UTENTI', 'U');
    DBMS_OUTPUT.PUT_LINE('WHERE generata: ' || NVL(vWhere, '(vuota - nessun filtro attivo)'));

    IF vWhere IS NOT NULL THEN
      -- Esegue la query dinamica (max 5 righe)
      vSql := 'SELECT U.COGNOME, U.NOME, U.LOGIN, U.ATTIVO'
           || '  FROM UTENTI U'
           || ' WHERE ' || vWhere
           || '   AND ROWNUM <= 5';
      OPEN cRec FOR vSql;
      LOOP
        FETCH cRec INTO vCognome, vNome, vLogin, vAttivo;
        EXIT WHEN cRec%NOTFOUND;
        vCount := vCount + 1;
        DBMS_OUTPUT.PUT_LINE('  [' || vCount || '] ' || vCognome || ' ' || vNome
                          || ' — login: ' || vLogin || ', attivo: ' || vAttivo);
      END LOOP;
      CLOSE cRec;
      IF vCount = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  Nessun utente trovato con i filtri combinati');
      ELSE
        DBMS_OUTPUT.PUT_LINE('  Totale righe restituite (max 5): ' || vCount);
      END IF;
    END IF;

    ROLLBACK TO SAVEPOINT tbw3_start;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    DBMS_OUTPUT.PUT_LINE('TBW3 completato.');

  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Errore TBW3: ' || SQLERRM);
      IF cRec%ISOPEN THEN CLOSE cRec; END IF;
      ROLLBACK TO SAVEPOINT tbw3_start;
      PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW3;


----------------------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('ESECUZIONE TEST_APP');

  IF PKG_APP.Inizializza('davide.bonino', 'Peter_Pan', 17460) THEN
    DBMS_OUTPUT.PUT_LINE('Inizializzazione avvenuta con successo');

    DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID:');
    DBMS_OUTPUT.PUT_LINE(PKG_APP.VisualizzaContesto('CTX_APP_IDS'));

    DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ABILITAZIONI:');
    DBMS_OUTPUT.PUT_LINE(PKG_APP.VisualizzaContesto('CTX_APP_ABL'));

    --PKG_APP.VisualizzaContesto('CTX_APP_IDS');
    --DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID_SESSIONE: ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_SESSIONE'));
    --DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID_PROFILO: '  || SYS_CONTEXT('CTX_APP_IDS', 'ID_PROFILO'));
    --DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID_RUOLO: '    || SYS_CONTEXT('CTX_APP_IDS', 'ID_RUOLO'));
    --DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID_UTENTE: '   || SYS_CONTEXT('CTX_APP_IDS', 'ID_UTENTE'));

    -- ESECUZIONE TEST AZIONE
    --TAZ1(10);

    -- ESECUZIONE TEST UTENTE
    --TUT1(237);

    -- ESECUZIONE TEST PROFILO
    --TPR1(237);

    -- ESECUZIONE TEST PRIVILEGIO
    --TPV1(1);

    -- ESECUZIONE TEST ABILITAZIONE
    --TAB1(SYS_CONTEXT('CTX_APP_IDS', 'ID_SESSIONE'), 1);

    -- ESECUZIONE TEST RUOLO
    --TRU1(100);

    -- ESECUZIONE TEST SESSIONE
    --TSE1('davide.bonino', 'Peter_Pan', 17460);

    -- ESECUZIONE TEST BUILDWHERE
    -- TBW1: filtro singolo — COGNOME LIKE 'B%'
    TBW1;
    -- TBW2: filtro singolo — solo utenti ATTIVO = 'S'
    TBW2;
    -- TBW3: filtri multipli combinati — COGNOME LIKE 'B%' AND ATTIVO = 'S'
    TBW3;

    COMMIT;

  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore di inizializzazione della sessione');
  END IF;

END;
