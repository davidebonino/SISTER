----------------------------------------------------------------------------
-- Condizioni di profilazione
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Condizioni AS OBJECT (
  Condizioni      CLOB,
  CONSTRUCTOR FUNCTION OBJ_Condizioni RETURN SELF AS RESULT,
  MEMBER PROCEDURE Aggiungi(NomeCampo VARCHAR2, Tipo VARCHAR2, Condizione VARCHAR2, Valore VARCHAR2),
  MEMBER FUNCTION Info RETURN VARCHAR2,
  MEMBER FUNCTION Mostra RETURN VARCHAR2
);
----------------------------------------------------------------------------


CREATE OR REPLACE TYPE BODY OBJ_Condizioni AS

  -- Costruttore
  CONSTRUCTOR FUNCTION OBJ_Condizioni RETURN SELF AS RESULT
  IS
  BEGIN
    SELF.Condizioni := '{}';
    RETURN;
  END;
----------------------------------------------------------------------------


  -- Informazioni sull'oggetto
  MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'CONDIZIONI';
  END;
  ----------------------------------------------------------------------------


  -- Mostra le condizioni
  MEMBER FUNCTION Mostra RETURN VARCHAR2 IS
  BEGIN
    RETURN SELF.Condizioni;
  END;
  ----------------------------------------------------------------------------


  MEMBER PROCEDURE Aggiungi(NomeCampo VARCHAR2, Tipo VARCHAR2, Condizione VARCHAR2, Valore VARCHAR2) IS
  vJsonObj JSON_OBJECT_T;
  vJson    JSON_OBJECT_T;
  BEGIN
    vJsonObj := JSON_OBJECT_T.parse(SELF.Condizioni);
    vJson := JSON_OBJECT_T();
    vJson.put('TIPO', Tipo);
    vJson.put('CONDIZIONE', Condizione);
    vJson.put('VALORE', Valore);
    vJsonObj.put(NomeCampo, vJson);
    Condizioni := vJsonObj.to_clob;
  END Aggiungi;
  ---------------------------------------------------------------------------
  
END;