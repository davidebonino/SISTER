----------------------------------------------------------------------------
-- OBJ_Profilatore — Tipo Oracle base per la gerarchia degli oggetti SISTER
--
-- SCOPO
--   Superclasse NOT INSTANTIABLE NOT FINAL da cui ereditano tutti i tipi
--   dell'applicazione (OBJ_Utente, OBJ_Sessione, OBJ_Profilo, ecc.).
--   Fornisce il campo condiviso Esito (OBJ_Esito), le funzioni statiche di
--   accesso all'Application Context (MioIdUtente, MioIdRuolo, ecc.) e
--   il metodo di costruzione dinamica delle clausole WHERE (BuildWhere).
--
-- METODO ASTRATTO
--   RisolviSinonimo(pSinonimo) — MUST OVERRIDE in ogni sottotipo:
--   traduce un nome logico di attributo (es. 'COGNOME') nella coppia
--   COLONNA|TIPO usata da BuildWhere (es. 'COGNOME|V').
--   Restituisce NULL se il sinonimo non e mappato.
--
-- PATTERN DI UTILIZZO
--   -- Lettura identita di sessione (senza istanziare l'oggetto):
--   vIdUtente := OBJ_Profilatore.MioIdUtente();
--   vIdRuolo  := OBJ_Profilatore.MioIdRuolo();
--
--   -- Costruzione clausola WHERE filtrata:
--   vOggetto := OBJ_Utente();
--   vOggetto.BuildWhere('U', vWhere);
--   -- vWhere contiene: "U.COGNOME LIKE 'B%' AND U.ATTIVO = 'S'"
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Profilatore AS OBJECT (
  Esito           OBJ_Esito,         -- Esito dell'ultima operazione eseguita
  MEMBER FUNCTION Info RETURN VARCHAR2,
  STATIC FUNCTION MioIdProfilo RETURN NUMBER,
  STATIC FUNCTION MioIdRuolo RETURN NUMBER,
  STATIC FUNCTION MioIdSessione RETURN VARCHAR2,
  STATIC FUNCTION MioIdUtente RETURN NUMBER,
  NOT INSTANTIABLE MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,
  -- Costruisce la clausola WHERE da CTX_APP_ABL (autorizzazioni) e CTX_APP_FLT (filtri).
  -- pAlias: alias tabella per qualificare le colonne (es. 'U' → 'U.COGNOME'); NULL = nessuna qualifica.
  -- pWhere: clausola WHERE senza la parola chiave WHERE, pronta per concatenazione.
  -- SELF.Esito: 200 = OK, 200+DebugInfo = OK con avvisi (FLT allarga visibilità),
  --             400 = sinonimo non riconosciuto, 500 = errore interno.
  MEMBER PROCEDURE BuildWhere(pAlias IN VARCHAR2 DEFAULT NULL, pWhere OUT VARCHAR2)
) NOT INSTANTIABLE NOT FINAL;

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

  -- Costruisce la clausola WHERE combinando CTX_APP_ABL e CTX_APP_FLT.
  -- Ogni attributo dei contesti è risolto via SELF.RisolviSinonimo: NULL → errore 400 immediato.
  -- Merging ABL+FLT sullo stesso campo con operatore =: unione valori (IN clause).
  -- Se FLT aggiunge valori non presenti in ABL: esito 200 con avviso in DebugInfo.
  MEMBER PROCEDURE BuildWhere(pAlias IN VARCHAR2 DEFAULT NULL, pWhere OUT VARCHAR2) IS
    vSep       VARCHAR2(5)    := '';
    vAttr      VARCHAR2(128);
    vRisolto   VARCHAR2(256);
    vColonna   VARCHAR2(128);
    vTipo      VARCHAR2(1);
    vCampo     VARCHAR2(256);
    vValAbl    VARCHAR2(4000);
    vValFlt    VARCHAR2(4000);
    vValoriAbl VARCHAR2(3900);
    vValoriFlt VARCHAR2(3900);
    vOpAbl     VARCHAR2(10);
    vOpFlt     VARCHAR2(10);
    vPred      VARCHAR2(4000);
    vWarnings  VARCHAR2(4000) := '';

    -- FormatVal: formatta un singolo valore scalare per inclusione sicura in SQL.
    -- Tipi supportati:
    --   'N' (NUMBER)  — valida con TO_NUMBER per prevenire SQL injection; restituisce il valore numerico
    --   'D' (DATE)    — valida con TO_DATE(YYYY-MM-DD); avvolge in TO_DATE(...)
    --   'V' (VARCHAR) — escapa gli apici singoli raddoppiandoli; avvolge in apici
    -- Nota: la validazione di N e D solleva eccezione in caso di formato errato;
    --       il chiamante (BuildWhere) intercetta WHEN OTHERS → esito 500.
    FUNCTION FormatVal(pVal IN VARCHAR2, pTipo IN VARCHAR2) RETURN VARCHAR2 IS
      vN NUMBER;
      vD DATE;
	    BEGIN
	      IF pTipo = 'N' THEN
	        vN := TO_NUMBER(TRIM(pVal));
	        RETURN TRIM(pVal);
	      ELSIF pTipo = 'D' THEN
	        vD := TO_DATE(TRIM(pVal), 'YYYY-MM-DD');
	        RETURN 'TO_DATE(''' || TRIM(pVal) || ''',''YYYY-MM-DD'')';
	      ELSE
	        RETURN '''' || REPLACE(TRIM(pVal), '''', '''''') || '''';
	      END IF;
	    END FormatVal;

    -- Predicato: costruisce il frammento SQL per un singolo campo.
    -- Operatori supportati:
    --   =  <  <=  >  >=  <>  LIKE  BETWEEN  NULL  NOTNULL
    -- Comportamento speciale:
    --   NULL/NOTNULL: ignora pValori, genera "campo IS [NOT] NULL"
    --   BETWEEN:      attende due valori semicolon-separated (es. "100;500")
    --   = con N valori: genera clausola IN  (es. "campo IN (1,2,3)")
    -- Esempio:
    --   Predicato('U.COGNOME', 'V', 'Rossi;Bianchi', '=') → "U.COGNOME IN ('Rossi','Bianchi')"
    --   Predicato('U.DATA', 'D', '2024-01-01;2024-12-31', 'BETWEEN') → "U.DATA BETWEEN TO_DATE(...) AND TO_DATE(...)"
    FUNCTION Predicato(pCampo IN VARCHAR2, pTipo IN VARCHAR2, pValori IN VARCHAR2, pOp IN VARCHAR2) RETURN VARCHAR2 IS
      vCount  NUMBER;
      vVal    VARCHAR2(500);
      vInList VARCHAR2(3000);
      vSepIn  VARCHAR2(1) := '';
	    BEGIN
	      IF pOp IN ('NULL', 'NOTNULL') THEN
	        RETURN pCampo || CASE pOp WHEN 'NULL' THEN ' IS NULL' ELSE ' IS NOT NULL' END;
	      END IF;
	      IF pOp = 'BETWEEN' THEN
	        RETURN pCampo || ' BETWEEN ' ||
	               FormatVal(REGEXP_SUBSTR(pValori, '[^;]+', 1, 1), pTipo) ||
	               ' AND ' ||
	               FormatVal(REGEXP_SUBSTR(pValori, '[^;]+', 1, 2), pTipo);
	      END IF;
	      vCount := REGEXP_COUNT(pValori, ';') + 1;
	      IF vCount = 1 THEN
	        RETURN pCampo || ' ' || pOp || ' ' || FormatVal(pValori, pTipo);
	      END IF;
	      FOR i IN 1..vCount LOOP
	        vVal    := TRIM(REGEXP_SUBSTR(pValori, '[^;]+', 1, i));
	        vInList := vInList || vSepIn || FormatVal(vVal, pTipo);
	        vSepIn  := ',';
	      END LOOP;
	      RETURN pCampo || ' IN (' || vInList || ')';
	    END Predicato;

    -- UnisciValori: unisce due liste di valori semicolon-separated eliminando i duplicati.
    -- Utilizzata nel merging ABL+FLT con operatore = per costruire la clausola IN
    -- senza ripetizioni.
    -- Esempio: UnisciValori('S;A', 'S;B') → 'S;A;B'
    FUNCTION UnisciValori(pA IN VARCHAR2, pB IN VARCHAR2) RETURN VARCHAR2 IS
      vResult VARCHAR2(4000) := pA;
      vCount  NUMBER;
      vVal    VARCHAR2(500);
	    BEGIN
	      vCount := REGEXP_COUNT(pB, ';') + 1;
	      FOR i IN 1..vCount LOOP
	        vVal := TRIM(REGEXP_SUBSTR(pB, '[^;]+', 1, i));
	        IF vVal IS NOT NULL AND INSTR(';' || vResult || ';', ';' || vVal || ';') = 0 THEN
	          vResult := vResult || ';' || vVal;
	        END IF;
	      END LOOP;
	      RETURN vResult;
	    END UnisciValori;

    -- HaNuoviValori: verifica se la lista pB introduce valori non presenti in pA.
    -- Usata per rilevare quando CTX_APP_FLT "allarga la visibilita" rispetto a CTX_APP_ABL:
    -- in quel caso BuildWhere imposta DebugInfo con l'avviso sugli attributi coinvolti.
    -- Esempio: HaNuoviValori('S', 'N') → TRUE  (FLT aggiunge il valore 'N')
    --          HaNuoviValori('S;N', 'S') → FALSE (tutti i valori FLT gia presenti in ABL)
    FUNCTION HaNuoviValori(pA IN VARCHAR2, pB IN VARCHAR2) RETURN BOOLEAN IS
      vCount NUMBER;
      vVal   VARCHAR2(500);
	    BEGIN
	      vCount := REGEXP_COUNT(pB, ';') + 1;
	      FOR i IN 1..vCount LOOP
	        vVal := TRIM(REGEXP_SUBSTR(pB, '[^;]+', 1, i));
	        IF vVal IS NOT NULL AND INSTR(';' || pA || ';', ';' || vVal || ';') = 0 THEN
	          RETURN TRUE;
	        END IF;
	      END LOOP;
	      RETURN FALSE;
	    END HaNuoviValori;

	  BEGIN
	    pWhere := '';

	    -- Ciclo su Abilitazioni e Filtri
			FOR vRec IN (
	      SELECT DISTINCT attribute
	        FROM SESSION_CONTEXT
	       WHERE namespace IN ('CTX_APP_ABL', 'CTX_APP_FLT')
	       ORDER BY attribute
	    ) LOOP
	      vAttr := vRec.attribute;

	      -- Risoluzione sinonimo → COLONNA|TIPO
	      vRisolto := SELF.RisolviSinonimo(vAttr);
	      IF vRisolto IS NULL THEN
	        SELF.Esito := OBJ_Esito.Imposta(
	          400,
	          'BuildWhere: sinonimo non riconosciuto',
	          'Il sinonimo "' || vAttr || '" non è mappato per ' || SELF.Info(),
	          'OBJ_Profilatore.BuildWhere'
	        );
	        pWhere := NULL;
	        RETURN;
	      END IF;

	      vColonna := SUBSTR(vRisolto, 1, INSTR(vRisolto, '|') - 1);
	      vTipo    := SUBSTR(vRisolto, INSTR(vRisolto, '|') + 1);
	      vCampo   := CASE WHEN pAlias IS NOT NULL THEN pAlias || '.' ELSE '' END || vColonna;

	      -- Lettura valori dai contesti
	      vValAbl    := SYS_CONTEXT('CTX_APP_ABL', vAttr);
	      vValFlt    := SYS_CONTEXT('CTX_APP_FLT', vAttr);
	      vValoriAbl := NULL; vOpAbl := NULL;
	      vValoriFlt := NULL; vOpFlt := NULL;

	      -- Parsing VALORI|OPERATORE (separatore: ultimo '|')
	      IF vValAbl IS NOT NULL THEN
	        vOpAbl     := SUBSTR(vValAbl, INSTR(vValAbl, '|', -1) + 1);
	        vValoriAbl := SUBSTR(vValAbl, 1, INSTR(vValAbl, '|', -1) - 1);
	      END IF;
	      IF vValFlt IS NOT NULL THEN
	        vOpFlt     := SUBSTR(vValFlt, INSTR(vValFlt, '|', -1) + 1);
	        vValoriFlt := SUBSTR(vValFlt, 1, INSTR(vValFlt, '|', -1) - 1);
	      END IF;

	      -- Merging e costruzione predicato
	      IF vValAbl IS NOT NULL AND vValFlt IS NOT NULL THEN
	        IF vOpAbl = '=' AND vOpFlt = '=' THEN
	          -- Stesso operatore =: unione valori con eventuale avviso
	          IF HaNuoviValori(vValoriAbl, vValoriFlt) THEN
	            vWarnings := vWarnings || vAttr || ' ';
	          END IF;
	          vPred := Predicato(vCampo, vTipo, UnisciValori(vValoriAbl, vValoriFlt), '=');
	        ELSE
	          -- Operatori diversi o non-=: entrambe le condizioni in AND
	          vPred := Predicato(vCampo, vTipo, vValoriAbl, vOpAbl) ||
	                   ' AND ' ||
	                   Predicato(vCampo, vTipo, vValoriFlt, vOpFlt);
	        END IF;
	      ELSIF vValAbl IS NOT NULL THEN
	        vPred := Predicato(vCampo, vTipo, vValoriAbl, vOpAbl);
	      ELSE
	        vPred := Predicato(vCampo, vTipo, vValoriFlt, vOpFlt);
	      END IF;

	      pWhere := pWhere || vSep || vPred;
	      vSep   := ' AND ';
	    END LOOP;

	    IF vWarnings IS NOT NULL THEN
	      SELF.Esito := OBJ_Esito.Imposta(200,
	        'BuildWhere completata con avvisi',
	        'FLT allarga visibilità per: ' || TRIM(vWarnings),
	        NULL);
	    ELSE
	      SELF.Esito := OBJ_Esito.Imposta(200, 'BuildWhere completata', NULL, NULL);
	    END IF;

	  EXCEPTION
	    WHEN OTHERS THEN
	      SELF.Esito := OBJ_Esito.Imposta(500,
	        'BuildWhere non riuscita per errore interno',
	        SQLERRM, SQLERRM);
	      pWhere := NULL;
	  END BuildWhere;

END;
