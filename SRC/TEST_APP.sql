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

        -- Creazione azione
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

    END TAZ1;


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
        --Utente.IdUtente := 8555;
        Utente.Elimina;
        IF Utente.Esito.StatusCode = 200 THEN
          DBMS_OUTPUT.PUT_LINE('Utente eliminato con successo');
        ELSE
          DBMS_OUTPUT.PUT_LINE('Errore nell''eliminazione dell''utente: ' || Utente.Esito.StatusCode || ' - ' || Utente.Esito.DebugInfo);
        END IF;

      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nel caricamento dell''utente: ' || Utente.Esito.StatusCode || ' - ' || Utente.Esito.DebugInfo);
      END IF;

    END TUT1;


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

    END TPR1;


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

    END TPV1;


  -- TEST: PRIVILEGIO - Verifica eliminazione soft e fisica ----------------------------
  -- Obiettivo: verificare che Elimina (default) esegua il soft delete (Attivo='N')
  --            e che Elimina(TRUE) esegua la cancellazione fisica (record assente)
  PROCEDURE TPV2(pIdAzione NUMBER, pIdRuolo NUMBER) AS
    vIdPrivilegio NUMBER;
    BEGIN
      DBMS_OUTPUT.PUT_LINE('ESECUZIONE TPV2 - TEST PRIVILEGIO ELIMINAZIONE SOFT E FISICA');

      -- Creazione del privilegio di test
      Privilegio := OBJ_Privilegio();
      Privilegio.IdAzione := pIdAzione;
      Privilegio.IdRuolo  := pIdRuolo;
      Privilegio.Crea;
      IF Privilegio.Esito.StatusCode <> 200 THEN
        DBMS_OUTPUT.PUT_LINE('Errore creazione privilegio: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio || ' - ' || Privilegio.Esito.DebugInfo);
        RETURN;
      END IF;
      vIdPrivilegio := Privilegio.IdPrivilegio;
      DBMS_OUTPUT.PUT_LINE('Privilegio creato - IdPrivilegio: ' || vIdPrivilegio);

      -- Soft delete (pFisica = FALSE, default)
      Privilegio.Elimina;
      IF Privilegio.Esito.StatusCode = 200 THEN
        -- Verifica: il record deve esistere con Attivo = 'N'
        Privilegio := OBJ_Privilegio.Carica(vIdPrivilegio);
        IF Privilegio.Esito.StatusCode = 200 AND Privilegio.Attivo = 'N' THEN
          DBMS_OUTPUT.PUT_LINE('Soft delete OK: record presente con Attivo = N');
        ELSE
          DBMS_OUTPUT.PUT_LINE('Soft delete FALLITO: stato inatteso - StatusCode=' || Privilegio.Esito.StatusCode || ' - Attivo=' || Privilegio.Attivo);
        END IF;
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore soft delete: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio || ' - ' || Privilegio.Esito.DebugInfo);
      END IF;

      -- Eliminazione fisica dello stesso record (pFisica = TRUE)
      Privilegio.IdPrivilegio := vIdPrivilegio;
      Privilegio.Elimina(TRUE);
      IF Privilegio.Esito.StatusCode = 200 THEN
        -- Verifica: il record non deve più essere presente
        Privilegio := OBJ_Privilegio.Carica(vIdPrivilegio);
        IF Privilegio.Esito.StatusCode = 204 THEN
          DBMS_OUTPUT.PUT_LINE('Eliminazione fisica OK: record non più presente');
        ELSE
          DBMS_OUTPUT.PUT_LINE('Eliminazione fisica FALLITA: record ancora presente - StatusCode=' || Privilegio.Esito.StatusCode);
        END IF;
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore eliminazione fisica: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio || ' - ' || Privilegio.Esito.DebugInfo);
      END IF;

    END TPV2;


  -- TEST: PRIVILEGIO - Carica per Azione/Ruolo e Cerca --------------------------------
  -- Obiettivo: verificare Carica(IdAzione, IdRuolo) e Cerca con coppia valida e
  --            con coppia inesistente (atteso NULL)
  PROCEDURE TPV3(pIdAzione NUMBER, pIdRuolo NUMBER) AS
    vIdPrivilegio NUMBER;
    BEGIN
      DBMS_OUTPUT.PUT_LINE('ESECUZIONE TPV3 - TEST PRIVILEGIO CARICA PER AZIONE/RUOLO E CERCA');

      -- Carica per coppia IdAzione / IdRuolo
      Privilegio := OBJ_Privilegio.Carica(pIdAzione, pIdRuolo);
      IF Privilegio.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Carica(IdAzione, IdRuolo) OK - IdPrivilegio: ' || Privilegio.IdPrivilegio || ' - Attivo: ' || Privilegio.Attivo);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Carica(IdAzione, IdRuolo) non trovato: ' || Privilegio.Esito.StatusCode || ' - ' || Privilegio.Esito.Messaggio);
      END IF;

      -- Cerca con coppia valida: deve restituire l'IdPrivilegio
      vIdPrivilegio := OBJ_Privilegio.Cerca(pIdAzione, pIdRuolo);
      IF vIdPrivilegio IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Cerca(IdAzione, IdRuolo) OK: IdPrivilegio = ' || vIdPrivilegio);
      ELSE
        DBMS_OUTPUT.PUT_LINE('Cerca(IdAzione, IdRuolo): nessun privilegio trovato per IdAzione=' || pIdAzione || ', IdRuolo=' || pIdRuolo);
      END IF;

      -- Cerca con coppia inesistente: deve restituire NULL
      vIdPrivilegio := OBJ_Privilegio.Cerca(-1, -1);
      IF vIdPrivilegio IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Cerca con ID inesistenti: NULL restituito correttamente');
      ELSE
        DBMS_OUTPUT.PUT_LINE('Cerca con ID inesistenti: valore inatteso = ' || vIdPrivilegio);
      END IF;

    END TPV3;


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

    END TAB1;


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

    END TRU1;


  -- TEST: BUILDWHERE -------------------------------------------
  -- I test TBW gestiscono direttamente CTX_APP_ABL e CTX_APP_FLT via PulisciContesto/AggiungiContesto.
  -- Non richiedono SAVEPOINT: nessuna scrittura su DB.

  -- TBW1: FLT singolo, LIKE su VARCHAR2
  PROCEDURE TBW1 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW1 - BUILDWHERE: FLT LIKE VARCHAR2');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'B%|LIKE');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere(NULL, vWhere);

    IF vUtente.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('TBW1 WHERE: ' || NVL(vWhere, '(vuota)'));
      IF INSTR(vWhere, q'[COGNOME LIKE 'B%']') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TBW1 OK');
      ELSE
        DBMS_OUTPUT.PUT_LINE('TBW1 KO: predicato atteso assente');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW1 KO - ' || vUtente.Esito.StatusCode || ': ' || vUtente.Esito.Messaggio);
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW1;


  -- TBW2: FLT singolo, = su NUMBER
  PROCEDURE TBW2 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW2 - BUILDWHERE: FLT = NUMBER');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ID_UTENTE', '237|=');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere(NULL, vWhere);

    IF vUtente.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('TBW2 WHERE: ' || NVL(vWhere, '(vuota)'));
      IF INSTR(vWhere, 'ID_UTENTE = 237') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TBW2 OK');
      ELSE
        DBMS_OUTPUT.PUT_LINE('TBW2 KO: predicato atteso assente');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW2 KO - ' || vUtente.Esito.StatusCode || ': ' || vUtente.Esito.Messaggio);
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW2;


  -- TBW3: FLT multipli, combinazione AND
  PROCEDURE TBW3 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW3 - BUILDWHERE: FLT multipli AND');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'COGNOME', 'B%|LIKE');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO',  'S|=');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere(NULL, vWhere);

    IF vUtente.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('TBW3 WHERE: ' || NVL(vWhere, '(vuota)'));
      IF INSTR(vWhere, 'COGNOME') > 0 AND INSTR(vWhere, 'ATTIVO') > 0 AND INSTR(vWhere, ' AND ') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TBW3 OK');
      ELSE
        DBMS_OUTPUT.PUT_LINE('TBW3 KO: AND con entrambi i predicati assente');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW3 KO - ' || vUtente.Esito.StatusCode || ': ' || vUtente.Esito.Messaggio);
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW3;


  -- TBW4: ABL + FLT stesso campo, stesso valore → deduplicazione (nessun IN, nessun avviso)
  PROCEDURE TBW4 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW4 - BUILDWHERE: ABL + FLT stesso valore, deduplicazione');
    PKG_APP.PulisciContesto('CTX_APP_ABL');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_ABL', 'ATTIVO', 'S|=');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO', 'S|=');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere(NULL, vWhere);

    IF vUtente.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('TBW4 WHERE: ' || NVL(vWhere, '(vuota)'));
      IF vUtente.Esito.DebugInfo IS NULL AND INSTR(vWhere, ' IN ') = 0 THEN
        DBMS_OUTPUT.PUT_LINE('TBW4 OK: nessun avviso, nessun IN (valore deduplicato)');
      ELSE
        DBMS_OUTPUT.PUT_LINE('TBW4 KO: avviso o IN inatteso - DebugInfo: ' || NVL(vUtente.Esito.DebugInfo, 'NULL'));
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW4 KO - ' || vUtente.Esito.StatusCode || ': ' || vUtente.Esito.Messaggio);
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_ABL');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW4;


  -- TBW5: ABL + FLT stesso campo, valori diversi → IN clause + avviso
  PROCEDURE TBW5 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW5 - BUILDWHERE: FLT allarga visibilità ABL, avviso atteso');
    PKG_APP.PulisciContesto('CTX_APP_ABL');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_ABL', 'ATTIVO', 'S|=');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ATTIVO', 'N|=');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere(NULL, vWhere);

    IF vUtente.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('TBW5 WHERE: ' || NVL(vWhere, '(vuota)'));
      IF vUtente.Esito.DebugInfo IS NOT NULL AND INSTR(vWhere, ' IN ') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TBW5 OK: avviso presente, IN clause generata');
        DBMS_OUTPUT.PUT_LINE('TBW5 Avviso: ' || vUtente.Esito.DebugInfo);
      ELSE
        DBMS_OUTPUT.PUT_LINE('TBW5 KO: avviso assente o IN assente');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW5 KO - ' || vUtente.Esito.StatusCode || ': ' || vUtente.Esito.Messaggio);
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_ABL');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW5;


  -- TBW6: sinonimo non riconosciuto → errore 400, pWhere NULL
  PROCEDURE TBW6 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW6 - BUILDWHERE: sinonimo sconosciuto, errore 400 atteso');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'CAMPO_IGNOTO', 'X|=');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere(NULL, vWhere);

    IF vUtente.Esito.StatusCode = 400 AND vWhere IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('TBW6 OK: errore 400 e WHERE NULL come atteso');
      DBMS_OUTPUT.PUT_LINE('TBW6 Messaggio: ' || vUtente.Esito.Messaggio);
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW6 KO - StatusCode: ' || vUtente.Esito.StatusCode || ', WHERE: ' || NVL(vWhere, 'NULL'));
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW6;


  -- TBW7: operatore BETWEEN su NUMBER
  PROCEDURE TBW7 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW7 - BUILDWHERE: BETWEEN NUMBER');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'ID_UTENTE', '100;500|BETWEEN');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere(NULL, vWhere);

    IF vUtente.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('TBW7 WHERE: ' || NVL(vWhere, '(vuota)'));
      IF INSTR(vWhere, 'ID_UTENTE BETWEEN 100 AND 500') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TBW7 OK');
      ELSE
        DBMS_OUTPUT.PUT_LINE('TBW7 KO: predicato BETWEEN atteso assente');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW7 KO - ' || vUtente.Esito.StatusCode || ': ' || vUtente.Esito.Messaggio);
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW7;


  -- TBW8: IS NOT NULL con alias tabella
  PROCEDURE TBW8 AS
    vUtente OBJ_Utente;
    vWhere  VARCHAR2(32767);
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ESECUZIONE TBW8 - BUILDWHERE: IS NOT NULL con alias');
    PKG_APP.PulisciContesto('CTX_APP_FLT');
    PKG_APP.AggiungiContesto('CTX_APP_FLT', 'EMAIL', '|NOTNULL');

    vUtente := OBJ_Utente();
    vUtente.BuildWhere('U', vWhere);

    IF vUtente.Esito.StatusCode = 200 THEN
      DBMS_OUTPUT.PUT_LINE('TBW8 WHERE: ' || NVL(vWhere, '(vuota)'));
      IF INSTR(vWhere, 'U.EMAIL IS NOT NULL') > 0 THEN
        DBMS_OUTPUT.PUT_LINE('TBW8 OK');
      ELSE
        DBMS_OUTPUT.PUT_LINE('TBW8 KO: predicato IS NOT NULL con alias assente');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('TBW8 KO - ' || vUtente.Esito.StatusCode || ': ' || vUtente.Esito.Messaggio);
    END IF;
    PKG_APP.PulisciContesto('CTX_APP_FLT');
  END TBW8;


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

    END TSE1;



----------------------------------------------------------------------------
--                               T E S T                                  --
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

    -- ESECUZIONE TEST PRIVILEGIO - singolo oggetto CRUD
    TPV1(1);

    -- ESECUZIONE TEST PRIVILEGIO - eliminazione soft e fisica
    TPV2(10, 100);

    -- ESECUZIONE TEST PRIVILEGIO - Carica per Azione/Ruolo e Cerca
    TPV3(10, 100);

    -- ESECUZIONE TEST ABILITAZIONE
    --TAB1(SYS_CONTEXT('CTX_APP_IDS', 'ID_SESSIONE'), 1);

    -- ESECUZIONE TEST RUOLO
    --TRU1(100);

    -- ESECUZIONE TEST SESSIONE
    --TSE1('davide.bonino', 'Peter_Pan', 17460);



    COMMIT;

  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore di inizializzazione della sessione');
  END IF;

END;
