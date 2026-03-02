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


  -- Escape degli apici in una stringa (converte i doppi apici in modo che siano presenti all'interno di una stringa)
  MEMBER FUNCTION Esc(p VARCHAR2) RETURN VARCHAR2 IS
	  BEGIN
	    RETURN REPLACE(p, '''', '''''');
	  END Esc;


  -- Costruisce literal SQL per un valore secondo il tipo di dato presente nella stringa
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
				-- !!! La gestione dell'errore deve essere rivista, valutare se restituire l'oggetto OBJ_Esito
	      RAISE_APPLICATION_ERROR(-20021, 'Identificatore SQL non valido: '||pNome);
	  END ControllaNomeCampo;


  -- Split CSV per IN / NOT IN, suddivide una stringa in un array separando con il carattere ","
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

     Costruisce dinamicamente una clausola WHERE SQL leggendo i filtri
     di profilazione dal contesto applicativo Oracle (SESSION_CONTEXT).

     Ogni attributo presente nel namespace indicato viene tradotto in
     un predicato SQL sicuro (anti-injection) e concatenato con AND.

     Parametri:
       pNamespace  — nome del contesto Oracle da cui leggere i filtri
                     (es. 'CTX_APP_ABL'); corrisponde al namespace in
                     SESSION_CONTEXT e in ctx_column_map.
       pTabella    — nome fisico della tabella/vista su cui si applica
                     il filtro; usato per risolvere il nome colonna
                     reale tramite ctx_column_map.
       pAlias      — alias SQL della tabella nella query chiamante
                     (es. 'U'); se valorizzato, il predicato sarà
                     nella forma ALIAS.COLONNA; se NULL, solo COLONNA.

     Valore restituito:
       Stringa contenente i predicati SQL pronti per essere inseriti
       in una clausola WHERE, separati da AND.
       Restituisce NULL se non vi sono filtri attivi nel contesto.

     Formato del valore in SESSION_CONTEXT:
       Ogni attributo deve avere il formato:  valore|OPERATORE|TIPO
         valore   — il valore del filtro (può essere una lista CSV
                    per IN/NOT IN, o coppia "val1,val2" per BETWEEN)
         OPERATORE — uno degli operatori ammessi (vedi OperatoreValido)
         TIPO      — tipo SQL del dato: NUMBER, VARCHAR2, DATE
       Esempio: '10,20|BETWEEN|NUMBER'  →  COLONNA BETWEEN 10 AND 20
                'MARIO|LIKE|VARCHAR2'   →  COLONNA LIKE 'MARIO'
                '|IS NULL|'             →  COLONNA IS NULL
     --------------------------------------------------------------- */
  MEMBER FUNCTION BuildWhere(
    pNamespace IN VARCHAR2,
    pTabella   IN VARCHAR2,
    pAlias     IN VARCHAR2
  ) RETURN VARCHAR2 IS

    vWhere   VARCHAR2(32767);  -- clausola WHERE accumulata (predicati separati da AND)
    vRaw     VARCHAR2(4000);   -- valore grezzo letto dal contesto: "valore|OPERATORE|TIPO"
    vVal     VARCHAR2(4000);   -- parte "valore" estratta da vRaw
    vOp      VARCHAR2(50);     -- parte "OPERATORE" estratta da vRaw (es. '=', 'IN', 'BETWEEN')
    vType    VARCHAR2(50);     -- parte "TIPO" estratta da vRaw (es. 'NUMBER', 'DATE')
    pos1     INT;              -- posizione del primo separatore '|' in vRaw
    pos2     INT;              -- posizione del secondo separatore '|' in vRaw
    vColReal VARCHAR2(128);    -- nome fisico della colonna risolto tramite ctx_column_map
    vColFull VARCHAR2(200);    -- nome colonna qualificato con alias (es. 'U.COGNOME')
    vOps     SYS.ODCIVARCHAR2LIST := OperatoreValido();   -- lista operatori ammessi
    vTypes   SYS.ODCIVARCHAR2LIST := TipoDatoValido();    -- lista tipi ammessi

	  BEGIN

      /* -------------------------------------------------------------------
         FASE 1 — Iterazione sugli attributi del contesto applicativo
         Per ogni coppia (attribute, value) presente nel namespace Oracle
         indicato da pNamespace si costruisce un predicato SQL.
         ------------------------------------------------------------------- */
	    FOR r IN (
	      SELECT attribute, value
	      FROM   SESSION_CONTEXT
	      WHERE  namespace = UPPER(TRIM(pNamespace))
	    ) LOOP

        /* -----------------------------------------------------------------
           FASE 2 — Risoluzione del nome colonna fisico
           L'attributo del contesto (es. 'ID_STRUTTURA') viene mappato al
           nome della colonna reale nella tabella di destinazione attraverso
           la tabella di configurazione ctx_column_map, filtrando per
           namespace, attributo e nome tabella.
           ----------------------------------------------------------------- */
	      SELECT column_name
	        INTO vColReal
	        FROM ctx_column_map
	       WHERE namespace  = UPPER(TRIM(pNamespace))
	         AND attribute  = r.attribute
	         AND table_name = UPPER(TRIM(pTabella));

        /* -----------------------------------------------------------------
           FASE 3 — Validazione anti-injection del nome colonna
           Il nome colonna è passato a DBMS_ASSERT.SIMPLE_SQL_NAME per
           garantire che sia un identificatore SQL valido e prevenire
           qualsiasi rischio di SQL injection.
           ----------------------------------------------------------------- */
	      vColReal := ControllaNomeCampo(vColReal);

        /* -----------------------------------------------------------------
           FASE 4 — Qualificazione del nome colonna con l'alias di tabella
           Se è stato fornito un alias (pAlias), anche questo viene
           validato prima di costruire il riferimento "ALIAS.COLONNA".
           In assenza di alias si usa il solo nome colonna.
           ----------------------------------------------------------------- */
	      IF pAlias IS NOT NULL THEN
	        vColFull := ControllaNomeCampo(pAlias) || '.' || vColReal;
	      ELSE
	        vColFull := vColReal;
	      END IF;

        /* -----------------------------------------------------------------
           FASE 5 — Lettura e parsing del valore grezzo dal contesto
           Il valore in SESSION_CONTEXT ha il formato: valore|OPERATORE|TIPO
           Si individuano le posizioni dei due separatori '|' per estrarre
           le tre componenti: valore, operatore e tipo di dato.
           Un valore NULL viene saltato (CONTINUE).
           ----------------------------------------------------------------- */
	      vRaw := r.value;
	      IF vRaw IS NULL THEN CONTINUE; END IF;

	      pos1 := INSTR(vRaw, '|', 1, 1);
	      pos2 := INSTR(vRaw, '|', 1, 2);

        -- Formato non valido: devono essere presenti esattamente due '|'
	      IF pos1 = 0 OR pos2 = 0 THEN
	        RAISE_APPLICATION_ERROR(-20002,
	          'Formato errato (atteso: valore|operatore|tipo). Attributo='||r.attribute);
	      END IF;

        -- Estrazione delle tre componenti dal valore grezzo
	      vVal  := SUBSTR(vRaw, 1, pos1 - 1);                           -- tutto prima del primo '|'
	      vOp   := UPPER(TRIM(SUBSTR(vRaw, pos1 + 1, pos2 - pos1 - 1))); -- tra i due '|'
	      vType := UPPER(TRIM(SUBSTR(vRaw, pos2 + 1)));                  -- tutto dopo il secondo '|'

        /* -----------------------------------------------------------------
           FASE 6 — Validazione dell'operatore e del tipo di dato
           L'operatore viene controllato rispetto alla lista ammessa.
           Per gli operatori che richiedono un valore (tutti tranne
           IS NULL e IS NOT NULL) si verifica anche che il tipo di dato
           sia valido e che il valore non sia vuoto.
           ----------------------------------------------------------------- */
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

        /* -----------------------------------------------------------------
           FASE 7 — Costruzione del predicato SQL in base all'operatore
           Per ogni operatore viene generato il frammento SQL corretto,
           convertendo il/i valore/i nel literal SQL sicuro tramite
           ConvertiDato() (che applica anche l'escape degli apici).

           Operatori semplici (=, <>, <, <=, >, >=, LIKE):
             → COLONNA OP 'literal'

           IN / NOT IN:
             → il valore CSV viene spezzato con split_csv() e ogni
               elemento convertito in un literal; si produce:
               COLONNA IN ('v1','v2','v3')

           BETWEEN:
             → il valore contiene due estremi separati da ',';
               si produce: COLONNA BETWEEN val1 AND val2

           IS NULL / IS NOT NULL:
             → nessun valore richiesto; predicato diretto sulla colonna
           ----------------------------------------------------------------- */
	      DECLARE
	        vPred  VARCHAR2(4000);         -- predicato SQL del singolo attributo
	        vList  SYS.ODCIVARCHAR2LIST;   -- lista valori per IN/NOT IN
	        leftv  VARCHAR2(4000);         -- estremo sinistro per BETWEEN
	        rightv VARCHAR2(4000);         -- estremo destro per BETWEEN
	        posc   INT;                    -- posizione del ',' in BETWEEN
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
	            -- Spezza la stringa CSV in array e costruisce la lista di valori tra parentesi
	            vList := split_csv(vVal);
	            vPred := vColFull||' IN (';
	            FOR i IN 1 .. vList.COUNT LOOP
	              IF i > 1 THEN vPred := vPred||','; END IF;
	              vPred := vPred||ConvertiDato(vType, vList(i));
	            END LOOP;
	            vPred := vPred||')';
	          WHEN 'NOT IN' THEN
	            -- Come IN ma con negazione
	            vList := split_csv(vVal);
	            vPred := vColFull||' NOT IN (';
	            FOR i IN 1 .. vList.COUNT LOOP
	              IF i > 1 THEN vPred := vPred||','; END IF;
	              vPred := vPred||ConvertiDato(vType, vList(i));
	            END LOOP;
	            vPred := vPred||')';
	          WHEN 'BETWEEN' THEN
	            -- Separa i due estremi sul primo ',' e costruisce il predicato BETWEEN ... AND ...
	            posc   := INSTR(vVal, ',');
	            leftv  := TRIM(SUBSTR(vVal, 1, posc - 1));
	            rightv := TRIM(SUBSTR(vVal, posc + 1));
	            vPred  := vColFull||' BETWEEN '||ConvertiDato(vType, leftv)||' AND '||ConvertiDato(vType, rightv);
	          WHEN 'IS NULL'     THEN vPred := vColFull||' IS NULL';
	          WHEN 'IS NOT NULL' THEN vPred := vColFull||' IS NOT NULL';
	        END CASE;

        /* -----------------------------------------------------------------
           FASE 8 — Accumulo del predicato nella clausola WHERE finale
           Il primo predicato viene assegnato direttamente a vWhere;
           i successivi vengono concatenati con l'operatore logico AND,
           in modo che la stringa risultante possa essere usata
           direttamente dopo la parola chiave WHERE nella query chiamante.
           ----------------------------------------------------------------- */
	        IF vWhere IS NULL THEN
	          vWhere := vPred;
	        ELSE
	          vWhere := vWhere||' AND '||vPred;
	        END IF;
	      END;

	    END LOOP;

    -- Restituzione della clausola WHERE completa (NULL se nessun filtro attivo)
	    RETURN vWhere;
	  END;

END;
