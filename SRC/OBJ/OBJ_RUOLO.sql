----------------------------------------------------------------------------
--  Ruolo
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Ruolo UNDER OBJ_Profilatore (
  IdRuolo             NUMBER,
  Descrizione         VARCHAR2(100),
  DataInizioValidita  DATE,
  DataFineValidita    DATE,
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,
  STATIC FUNCTION Carica(pIdRuolo IN NUMBER) RETURN OBJ_Ruolo,
  CONSTRUCTOR FUNCTION OBJ_Ruolo RETURN SELF AS RESULT

);
----------------------------------------------------------------------------


CREATE OR REPLACE TYPE BODY OBJ_Ruolo AS

  -- Costruttore
  CONSTRUCTOR FUNCTION OBJ_Ruolo RETURN SELF AS RESULT
  IS
  BEGIN
    SELF.IdRuolo := NULL;
    SELF.Descrizione := NULL;
    SELF.DataInizioValidita := NULL;
    SELF.DataFineValidita := NULL;
    RETURN;
  END;


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'RUOLO';
  END Info;
  --------------------------------------------------------------------------


  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE UPPER(pSinonimo)
      WHEN 'ID_RUOLO'             THEN 'ID_RUOLO|N'
      WHEN 'DESCRIZIONE'          THEN 'DESCRIZIONE|V'
      WHEN 'DATA_INIZIO_VALIDITA' THEN 'DATA_INIZIO_VALIDITA|D'
      WHEN 'DATA_FINE_VALIDITA'   THEN 'DATA_FINE_VALIDITA|D'
      ELSE NULL
    END;
  END RisolviSinonimo;
  --------------------------------------------------------------------------


  -- Carica il privilegio
  STATIC FUNCTION Carica(pIdRuolo IN NUMBER) RETURN OBJ_Ruolo IS
    vRuolo OBJ_Ruolo;
  BEGIN
    vRuolo := OBJ_Ruolo();

    SELECT ID_RUOLO
         , DESCRIZIONE
         , DATA_INIZIO_VALIDITA
         , DATA_FINE_VALIDITA
      INTO vRuolo.IdRuolo,
           vRuolo.Descrizione,
           vRuolo.DataInizioValidita,
           vRuolo.DataFineValidita
      FROM TAB_RUOLI RU
       WHERE RU.ID_RUOLO  = pIdRuolo;

     IF vRuolo.IdRuolo IS NOT NULL THEN
       vRuolo.Esito := OBJ_Esito.Imposta(200, 'Ruolo caricato con successo', NULL, NULL);
       RETURN vRuolo;
     ELSE
       vRuolo.Esito := OBJ_Esito.Imposta(204, 'Ruolo non trovato', 'Ruolo non trovato per i parametri forniti', NULL);
       RETURN vRuolo;
     END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Ruolo non trovato
      vRuolo.Esito := OBJ_Esito.Imposta(204, 'Ruolo non trovato, parametri errati', 'Ruolo non trovato, parametri errati' || SQLERRM, SQLERRM);
      RETURN vRuolo;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vRuolo.Esito := OBJ_Esito.Imposta(500, 'Ruolo non trovato per errore interno', 'Ruolo non trovato per errore interno' || SQLERRM, SQLERRM);
      RETURN vRuolo;
  END Carica;
  --------------------------------------------------------------------------

END;
