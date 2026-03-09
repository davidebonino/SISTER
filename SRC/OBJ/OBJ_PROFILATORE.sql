----------------------------------------------------------------------------
-- Profilatore
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Profilatore AS OBJECT (
  Esito           OBJ_Esito,         -- Esito dell'ultima operazione eseguita
  MEMBER FUNCTION Info RETURN VARCHAR2,
  STATIC FUNCTION MioIdProfilo RETURN NUMBER,
  STATIC FUNCTION MioIdRuolo RETURN NUMBER,
  STATIC FUNCTION MioIdSessione RETURN VARCHAR2,
  STATIC FUNCTION MioIdUtente RETURN NUMBER
) NOT FINAL;

----------------------------------------------------------------------------

CREATE OR REPLACE TYPE BODY OBJ_Profilatore AS

  -- Informazioni sull'oggetto
  MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PROFILATORE';
  END Info;


  -- IdProfilo della sessione corrente — letto da Application Context
  STATIC FUNCTION MioIdProfilo RETURN NUMBER IS
  BEGIN
    RETURN TO_NUMBER(SYS_CONTEXT('CTX_APP_IDS', 'ID_PROFILO'));
  END MioIdProfilo;


  -- IdRuolo della sessione corrente — letto da Application Context
  STATIC FUNCTION MioIdRuolo RETURN NUMBER IS
  BEGIN
    RETURN TO_NUMBER(SYS_CONTEXT('CTX_APP_IDS', 'ID_RUOLO'));
  END MioIdRuolo;


  -- IdSessione della sessione corrente — letto da Application Context
  STATIC FUNCTION MioIdSessione RETURN VARCHAR2 IS
  BEGIN
    RETURN SYS_CONTEXT('CTX_APP_IDS', 'ID_SESSIONE');
  END MioIdSessione;


  -- IdUtente della sessione corrente — letto da Application Context
  STATIC FUNCTION MioIdUtente RETURN NUMBER IS
  BEGIN
    RETURN TO_NUMBER(SYS_CONTEXT('CTX_APP_IDS', 'ID_UTENTE'));
  END MioIdUtente;

END;
