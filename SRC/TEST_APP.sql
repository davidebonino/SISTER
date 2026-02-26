DECLARE
  Azione OBJ_Azione;
  Utente OBJ_Utente;
  Profilo OBJ_Profilo;
  Privilegio OBJ_Privilegio;
  Abilitazione OBJ_Abilitazione;
  Ruolo OBJ_Ruolo;
  Sessione OBJ_Sessione;


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
      Privilegio.IdRuolo := Privilegio.IdRuolo;
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
      Abilitazione.Tipo := 1;
      Abilitazione.Chiave := 'TEST_CHIAVE';
      Abilitazione.Valore := 'TEST_VALORE';
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
      DBMS_OUTPUT.PUT_LINE('IdRuolo: ' || Ruolo.IdRuolo);
      DBMS_OUTPUT.PUT_LINE('Descrizione: ' || Ruolo.Descrizione);
      DBMS_OUTPUT.PUT_LINE('DataInizioValidita: ' || TO_CHAR(Ruolo.DataInizioValidita, 'DD/MM/YYYY'));
      DBMS_OUTPUT.PUT_LINE('DataFineValidita: ' || TO_CHAR(Ruolo.DataFineValidita, 'DD/MM/YYYY'));
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
      DBMS_OUTPUT.PUT_LINE('IdProfilo: ' || Sessione.IdProfilo);
      DBMS_OUTPUT.PUT_LINE('IdRuolo: ' || Sessione.IdRuolo);

      -- Caricamento sessione appena creata
      Sessione := OBJ_Sessione.Carica(RAWTOHEX(Sessione.IdSessione));
      IF Sessione.Esito.StatusCode = 200 THEN
        DBMS_OUTPUT.PUT_LINE('Sessione ricaricata con successo');
        DBMS_OUTPUT.PUT_LINE('Stato: ' || Sessione.Stato);
        DBMS_OUTPUT.PUT_LINE('Data: ' || TO_CHAR(Sessione.Data, 'DD/MM/YYYY HH24:MI:SS'));
      ELSE
        DBMS_OUTPUT.PUT_LINE('Errore nel caricamento della sessione: ' || Sessione.Esito.StatusCode || ' - ' || Sessione.Esito.Messaggio || ' - ' || Sessione.Esito.DebugInfo);
      END IF;

    ELSE
      DBMS_OUTPUT.PUT_LINE('Errore nella creazione della sessione: ' || Sessione.Esito.StatusCode || ' - ' || Sessione.Esito.Messaggio || ' - ' || Sessione.Esito.DebugInfo);
    END IF;

  END;


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
    --DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID_PROFILO: ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_PROFILO'));
    --DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID_RUOLO: ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_RUOLO'));
    --DBMS_OUTPUT.PUT_LINE('LETTURA CONTESTO ID_UTENTE: ' || SYS_CONTEXT('CTX_APP_IDS', 'ID_UTENTE'));

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

    COMMIT;

  ELSE
    DBMS_OUTPUT.PUT_LINE('Errore di inizializzazione della sessione');
  END IF;

END;
