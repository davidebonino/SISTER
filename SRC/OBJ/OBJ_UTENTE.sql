----------------------------------------------------------------------------
-- OBJ_Utente — Entita utente con CRUD completo e soft delete
--
-- SCOPO
--   Rappresenta un utente del sistema con tutti i suoi dati anagrafici,
--   credenziali di accesso e campi di audit. Implementa il pattern CRUD
--   standard con verifica accesso RBAC su ogni operazione di scrittura.
--
-- PATTERN SOFT DELETE
--   Elimina(pFisica=FALSE) → imposta Attivo='N' (record mantenuto)
--   Elimina(pFisica=TRUE)  → cancellazione fisica da UTENTI
--
-- CAMPI SENSIBILI (GDPR)
--   CodiceFiscale, Telefono, Cellulare, Email — dati personali identificativi
--   Password0/1/2 — hash MD5 della password corrente e delle ultime 2
--
-- AUDIT TRAIL
--   DataIns/UtenteIns — creazione record
--   DataAgg/UtenteAgg — ultima modifica
--
-- METODO Carica
--   Richiede MioIdRuolo() IS NOT NULL (sessione inizializzata).
--   Usato anche da PKG_APP.Inizializza: in quel contesto non viene chiamato
--   VerificaAccesso perche la sessione non e ancora completamente popolata.
--
-- DIPENDENZE
--   UNDER OBJ_Profilatore — eredita Esito, BuildWhere e funzioni statiche
--   AZIONI/PRIVILEGI: INSERIMENTO/MODIFICA/ELIMINAZIONE su 'UTENTE'
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Utente UNDER OBJ_Profilatore (
  IdUtente             NUMBER,
  Login                VARCHAR2(100),
  Password0            VARCHAR2(32),
  Password1            VARCHAR2(32),
  Password2            VARCHAR2(32),
  Cognome              VARCHAR2(50),
  Nome                 VARCHAR2(50),
  CodiceFiscale        VARCHAR2(16),
  Telefono             VARCHAR2(20),
  Cellulare            VARCHAR2(20),
  Fax                  VARCHAR2(20),
  Email                VARCHAR2(100),
  Attivo               VARCHAR2(1),
  DataScadenzaPassword DATE,
  DataUltimoAccesso    DATE,
  DataIns              DATE,
  UtenteIns            NUMBER,
  DataAgg              DATE,
  UtenteAgg            NUMBER,
  Annotazioni          VARCHAR2(2048),
  IdProfessione        NUMBER(9),
  Incarico             VARCHAR2(50),
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,
  STATIC FUNCTION Carica(pIdUtente NUMBER) RETURN OBJ_Utente,
  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN,
  MEMBER PROCEDURE Crea,
  MEMBER PROCEDURE Modifica,
  MEMBER PROCEDURE Elimina(pFisica BOOLEAN DEFAULT FALSE),
  MEMBER PROCEDURE Cerca(pCursor OUT SYS_REFCURSOR),
  CONSTRUCTOR FUNCTION OBJ_Utente RETURN SELF AS RESULT
  );

----------------------------------------------------------------------------

CREATE OR REPLACE TYPE BODY OBJ_Utente AS

  -- Costruttore
  CONSTRUCTOR FUNCTION OBJ_Utente RETURN SELF AS RESULT
    IS
    BEGIN
      SELF.IdUtente      := NULL;
      SELF.Login         := NULL;
      SELF.Password0     := NULL;
      SELF.Password1     := NULL;
      SELF.Password2     := NULL;
      SELF.Cognome       := NULL;
      SELF.Nome          := NULL;
      SELF.CodiceFiscale := NULL;
      SELF.Telefono      := NULL;
      SELF.Cellulare     := NULL;
      SELF.Fax           := NULL;
      SELF.Email         := NULL;
      SELF.Attivo        := NULL;
      SELF.DataScadenzaPassword := NULL;
      SELF.DataUltimoAccesso    := NULL;
      SELF.DataIns       := NULL;
      SELF.UtenteIns     := NULL;
      SELF.DataAgg       := NULL;
      SELF.UtenteAgg     := NULL;
      SELF.Annotazioni   := NULL;
      SELF.IdProfessione := NULL;
      SELF.Incarico      := NULL;
      RETURN;
    END;


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
    BEGIN
      RETURN 'UTENTE';
    END Info;
    --------------------------------------------------------------------------


  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE UPPER(pSinonimo)
      WHEN 'ID_UTENTE'      THEN 'ID_UTENTE|N'
      WHEN 'LOGIN'          THEN 'LOGIN|V'
      WHEN 'COGNOME'        THEN 'COGNOME|V'
      WHEN 'NOME'           THEN 'NOME|V'
      WHEN 'CODICE_FISCALE' THEN 'CODICE_FISCALE|V'
      WHEN 'EMAIL'          THEN 'EMAIL|V'
      WHEN 'TELEFONO'       THEN 'TELEFONO|V'
      WHEN 'CELLULARE'      THEN 'CELLULARE|V'
      WHEN 'ATTIVO'         THEN 'ATTIVO|V'
      WHEN 'ID_PROFESSIONE' THEN 'ID_PROFESSIONE|N'
      WHEN 'INCARICO'       THEN 'INCARICO|V'
      ELSE NULL
    END;
  END RisolviSinonimo;
  --------------------------------------------------------------------------


  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN IS
    BEGIN
      RETURN TRUE;
    END ControlliLogici;
    --------------------------------------------------------------------------


  -- Crea un oggetto Utente nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Crea IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'UTENTE', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.IdUtente      := UTENTI_ID_UTENTE.NEXTVAL;
      SELF.Attivo        := 'S';
      SELF.DataIns       := SYSDATE;
      SELF.UtenteIns     := OBJ_Utente.MioIdUtente();
      SELF.DataAgg       := SYSDATE;
      SELF.UtenteAgg     := OBJ_Utente.MioIdUtente();

      INSERT INTO UTENTI (
        Id_Utente,
        Login,
        Password_0,
        Password_1,
        Password_2,
        Cognome,
        Nome,
        Codice_Fiscale,
        Telefono,
        Cellulare,
        Fax,
        Email,
        Attivo,
        Data_Scadenza_Password,
        Data_Ultimo_Accesso,
        DataIns,
        UtenteIns,
        DataAgg,
        UtenteAgg,
        Annotazioni,
        Id_Professione,
        Incarico)
      VALUES (
        SELF.IdUtente,
        SELF.Login,
        SELF.Password0,
        SELF.Password1,
        SELF.Password2,
        SELF.Cognome,
        SELF.Nome,
        SELF.CodiceFiscale,
        SELF.Telefono,
        SELF.Cellulare,
        SELF.Fax,
        SELF.Email,
        SELF.Attivo,
        SELF.DataScadenzaPassword,
        SELF.DataUltimoAccesso,
        SELF.DataIns,
        SELF.UtenteIns,
        SELF.DataAgg,
        SELF.UtenteAgg,
        SELF.Annotazioni,
        SELF.IdProfessione,
        SELF.Incarico
      );
      SELF.Esito := OBJ_Esito.Imposta(200, 'Utente creato con successo', NULL, NULL);

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Utente non inserito per errore interno', 'Utente non inserito per errore interno' || SQLERRM, SQLERRM);

    END Crea;
    --------------------------------------------------------------------------


  -- Modifica un oggetto Utente nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Modifica IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('MODIFICA', 'UTENTE', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.DataAgg       := SYSDATE;
      SELF.UtenteAgg     := OBJ_Utente.MioIdUtente();

      UPDATE UTENTI SET
        Login = SELF.Login,
        Password_0 = SELF.Password0,
        Password_1 = SELF.Password1,
        Password_2 = SELF.Password2,
        Cognome = SELF.Cognome,
        Nome = SELF.Nome,
        Codice_Fiscale = SELF.CodiceFiscale,
        Telefono = SELF.Telefono,
        Cellulare = SELF.Cellulare,
        Fax = SELF.Fax,
        Email = SELF.Email,
        Attivo = SELF.Attivo,
        Data_Scadenza_Password = SELF.DataScadenzaPassword,
        Data_Ultimo_Accesso = SELF.DataUltimoAccesso,
        DataAgg = SELF.DataAgg,
        UtenteAgg = SELF.UtenteAgg,
        Annotazioni = SELF.Annotazioni,
        Id_Professione = SELF.IdProfessione,
        Incarico = SELF.Incarico
      WHERE Id_Utente = SELF.IdUtente;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Utente modificato con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Utente non trovato per modifica', 'Utente non trovato per modifica', 'OBJ_Utente.Modifica: Nessun record aggiornato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Utente non modificato per errore interno', 'Utente non modificato per errore interno' || SQLERRM, SQLERRM);

    END Modifica;
    --------------------------------------------------------------------------


  -- Elimina un oggetto Utente nel database.
  -- pFisica = FALSE (default): soft delete (Attivo = 'N')
  -- pFisica = TRUE: eliminazione fisica del record
  MEMBER PROCEDURE Elimina(pFisica BOOLEAN DEFAULT FALSE) IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('ELIMINAZIONE', 'UTENTE', NULL, TRUE);
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      IF pFisica THEN
        --Cancellazione fisica
        DELETE FROM UTENTI
        WHERE Id_Utente = SELF.IdUtente;
      ELSE
        --Cancellazione logica (soft delete)
        SELF.DataAgg   := SYSDATE;
        SELF.UtenteAgg := OBJ_Utente.MioIdUtente();
        SELF.Attivo    := 'N';

        UPDATE UTENTI SET
          Attivo    = SELF.Attivo,
          DataAgg   = SELF.DataAgg,
          UtenteAgg = SELF.UtenteAgg
        WHERE Id_Utente = SELF.IdUtente;

      END IF;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Utente eliminato con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Utente non trovato per eliminazione', 'Utente non trovato per eliminazione', 'OBJ_Utente.Elimina: Nessun record aggiornato');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        SELF.Esito := OBJ_Esito.Imposta(500, 'Utente non eliminato per errore interno', 'Utente non eliminato per errore interno' || SQLERRM, SQLERRM);
    END Elimina;
    --------------------------------------------------------------------------


  -- Carica l'utente
  STATIC FUNCTION Carica(pIdUtente NUMBER) RETURN OBJ_Utente IS
    vUtente OBJ_Utente;
  BEGIN
    vUtente := OBJ_Utente();

    IF OBJ_Utente.MioIdRuolo() IS NOT NULL THEN

      SELECT Id_Utente,
            Login,
            Password_0,
            Password_1,
            Password_2,
            Cognome,
            Nome,
            Codice_Fiscale,
            Telefono,
            Cellulare,
            Fax,
            Email,
            Attivo,
            Data_Scadenza_Password,
            Data_Ultimo_Accesso,
            DataIns,
            UtenteIns,
            DataAgg,
            UtenteAgg,
            Annotazioni,
            Id_Professione,
            Incarico
        INTO vUtente.IdUtente,
            vUtente.Login,
            vUtente.Password0,
            vUtente.Password1,
            vUtente.Password2,
            vUtente.Cognome,
            vUtente.Nome,
            vUtente.CodiceFiscale,
            vUtente.Telefono,
            vUtente.Cellulare,
            vUtente.Fax,
            vUtente.Email,
            vUtente.Attivo,
            vUtente.DataScadenzaPassword,
            vUtente.DataUltimoAccesso,
            vUtente.DataIns,
            vUtente.UtenteIns,
            vUtente.DataAgg,
            vUtente.UtenteAgg,
            vUtente.Annotazioni,
            vUtente.IdProfessione,
            vUtente.Incarico
        FROM Utenti
      WHERE ID_UTENTE = pIdUtente;

      IF vUtente.IdUtente IS NOT NULL THEN
        vUtente.Esito := OBJ_Esito.Imposta(200, 'Utente caricato con successo', NULL, NULL);
        RETURN vUtente;
      ELSE
        vUtente.Esito := OBJ_Esito.Imposta(204, 'Utente non trovato', 'Utente non trovato per i parametri forniti', NULL);
        RETURN vUtente;
      END IF;
    ELSE
      -- Chiamante non autorizzato
      vUtente.Esito := OBJ_Esito.Imposta(401, 'Chiamante non autorizzato', 'Chiamante non autorizzato', NULL);
      RETURN vUtente;
    END IF;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          -- Utente non trovato
          vUtente.Esito := OBJ_Esito.Imposta(204, 'Utente non trovato, parametri errati', 'Utente non trovato, parametri errati' || SQLERRM, SQLERRM);
          RETURN vUtente;
        WHEN OTHERS THEN
          -- Log dell'errore per debugging
          vUtente.Esito := OBJ_Esito.Imposta(500, 'Utente non trovato per errore interno', 'Utente non trovato per errore interno' || SQLERRM, SQLERRM);
          RETURN vUtente;
    END Carica;
    --------------------------------------------------------------------------


  -- Esegue una ricerca sugli utenti applicando i filtri di autorizzazione
  -- (CTX_APP_ABL) e di ricerca (CTX_APP_FLT) tramite BuildWhere.
  -- Il chiamante imposta i filtri su CTX_APP_FLT prima di invocare Cerca,
  -- poi itera sul cursore con FETCH e lo chiude con CLOSE al termine.
  --
  -- Colonne restituite: Id_Utente, Login, Cognome, Nome, Email, Attivo.
  -- Ordine: Cognome ASC, Nome ASC.
  -- Campi esclusi: Password_0/1/2 (hash MD5) e campi di audit.
  --
  -- SELF.Esito dopo la chiamata:
  --   200 — cursore aperto, iterare con FETCH ... CLOSE
  --   401 — sessione non inizializzata (MioIdRuolo IS NULL)
  --   400 — errore nei filtri (BuildWhere fallita)
  --   500 — errore interno
  MEMBER PROCEDURE Cerca(pCursor OUT SYS_REFCURSOR) IS
    vWhere VARCHAR2(32767);
    vSql   VARCHAR2(32767);
  BEGIN

    IF OBJ_Utente.MioIdRuolo() IS NULL THEN
      SELF.Esito := OBJ_Esito.Imposta(401, 'Sessione non attiva', 'MioIdRuolo IS NULL', NULL);
      pCursor := NULL;
      RETURN;
    END IF;

    SELF.BuildWhere('U', vWhere);
    IF SELF.Esito.StatusCode <> 200 THEN
      pCursor := NULL;
      RETURN;
    END IF;

    vSql :=
      'SELECT U.Id_Utente, U.Login, U.Cognome, U.Nome, U.Email, U.Attivo' ||
      ' FROM UTENTI U';
    IF vWhere IS NOT NULL THEN
      vSql := vSql || ' WHERE ' || vWhere;
    END IF;
    vSql := vSql || ' ORDER BY U.Cognome, U.Nome';

    OPEN pCursor FOR vSql;
    SELF.Esito := OBJ_Esito.Imposta(200, 'Ricerca completata', NULL, NULL);

  EXCEPTION
    WHEN OTHERS THEN
      SELF.Esito := OBJ_Esito.Imposta(500, 'Cerca non riuscita per errore interno', SQLERRM, SQLERRM);
      pCursor := NULL;
  END Cerca;
  --------------------------------------------------------------------------

END;
----------------------------------------------------------------------------
