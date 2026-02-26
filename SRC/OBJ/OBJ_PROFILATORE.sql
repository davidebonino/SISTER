----------------------------------------------------------------------------
-- Profilatore
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Profilatore AS OBJECT (
  Esito           OBJ_Esito,         -- Esito dell'ultima operazione eseguita
  Condizioni      OBJ_Condizioni,    -- Condizioni di profilazione in formato JSON
  MEMBER FUNCTION Info RETURN VARCHAR2,
  STATIC FUNCTION MioIdProfilo RETURN NUMBER,
  STATIC FUNCTION MioIdRuolo RETURN NUMBER,
  STATIC FUNCTION MioIdSessione RETURN VARCHAR2,
  STATIC FUNCTION MioIdUtente RETURN NUMBER,
  MEMBER FUNCTION OperatoreValido RETURN SYS.ODCIVARCHAR2LIST,
  MEMBER FUNCTION TipoDatoValido RETURN SYS.ODCIVARCHAR2LIST,
  MEMBER FUNCTION InLista(pVal VARCHAR2, pLista SYS.ODCIVARCHAR2LIST) RETURN BOOLEAN,
  MEMBER FUNCTION Esc(p VARCHAR2) RETURN VARCHAR2,
  MEMBER FUNCTION ConvertiDato(pTipo VARCHAR2, pValore VARCHAR2) RETURN VARCHAR2,
  MEMBER FUNCTION ControllaNomeCampo(pNome VARCHAR2) RETURN VARCHAR2,
  MEMBER FUNCTION split_csv(pCsv VARCHAR2) RETURN SYS.ODCIVARCHAR2LIST,
  MEMBER FUNCTION BuildWhere(pNamespace IN VARCHAR2, pTabella IN VARCHAR2, pAlias IN VARCHAR2) RETURN VARCHAR2
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


  /* ---------------------------------------------------------------
     UTILITY INTERNE AL TYPE
     --------------------------------------------------------------- */

  -- Lista operatori consentiti
  MEMBER FUNCTION OperatoreValido RETURN SYS.ODCIVARCHAR2LIST IS
  BEGIN
    RETURN SYS.ODCIVARCHAR2LIST('=','<>','<','<=','>','>=','LIKE','IN','NOT IN','BETWEEN','IS NULL','IS NOT NULL');
  END OperatoreValido;


  -- Lista dei tipi di dato consentiti
  MEMBER FUNCTION TipoDatoValido RETURN SYS.ODCIVARCHAR2LIST IS
  BEGIN
    RETURN SYS.ODCIVARCHAR2LIST('NUMBER','VARCHAR2','DATE');
  END TipoDatoValido;


  -- Controlla se un valore è dentro una lista
  MEMBER FUNCTION InLista(pVal VARCHAR2, pLista SYS.ODCIVARCHAR2LIST) RETURN BOOLEAN IS
  BEGIN
    FOR i IN 1 .. pLista.COUNT LOOP
      IF pLista(i) = pVal THEN
        RETURN TRUE;
      END IF;
    END LOOP;
    RETURN FALSE;
  END InLista;


  -- Escape degli apici in una stringa
  MEMBER FUNCTION Esc(p VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN REPLACE(p, '''', '''''');
  END Esc;


  -- Costruisce literal SQL per un valore secondo tipo
  MEMBER FUNCTION ConvertiDato(pTipo VARCHAR2, pValore VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    CASE pTipo
      WHEN 'NUMBER'   THEN RETURN 'TO_NUMBER('''||Esc(pValore)||''')';
      WHEN 'DATE'     THEN RETURN 'TO_DATE('''||Esc(pValore)||''',''YYYY-MM-DD'')';
      WHEN 'VARCHAR2' THEN RETURN ''''||Esc(pValore)||'''';
      ELSE RAISE_APPLICATION_ERROR(-20020, 'Tipo non supportato: '||pTipo);
    END CASE;
  END ConvertiDato;


  -- Validazione nome SQL (evita injection)
  MEMBER FUNCTION ControllaNomeCampo(pNome VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(pNome)));
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20021, 'Identificatore SQL non valido: '||pNome);
  END ControllaNomeCampo;


  -- Split CSV per IN / NOT IN
  MEMBER FUNCTION split_csv(pCsv VARCHAR2) RETURN SYS.ODCIVARCHAR2LIST IS
    vList  SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST();
    vPos   INT;
    vStart INT := 1;
    vPiece VARCHAR2(4000);
    vStr   VARCHAR2(4000) := NVL(TRIM(pCsv), '');
  BEGIN
    IF vStr IS NULL OR vStr = '' THEN
      RETURN vList;
    END IF;
    LOOP
      vPos := INSTR(vStr, ',', vStart);
      IF vPos = 0 THEN
        vPiece := TRIM(SUBSTR(vStr, vStart));
        IF vPiece IS NOT NULL THEN
          vList.EXTEND;
          vList(vList.COUNT) := vPiece;
        END IF;
        EXIT;
      END IF;
      vPiece := TRIM(SUBSTR(vStr, vStart, vPos - vStart));
      vList.EXTEND;
      vList(vList.COUNT) := vPiece;
      vStart := vPos + 1;
    END LOOP;
    RETURN vList;
  END;


  /* ---------------------------------------------------------------
     METODO PRINCIPALE: BuildWhere()
     --------------------------------------------------------------- */
  MEMBER FUNCTION BuildWhere(
    pNamespace IN VARCHAR2,
    pTabella   IN VARCHAR2,
    pAlias     IN VARCHAR2
  ) RETURN VARCHAR2 IS

    vWhere   VARCHAR2(32767);
    vRaw     VARCHAR2(4000);
    vVal     VARCHAR2(4000);
    vOp      VARCHAR2(50);
    vType    VARCHAR2(50);
    pos1     INT;
    pos2     INT;
    vColReal VARCHAR2(128);
    vColFull VARCHAR2(200);
    vOps     SYS.ODCIVARCHAR2LIST := OperatoreValido();
    vTypes   SYS.ODCIVARCHAR2LIST := TipoDatoValido();

  BEGIN

    FOR r IN (
      SELECT attribute, value
      FROM   SESSION_CONTEXT
      WHERE  namespace = UPPER(TRIM(pNamespace))
    ) LOOP

      SELECT column_name
        INTO vColReal
        FROM ctx_column_map
       WHERE namespace  = UPPER(TRIM(pNamespace))
         AND attribute  = r.attribute
         AND table_name = UPPER(TRIM(pTabella));

      vColReal := ControllaNomeCampo(vColReal);

      IF pAlias IS NOT NULL THEN
        vColFull := ControllaNomeCampo(pAlias) || '.' || vColReal;
      ELSE
        vColFull := vColReal;
      END IF;

      vRaw := r.value;
      IF vRaw IS NULL THEN CONTINUE; END IF;

      pos1 := INSTR(vRaw, '|', 1, 1);
      pos2 := INSTR(vRaw, '|', 1, 2);

      IF pos1 = 0 OR pos2 = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
          'Formato errato (atteso: valore|operatore|tipo). Attributo='||r.attribute);
      END IF;

      vVal  := SUBSTR(vRaw, 1, pos1 - 1);
      vOp   := UPPER(TRIM(SUBSTR(vRaw, pos1 + 1, pos2 - pos1 - 1)));
      vType := UPPER(TRIM(SUBSTR(vRaw, pos2 + 1)));

      IF NOT InLista(vOp, vOps) THEN
        RAISE_APPLICATION_ERROR(-20003, 'Operatore non ammesso: '||vOp);
      END IF;

      IF vOp NOT IN ('IS NULL','IS NOT NULL') THEN
        IF NOT InLista(vType, vTypes) THEN
          RAISE_APPLICATION_ERROR(-20004, 'Tipo non ammesso: '||vType);
        END IF;
        IF TRIM(vVal) IS NULL THEN
          RAISE_APPLICATION_ERROR(-20005, 'Valore mancante per operatore '||vOp||'. Attributo='||r.attribute);
        END IF;
      END IF;

      DECLARE
        vPred  VARCHAR2(4000);
        vList  SYS.ODCIVARCHAR2LIST;
        leftv  VARCHAR2(4000);
        rightv VARCHAR2(4000);
        posc   INT;
      BEGIN
        CASE vOp
          WHEN '='          THEN vPred := vColFull||' = '   ||ConvertiDato(vType, TRIM(vVal));
          WHEN '<>'         THEN vPred := vColFull||' <> '  ||ConvertiDato(vType, TRIM(vVal));
          WHEN '<'          THEN vPred := vColFull||' < '   ||ConvertiDato(vType, TRIM(vVal));
          WHEN '<='         THEN vPred := vColFull||' <= '  ||ConvertiDato(vType, TRIM(vVal));
          WHEN '>'          THEN vPred := vColFull||' > '   ||ConvertiDato(vType, TRIM(vVal));
          WHEN '>='         THEN vPred := vColFull||' >= '  ||ConvertiDato(vType, TRIM(vVal));
          WHEN 'LIKE'       THEN vPred := vColFull||' LIKE ' ||ConvertiDato('VARCHAR2', vVal);
          WHEN 'IN' THEN
            vList := split_csv(vVal);
            vPred := vColFull||' IN (';
            FOR i IN 1 .. vList.COUNT LOOP
              IF i > 1 THEN vPred := vPred||','; END IF;
              vPred := vPred||ConvertiDato(vType, vList(i));
            END LOOP;
            vPred := vPred||')';
          WHEN 'NOT IN' THEN
            vList := split_csv(vVal);
            vPred := vColFull||' NOT IN (';
            FOR i IN 1 .. vList.COUNT LOOP
              IF i > 1 THEN vPred := vPred||','; END IF;
              vPred := vPred||ConvertiDato(vType, vList(i));
            END LOOP;
            vPred := vPred||')';
          WHEN 'BETWEEN' THEN
            posc   := INSTR(vVal, ',');
            leftv  := TRIM(SUBSTR(vVal, 1, posc - 1));
            rightv := TRIM(SUBSTR(vVal, posc + 1));
            vPred  := vColFull||' BETWEEN '||ConvertiDato(vType, leftv)||' AND '||ConvertiDato(vType, rightv);
          WHEN 'IS NULL'     THEN vPred := vColFull||' IS NULL';
          WHEN 'IS NOT NULL' THEN vPred := vColFull||' IS NOT NULL';
        END CASE;

        IF vWhere IS NULL THEN
          vWhere := vPred;
        ELSE
          vWhere := vWhere||' AND '||vPred;
        END IF;
      END;

    END LOOP;

    RETURN vWhere;
  END;

END;
