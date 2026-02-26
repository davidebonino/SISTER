----------------------------------------------------------------------------
--  Sessione
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Sessione UNDER OBJ_Profilatore (
  IdSessione RAW(16),
  IdProfilo  NUMBER,
  IdRuolo    NUMBER, 
  Stato      CHAR(1),
  Data       DATE,
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
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
    SELF.Condizioni := OBJ_Condizioni();
    RETURN;
  END;


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'SESSIONE';
  END Info;
  --------------------------------------------------------------------------


  -- Autenticazione e creazione sessione
  STATIC FUNCTION Crea(pUsername IN VARCHAR2, pKeyword IN VARCHAR2, pIdProfilo IN NUMBER) RETURN OBJ_Sessione IS
    vIdRuolo NUMBER;
    vSessione OBJ_Sessione;
  BEGIN
    vSessione := OBJ_Sessione();
    
    -- Verifica delle credenziali 
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
      PKG_APP.gSessione := vSessione;
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