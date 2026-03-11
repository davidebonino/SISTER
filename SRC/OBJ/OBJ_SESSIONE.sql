----------------------------------------------------------------------------
-- OBJ_Sessione — Gestione dell'autenticazione e del ciclo di vita delle sessioni
--
-- SCOPO
--   Rappresenta una sessione utente attiva. La funzione Crea() esegue
--   l'autenticazione verificando username, password (hash MD5), profilo e
--   scadenza password; inserisce il record in TBL_SESSIONI e restituisce
--   l'oggetto sessione popolato.
--
-- CAMPI PRINCIPALI
--   IdSessione (RAW 16) — identificatore univoco di sessione generato da SYS_GUID()
--   IdProfilo  (NUMBER) — profilo utente selezionato al login
--   IdRuolo    (NUMBER) — ruolo applicativo associato al profilo
--   Stato      (CHAR 1) — 'A' = Attiva, altri valori per stati futuri
--   Data       (DATE)   — timestamp di creazione della sessione
--
-- NOTA SULLA SICUREZZA
--   La password e confrontata come STANDARD_HASH(pKeyword, 'MD5').
--   La query di autenticazione verifica anche ATTIVO='S' (utente e profilo)
--   e DATA_SCADENZA_PASSWORD >= SYSDATE per garantire la validita.
--   Il metodo Crea esegue COMMIT dopo l'inserimento in TBL_SESSIONI.
--
-- DIPENDENZE
--   UNDER OBJ_Profilatore — eredita il campo Esito e i metodi statici
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Sessione UNDER OBJ_Profilatore (
  IdSessione RAW(16),
  IdProfilo  NUMBER,
  IdRuolo    NUMBER,
  Stato      CHAR(1),
  Data       DATE,
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,
  STATIC FUNCTION Crea(pUsername IN VARCHAR2, pKeyword IN VARCHAR2, pIdProfilo IN NUMBER) RETURN OBJ_Sessione,
  STATIC FUNCTION Carica(pIdSessione VARCHAR2) RETURN OBJ_Sessione,
  CONSTRUCTOR FUNCTION OBJ_Sessione RETURN SELF AS RESULT
);
----------------------------------------------------------------------------


CREATE OR REPLACE TYPE BODY OBJ_Sessione AS


  -- Costruttore
  CONSTRUCTOR FUNCTION OBJ_Sessione RETURN SELF AS RESULT
  IS
  BEGIN
    SELF.IdSessione := NULL;
    SELF.IdProfilo := NULL;
    SELF.IdRuolo   := NULL;
    SELF.Stato     := NULL;
    SELF.Data      := NULL;
    RETURN;
  END;


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SESSIONE';
  END Info;
  --------------------------------------------------------------------------


  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE UPPER(pSinonimo)
      WHEN 'ID_SESSIONE' THEN 'ID_SESSIONE|V'
      WHEN 'ID_PROFILO'  THEN 'ID_PROFILO|N'
      WHEN 'ID_RUOLO'    THEN 'ID_RUOLO|N'
      WHEN 'STATO'       THEN 'STATO|V'
      WHEN 'DATA'        THEN 'DATA|D'
      ELSE NULL
    END;
  END RisolviSinonimo;
  --------------------------------------------------------------------------


  -- Crea una nuova sessione autenticata.
  -- Sequenza di operazioni:
  --   1. Verifica credenziali: JOIN UTENTI-PROFILI con filtri ATTIVO, hash MD5,
  --      scadenza password e ID_PROFILO. ROWNUM=1 per sicurezza.
  --   2. Se le credenziali sono valide (IdRuolo > 0):
  --      - genera IdSessione con SYS_GUID()
  --      - inserisce in TBL_SESSIONI
  --      - esegue COMMIT
  --      - restituisce la sessione con Esito 201 (Created)
  --   3. In caso di NO_DATA_FOUND: Esito 401 (credenziali errate)
  --   4. In caso di altri errori: Esito 500 (errore interno)
  --
  -- Parametri:
  --   pUsername  — login utente (confronto case-insensitive)
  --   pKeyword   — password in chiaro (viene hashata internamente con MD5)
  --   pIdProfilo — ID del profilo selezionato dal client al momento del login
  STATIC FUNCTION Crea(pUsername IN VARCHAR2, pKeyword IN VARCHAR2, pIdProfilo IN NUMBER) RETURN OBJ_Sessione IS
    vIdRuolo NUMBER;
    vSessione OBJ_Sessione;
  BEGIN
    vSessione := OBJ_Sessione();

    -- Verifica delle credenziali: JOIN tra UTENTI e PROFILI per recuperare il ruolo
    -- associato al profilo. Hash MD5 della password confrontato con PASSWORD_0.
    SELECT ID_RUOLO
      INTO vIdRuolo
      FROM UTENTI U
         , PROFILI P
    WHERE U.ID_UTENTE  = P.ID_UTENTE
      AND U.ATTIVO     = 'S'
      AND P.ATTIVO     = 'S'
      AND UPPER(U.LOGIN)      = UPPER(pUsername)
      AND UPPER(U.PASSWORD_0) = STANDARD_HASH(pKeyword, 'MD5')
      AND P.ID_PROFILO = TO_NUMBER(pIdProfilo)
      AND U.DATA_SCADENZA_PASSWORD >= SYSDATE
      AND ROWNUM = 1;

    IF vIdRuolo > 0 THEN
      vSessione.IdSessione := SYS_GUID();
      vSessione.IdProfilo := pIdProfilo;
      vSessione.IdRuolo   := vIdRuolo;
      vSessione.Stato     := 'A';
      vSessione.Data      := SYSDATE;
      INSERT INTO TBL_SESSIONI VALUES (vSessione.IdSessione, vSessione.IdProfilo, vSessione.IdRuolo, vSessione.Stato, vSessione.Data);
      COMMIT;

      vSessione.Esito := OBJ_Esito.Imposta(201, 'Sessione creata con successo', NULL, NULL);
      RETURN vSessione;
    ELSE
      vSessione.Esito := OBJ_Esito.Imposta(401, 'Autenticazione non riuscita, IdRuolo non valido', 'IdRuolo non valido: ' || vIdRuolo, NULL);
      RETURN vSessione;
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Autenticazione non riuscita
      vSessione.Esito := OBJ_Esito.Imposta(401, 'Autenticazione non riuscita, parametri errati', 'Autenticazione non riuscita, parametri errati' || SQLERRM, SQLERRM);
      RETURN vSessione;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vSessione.Esito := OBJ_Esito.Imposta(500, 'Autenticazione non riuscita per errore interno', 'Autenticazione non riuscita per errore interno' || SQLERRM, SQLERRM);
      RETURN vSessione;
  END Crea;
  --------------------------------------------------------------------------


  -- Carica la sessione
  STATIC FUNCTION Carica(pIdSessione VARCHAR2) RETURN OBJ_Sessione IS
    vSessione OBJ_Sessione;
  BEGIN
    vSessione := OBJ_Sessione();

    SELECT ID_SESSIONE,
           ID_PROFILO,
           ID_RUOLO,
           STATO,
           DATA
      INTO vSessione.IdSessione,
           vSessione.IdProfilo,
           vSessione.IdRuolo,
           vSessione.Stato,
           vSessione.Data
      FROM TBL_SESSIONI
     WHERE ID_SESSIONE = pIdSessione;

     IF vSessione.IdSessione IS NOT NULL THEN
       vSessione.Esito := OBJ_Esito.Imposta(200, 'Sessione caricata con successo', NULL, NULL);
       RETURN vSessione;
     ELSE
       vSessione.Esito := OBJ_Esito.Imposta(204, 'Sessione non trovata2', 'Sessione non trovata per IdSessione: ' || pIdSessione, NULL);
       RETURN vSessione;
     END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Sessione non trovata
      vSessione.Esito := OBJ_Esito.Imposta(204, 'Sessione non trovata, parametri errati', 'Sessione non trovata, parametri errati' || SQLERRM, SQLERRM);
      RETURN vSessione;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vSessione.Esito := OBJ_Esito.Imposta(500, 'Sessione non trovata per errore interno', 'Sessione non trovata per errore interno' || SQLERRM, SQLERRM);
      RETURN vSessione;
  END Carica;
  --------------------------------------------------------------------------

END;
