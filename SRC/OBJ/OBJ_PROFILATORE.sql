----------------------------------------------------------------------------
-- OBJ_Profilatore - Tipo Oracle base per la gerarchia degli oggetti SISTER
--
-- SCOPO
--   Superclasse NOT INSTANTIABLE NOT FINAL da cui ereditano tutti i tipi
--   dell'applicazione (OBJ_Utente, OBJ_Sessione, OBJ_Profilo, ecc.).
--   Fornisce il campo condiviso Esito (OBJ_Esito), le funzioni statiche di
--   accesso all'Application Context (MioIdUtente, MioIdRuolo, ecc.) e
--   il metodo di costruzione dinamica delle clausole WHERE (BuildWhere).
--
-- DIPENDENZE
--   OBJ_Esito - usato come tipo del campo Esito e come valore di ritorno
--               degli helper di costruzione dei predicati WHERE.
--   CTX_APP_IDS - Application Context contenente ID_SESSIONE, ID_UTENTE,
--                 ID_PROFILO, ID_RUOLO della sessione corrente.
--   CTX_APP_ABL - Application Context contenente i filtri di autorizzazione
--                 del profilo (es. ATTIVO=S|=).
--   CTX_APP_FLT - Application Context contenente i filtri di ricerca
--                 aggiuntivi impostati a runtime dal chiamante.
--   SESSION_CONTEXT - vista Oracle usata da BuildWhere per iterare
--                     sugli attributi dei due contesti ABL e FLT.
--
-- METODO ASTRATTO
--   RisolviSinonimo(pSinonimo) - MUST OVERRIDE in ogni sottotipo concreto:
--   traduce un nome logico di attributo (es. 'COGNOME') nella coppia
--   COLONNA|TIPO usata da BuildWhere (es. 'COGNOME|V').
--   Restituisce NULL se il sinonimo non è mappato per questo oggetto
--   (campo ignorato in modo non bloccante da BuildWhere).
--
-- FORMATO CONTESTO ABL/FLT
--   Ogni attributo nei contesti è memorizzato come: VALORI|OPERATORE
--   dove VALORI è una lista separata da ';' e OPERATORE è uno dei
--   token supportati da BuildWhere (=, <>, LIKE, BETWEEN, NULL, NOTNULL, ecc.).
--   Esempio: 'S;N|='   →  campo IN ('S','N')
--            'B%|LIKE' →  campo LIKE 'B%'
--
-- FORMATO RISPOSTA RisolviSinonimo
--   COLONNA|TIPO  - dove TIPO è: 'V' (VARCHAR), 'N' (NUMBER), 'D' (DATE)
--   Esempio: 'COGNOME|V', 'ID_UTENTE|N', 'DATA_INS|D'
--
-- PATTERN DI UTILIZZO
--   -- Lettura identità di sessione (senza istanziare l'oggetto):
--   vIdUtente := OBJ_Profilatore.MioIdUtente();
--   vIdRuolo  := OBJ_Profilatore.MioIdRuolo();
--
--   -- Costruzione clausola WHERE filtrata per un OBJ_Utente:
--   vOggetto := OBJ_Utente();
--   vOggetto.BuildWhere('U', vWhere);
--   -- vWhere → "U.COGNOME LIKE 'B%' AND U.ATTIVO IN ('S','N')"
--
--   -- Aggiunta WHERE a una query:
--   vSql := 'SELECT * FROM UTENTI U';
--   IF vWhere IS NOT NULL THEN
--     vSql := vSql || ' WHERE ' || vWhere;
--   END IF;
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Profilatore AS OBJECT (
  -- Campo condiviso da tutte le sottoclassi: contiene l'esito dell'ultima
  -- operazione eseguita sull'oggetto (StatusCode, Messaggio, Errori, DebugInfo).
  Esito           OBJ_Esito,

  -- Info(): restituisce il nome identificativo del tipo (es. 'PROFILATORE').
  -- Usato per logging e diagnostica; le sottoclassi devono fare override.
  MEMBER FUNCTION Info RETURN VARCHAR2,

  -- MioIdProfilo(): ID_PROFILO della sessione corrente da CTX_APP_IDS.
  -- Restituisce NULL se la sessione non è attiva.
  STATIC FUNCTION MioIdProfilo RETURN NUMBER,

  -- MioIdRuolo(): ID_RUOLO della sessione corrente da CTX_APP_IDS.
  -- Usato da Carica() per verificare se la sessione è inizializzata
  -- prima di eseguire query (alternativa leggera a VerificaAccesso).
  STATIC FUNCTION MioIdRuolo RETURN NUMBER,

  -- MioIdSessione(): ID_SESSIONE (GUID) della sessione corrente da CTX_APP_IDS.
  -- Restituisce NULL se la sessione non è attiva.
  STATIC FUNCTION MioIdSessione RETURN VARCHAR2,

  -- MioIdUtente(): ID_UTENTE della sessione corrente da CTX_APP_IDS.
  -- Restituisce NULL se la sessione non è attiva.
  STATIC FUNCTION MioIdUtente RETURN NUMBER,

  -- RisolviSinonimo(pSinonimo): METODO ASTRATTO - da implementare in ogni sottotipo.
  -- Traduce un nome logico di attributo nel formato 'COLONNA|TIPO' per BuildWhere.
  -- Restituisce NULL se l'attributo non appartiene a questo oggetto (non bloccante).
  -- Esempio implementazione in OBJ_Utente:
  --   IF pSinonimo = 'COGNOME' THEN RETURN 'COGNOME|V';
  --   IF pSinonimo = 'ATTIVO'  THEN RETURN 'ATTIVO|V';
  --   ELSE RETURN NULL;
  NOT INSTANTIABLE MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,

  -- BuildWhere(pAlias, pWhere): costruisce la clausola WHERE dinamica.
  --
  -- Parametri:
  --   pAlias (IN)  - alias della tabella per qualificare le colonne
  --                  (es. 'U' → 'U.COGNOME'); NULL = nessuna qualifica.
  --   pWhere (OUT) - clausola WHERE senza la parola chiave WHERE,
  --                  pronta per concatenazione diretta alla query SQL.
  --                  Stringa vuota se nessun filtro è applicabile.
  --
  -- Comportamento:
  --   1. Itera su tutti gli attributi presenti in CTX_APP_ABL e CTX_APP_FLT.
  --   2. Per ogni attributo chiama SELF.RisolviSinonimo(); se NULL → ignora.
  --   3. Se lo stesso attributo è presente in entrambi i contesti con op. '=':
  --      unisce i valori (IN clause). Se FLT aggiunge valori non in ABL →
  --      segnala l'allargamento della visibilità in DebugInfo (status 200).
  --   4. Se gli operatori sono diversi: entrambe le condizioni in AND.
  --
  -- SELF.Esito dopo la chiamata:
  --   200            - OK, clausola costruita senza avvisi
  --   200+DebugInfo  - OK con avvisi (sinonimi ignorati e/o FLT allarga ABL)
  --   500            - errore interno (es. valore non valido per tipo N o D)
  MEMBER PROCEDURE BuildWhere(pAlias IN VARCHAR2 DEFAULT NULL, pWhere OUT VARCHAR2)

) NOT INSTANTIABLE NOT FINAL;

----------------------------------------------------------------------------
-- CORPO DEL TIPO: implementazione dei metodi non astratti di OBJ_Profilatore
----------------------------------------------------------------------------

CREATE OR REPLACE TYPE BODY OBJ_Profilatore AS

  -- Restituisce il nome identificativo del tipo base.
  -- Le sottoclassi devono fare override per restituire il proprio nome
  -- (es. 'UTENTE', 'SESSIONE', 'PROFILO').
  MEMBER FUNCTION Info RETURN VARCHAR2 IS
	  BEGIN
	    RETURN 'PROFILATORE';
	  END Info;


  -- Legge ID_PROFILO dal contesto di sessione CTX_APP_IDS.
  -- Questo contesto è popolato da PKG_APP.Inizializza() durante il login.
  -- Restituisce NULL se la sessione non è ancora stata inizializzata.
  STATIC FUNCTION MioIdProfilo RETURN NUMBER IS
	  BEGIN
	    RETURN TO_NUMBER(SYS_CONTEXT('CTX_APP_IDS', 'ID_PROFILO'));
	  END MioIdProfilo;


  -- Legge ID_RUOLO dal contesto di sessione CTX_APP_IDS.
  -- Il ruolo determina i privilegi disponibili e i filtri di visibilità.
  -- Usato da Carica() come guard rapido: IF MioIdRuolo() IS NOT NULL THEN ...
  STATIC FUNCTION MioIdRuolo RETURN NUMBER IS
	  BEGIN
	    RETURN TO_NUMBER(SYS_CONTEXT('CTX_APP_IDS', 'ID_RUOLO'));
	  END MioIdRuolo;


  -- Legge ID_SESSIONE (GUID come VARCHAR2) da CTX_APP_IDS.
  -- Il GUID è generato con SYS_GUID() al momento del login e inserito in TBL_SESSIONI.
  -- Restituisce NULL se la sessione non è attiva.
  STATIC FUNCTION MioIdSessione RETURN VARCHAR2 IS
	  BEGIN
	    RETURN SYS_CONTEXT('CTX_APP_IDS', 'ID_SESSIONE');
	  END MioIdSessione;


  -- Legge ID_UTENTE dal contesto di sessione CTX_APP_IDS.
  -- Usato dai metodi CRUD per il tracciamento audit (UtenteIns, UtenteAgg).
  -- Restituisce NULL se la sessione non è attiva.
  STATIC FUNCTION MioIdUtente RETURN NUMBER IS
	  BEGIN
	    RETURN TO_NUMBER(SYS_CONTEXT('CTX_APP_IDS', 'ID_UTENTE'));
	  END MioIdUtente;


  -- BuildWhere: costruisce dinamicamente la clausola WHERE combinando i filtri
  -- di autorizzazione (CTX_APP_ABL) con i filtri di ricerca (CTX_APP_FLT).
  --
  -- Algoritmo:
  --   1. Recupera l'unione degli attributi distinti presenti in ABL e FLT
  --      tramite la vista SESSION_CONTEXT, ordinati alfabeticamente.
  --   2. Per ogni attributo:
  --      a. Risolve il sinonimo (SELF.RisolviSinonimo) → se NULL lo ignora.
  --      b. Separa COLONNA e TIPO dal formato 'COLONNA|TIPO'.
  --      c. Qualifica la colonna con pAlias se fornito (es. 'U.COGNOME').
  --      d. Legge i valori da ABL e FLT; effettua il parsing 'VALORI|OPERATORE'.
  --      e. Applica il merging: stessi operatori '=' → UnisciValori (IN clause);
  --         operatori diversi → entrambe le condizioni collegate con AND.
  --   3. Concatena tutti i predicati con ' AND '.
  --   4. Imposta SELF.Esito con gli avvisi raccolti (sinonimi ignorati, FLT allarga ABL).
  MEMBER PROCEDURE BuildWhere(pAlias IN VARCHAR2 DEFAULT NULL, pWhere OUT VARCHAR2) IS
    vSep       VARCHAR2(5)    := '';    -- separatore AND tra predicati (vuoto al primo)
    vAttr      VARCHAR2(128);           -- nome attributo corrente dal contesto
    vRisolto   VARCHAR2(256);           -- risultato di RisolviSinonimo: 'COLONNA|TIPO'
    vColonna   VARCHAR2(128);           -- nome colonna fisica estratto da vRisolto
    vTipo      VARCHAR2(1);             -- tipo dati: 'V', 'N' o 'D'
    vCampo     VARCHAR2(256);           -- colonna qualificata con alias (es. 'U.COGNOME')
    vValAbl    VARCHAR2(4000);          -- valore grezzo da CTX_APP_ABL (es. 'S;N|=')
    vValFlt    VARCHAR2(4000);          -- valore grezzo da CTX_APP_FLT
    vValoriAbl VARCHAR2(3900);          -- lista valori ABL (parte prima dell'ultimo '|')
    vValoriFlt VARCHAR2(3900);          -- lista valori FLT
    vOpAbl     VARCHAR2(10);            -- operatore ABL (es. '=', 'LIKE', 'BETWEEN')
    vOpFlt     VARCHAR2(10);            -- operatore FLT
    vPred      VARCHAR2(4000);          -- predicato SQL costruito per il campo corrente
    vWarnings  VARCHAR2(4000) := '';    -- attributi per cui FLT allarga la visibilità ABL
    vIgnorati  VARCHAR2(4000) := '';    -- sinonimi non mappati da RisolviSinonimo (ignorati, non bloccanti)

    ---------------------------------------------------------------------------
    -- FUNZIONI INTERNE (nested) - visibili solo all'interno di BuildWhere
    ---------------------------------------------------------------------------

    -- FormatVal: formatta un singolo valore scalare per inclusione sicura in SQL dinamico.
    --
    -- Protezione SQL injection:
    --   'N' (NUMBER)  - tenta TO_NUMBER(TRIM(pVal)); se non numericamente valido
    --                   solleva eccezione VALUE_ERROR → intercettata da BuildWhere → esito 500.
    --                   Restituisce il testo del numero senza apici.
    --   'D' (DATE)    - tenta TO_DATE(TRIM(pVal), 'YYYY-MM-DD'); se formato non valido
    --                   solleva eccezione → intercettata da BuildWhere → esito 500.
    --                   Restituisce la stringa TO_DATE('YYYY-MM-DD','YYYY-MM-DD').
    --   'V' (VARCHAR) - escapa gli apici singoli raddoppiandoli (standard SQL);
    --                   avvolge il risultato in apici singoli.
    --                   Esempio: FormatVal('D''Amico', 'V') → '''D''''Amico'''
    FUNCTION FormatVal(pVal IN VARCHAR2, pTipo IN VARCHAR2) RETURN VARCHAR2 IS
      vN NUMBER;   -- usato per validare il tipo numerico
      vD DATE;     -- usato per validare il tipo data
	    BEGIN
	      IF pTipo = 'N' THEN
	        -- Validazione numerica: solleva eccezione se pVal non è un numero valido
	        vN := TO_NUMBER(TRIM(pVal));
	        RETURN TRIM(pVal);
	      ELSIF pTipo = 'D' THEN
	        -- Validazione data: attende formato ISO 8601 (YYYY-MM-DD)
	        vD := TO_DATE(TRIM(pVal), 'YYYY-MM-DD');
	        RETURN 'TO_DATE(''' || TRIM(pVal) || ''',''YYYY-MM-DD'')';
	      ELSE
	        -- Tipo VARCHAR: escape degli apici singoli ('' al posto di ')
	        RETURN '''' || REPLACE(TRIM(pVal), '''', '''''') || '''';
	      END IF;
	    END FormatVal;


    -- Predicato: costruisce il frammento SQL completo per un singolo campo.
    --
    -- Operatori supportati:
    --   =  <  <=  >  >=  <>  LIKE  BETWEEN  NULL  NOTNULL
    --
    -- Comportamento per operatori speciali:
    --   NULL/NOTNULL: ignora pValori, genera "campo IS [NOT] NULL"
    --   BETWEEN:      attende esattamente due valori ';'-separati
    --                 (es. '100;500' → "campo BETWEEN 100 AND 500")
    --   = con N valori: genera clausola IN
    --                 (es. 'S;N' → "campo IN ('S','N')")
    --   Qualsiasi altro operatore con 1 valore: "campo OP valore"
    --
    -- Esempi:
    --   Predicato('U.COGNOME', 'V', 'Rossi;Bianchi', '=')
    --     → "U.COGNOME IN ('Rossi','Bianchi')"
    --   Predicato('U.DATA_INS', 'D', '2024-01-01;2024-12-31', 'BETWEEN')
    --     → "U.DATA_INS BETWEEN TO_DATE('2024-01-01','YYYY-MM-DD') AND TO_DATE('2024-12-31','YYYY-MM-DD')"
    --   Predicato('U.COGNOME', 'V', 'B%', 'LIKE')
    --     → "U.COGNOME LIKE 'B%'"
    FUNCTION Predicato(pCampo IN VARCHAR2, pTipo IN VARCHAR2, pValori IN VARCHAR2, pOp IN VARCHAR2) RETURN VARCHAR2 IS
      vCount  NUMBER;          -- numero di valori nella lista ';'-separata
      vVal    VARCHAR2(500);   -- singolo valore estratto dalla lista
      vInList VARCHAR2(3000);  -- lista formattata per la clausola IN
      vSepIn  VARCHAR2(1) := '';  -- separatore ',' per la lista IN (vuoto al primo elemento)
	    BEGIN
	      -- Gestione operatori IS NULL / IS NOT NULL (non richiedono valori)
	      IF pOp IN ('NULL', 'NOTNULL') THEN
	        RETURN pCampo || CASE pOp WHEN 'NULL' THEN ' IS NULL' ELSE ' IS NOT NULL' END;
	      END IF;
	      -- Gestione BETWEEN: prende il primo e il secondo valore della lista
	      IF pOp = 'BETWEEN' THEN
	        RETURN pCampo || ' BETWEEN ' ||
	               FormatVal(REGEXP_SUBSTR(pValori, '[^;]+', 1, 1), pTipo) ||
	               ' AND ' ||
	               FormatVal(REGEXP_SUBSTR(pValori, '[^;]+', 1, 2), pTipo);
	      END IF;
	      -- Conta i valori presenti nella lista (separatore ';')
	      vCount := REGEXP_COUNT(pValori, ';') + 1;
	      -- Singolo valore: usa direttamente l'operatore fornito
	      IF vCount = 1 THEN
	        RETURN pCampo || ' ' || pOp || ' ' || FormatVal(pValori, pTipo);
	      END IF;
	      -- Valori multipli con op. '=': costruisce la clausola IN
	      FOR i IN 1..vCount LOOP
	        vVal    := TRIM(REGEXP_SUBSTR(pValori, '[^;]+', 1, i));
	        vInList := vInList || vSepIn || FormatVal(vVal, pTipo);
	        vSepIn  := ',';
	      END LOOP;
	      RETURN pCampo || ' IN (' || vInList || ')';
	    END Predicato;


    -- UnisciValori: unisce due liste ';'-separate eliminando i duplicati (case-sensitive).
    -- Preserva l'ordine: prima tutti gli elementi di pA, poi quelli di pB non già presenti.
    -- Utilizzata nel merging ABL+FLT quando entrambi usano operatore '=':
    -- il risultato è la lista unificata per la clausola IN finale.
    --
    -- Esempi:
    --   UnisciValori('S;A', 'S;B') → 'S;A;B'   (S già presente, B aggiunto)
    --   UnisciValori('S',   'S')   → 'S'         (nessuna aggiunta)
    FUNCTION UnisciValori(pA IN VARCHAR2, pB IN VARCHAR2) RETURN VARCHAR2 IS
      vResult VARCHAR2(4000) := pA;  -- inizia con tutti i valori di ABL
      vCount  NUMBER;
      vVal    VARCHAR2(500);
	    BEGIN
	      vCount := REGEXP_COUNT(pB, ';') + 1;
	      FOR i IN 1..vCount LOOP
	        vVal := TRIM(REGEXP_SUBSTR(pB, '[^;]+', 1, i));
	        -- Aggiunge il valore solo se non è già presente in vResult
	        -- (controllo tramite delimitatori ';' per evitare falsi positivi parziali)
	        IF vVal IS NOT NULL AND INSTR(';' || vResult || ';', ';' || vVal || ';') = 0 THEN
	          vResult := vResult || ';' || vVal;
	        END IF;
	      END LOOP;
	      RETURN vResult;
	    END UnisciValori;

    -- HaNuoviValori: verifica se la lista pB contiene almeno un valore non presente in pA.
    -- Usata per rilevare il caso in cui CTX_APP_FLT "allarga la visibilità" rispetto a
    -- CTX_APP_ABL: se FLT introduce valori non coperti da ABL, BuildWhere segnala
    -- l'allargamento in DebugInfo (esito 200 con avviso) senza bloccare l'operazione.
    --
    -- Esempi:
    --   HaNuoviValori('S',   'N')   → TRUE  (FLT aggiunge il valore 'N' non in ABL)
    --   HaNuoviValori('S;N', 'S')   → FALSE (tutti i valori FLT già presenti in ABL)
    --   HaNuoviValori('S;N', 'S;N') → FALSE
    FUNCTION HaNuoviValori(pA IN VARCHAR2, pB IN VARCHAR2) RETURN BOOLEAN IS
      vCount NUMBER;
      vVal   VARCHAR2(500);
	    BEGIN
	      vCount := REGEXP_COUNT(pB, ';') + 1;
	      FOR i IN 1..vCount LOOP
	        vVal := TRIM(REGEXP_SUBSTR(pB, '[^;]+', 1, i));
	        -- Trovato almeno un valore di pB non presente in pA: FLT allarga la visibilità
	        IF vVal IS NOT NULL AND INSTR(';' || pA || ';', ';' || vVal || ';') = 0 THEN
	          RETURN TRUE;
	        END IF;
	      END LOOP;
	      RETURN FALSE;
	    END HaNuoviValori;

    ---------------------------------------------------------------------------
    -- CORPO PRINCIPALE DI BuildWhere
    ---------------------------------------------------------------------------

	  BEGIN
	    pWhere := '';   -- inizializzazione: clausola vuota se nessun filtro è applicabile

	    -- Itera su tutti gli attributi distinti presenti in CTX_APP_ABL e/o CTX_APP_FLT.
	    -- SESSION_CONTEXT è la vista Oracle che espone il contenuto dei contesti attivi.
	    -- L'ordinamento garantisce un output deterministico (importante per i test).
			FOR vRec IN (
	      SELECT DISTINCT attribute
	        FROM SESSION_CONTEXT
	       WHERE namespace IN ('CTX_APP_ABL', 'CTX_APP_FLT')
	       ORDER BY attribute
	    ) LOOP
	      vAttr := vRec.attribute;

	      -- Risoluzione sinonimo → formato 'COLONNA|TIPO'
	      -- Se NULL: l'attributo non appartiene a questo oggetto (es. un filtro ATTIVO
	      -- potrebbe non essere presente in OBJ_Ruolo); viene ignorato silenziosamente
	      -- e tracciato in vIgnorati per l'eventuale avviso nel Esito finale.
	      vRisolto := SELF.RisolviSinonimo(vAttr);
	      IF vRisolto IS NULL THEN
	        vIgnorati := vIgnorati || vAttr || ' ';
	        CONTINUE;
	      END IF;

	      -- Separazione COLONNA e TIPO dal risultato 'COLONNA|TIPO'
	      vColonna := SUBSTR(vRisolto, 1, INSTR(vRisolto, '|') - 1);
	      vTipo    := SUBSTR(vRisolto, INSTR(vRisolto, '|') + 1);
	      -- Qualificazione con alias (es. 'COGNOME' → 'U.COGNOME')
	      vCampo   := CASE WHEN pAlias IS NOT NULL THEN pAlias || '.' ELSE '' END || vColonna;

	      -- Lettura dei valori dai due contesti (formato grezzo: 'VALORI|OPERATORE')
	      vValAbl    := SYS_CONTEXT('CTX_APP_ABL', vAttr);
	      vValFlt    := SYS_CONTEXT('CTX_APP_FLT', vAttr);
	      vValoriAbl := NULL; vOpAbl := NULL;
	      vValoriFlt := NULL; vOpFlt := NULL;

	      -- Parsing 'VALORI|OPERATORE': usa l'ultimo '|' come separatore
	      -- per gestire correttamente valori che contengono il carattere '|' al loro interno.
	      IF vValAbl IS NOT NULL THEN
	        vOpAbl     := SUBSTR(vValAbl, INSTR(vValAbl, '|', -1) + 1);
	        vValoriAbl := SUBSTR(vValAbl, 1, INSTR(vValAbl, '|', -1) - 1);
	      END IF;
	      IF vValFlt IS NOT NULL THEN
	        vOpFlt     := SUBSTR(vValFlt, INSTR(vValFlt, '|', -1) + 1);
	        vValoriFlt := SUBSTR(vValFlt, 1, INSTR(vValFlt, '|', -1) - 1);
	      END IF;

	      -- Merging ABL + FLT e costruzione del predicato per il campo corrente
	      IF vValAbl IS NOT NULL AND vValFlt IS NOT NULL THEN
	        IF vOpAbl = '=' AND vOpFlt = '=' THEN
	          -- Caso 1: entrambi con op. '=' → unione dei valori (IN clause).
	          -- Se FLT introduce valori non in ABL → segnalare l'allargamento in Warnings.
	          IF HaNuoviValori(vValoriAbl, vValoriFlt) THEN
	            vWarnings := vWarnings || vAttr || ' ';
	          END IF;
	          vPred := Predicato(vCampo, vTipo, UnisciValori(vValoriAbl, vValoriFlt), '=');
	        ELSE
	          -- Caso 2: operatori diversi o non-'=' → AND tra le due condizioni.
	          -- Esempio: ABL ha "ATTIVO = 'S'" e FLT ha "DATA_NASC >= '1980-01-01'"
	          vPred := Predicato(vCampo, vTipo, vValoriAbl, vOpAbl) ||
	                   ' AND ' ||
	                   Predicato(vCampo, vTipo, vValoriFlt, vOpFlt);
	        END IF;
	      ELSIF vValAbl IS NOT NULL THEN
	        -- Solo ABL: usa direttamente il predicato di autorizzazione
	        vPred := Predicato(vCampo, vTipo, vValoriAbl, vOpAbl);
	      ELSE
	        -- Solo FLT: usa direttamente il predicato di ricerca
	        vPred := Predicato(vCampo, vTipo, vValoriFlt, vOpFlt);
	      END IF;

	      -- Concatenazione con separatore AND
	      pWhere := pWhere || vSep || vPred;
	      vSep   := ' AND ';
	    END LOOP;

	    -- Impostazione dell'esito finale con eventuali avvisi
	    IF vIgnorati IS NOT NULL OR vWarnings IS NOT NULL THEN
	      -- 200 con DebugInfo: clausola costruita correttamente ma con avvisi
	      SELF.Esito := OBJ_Esito.Imposta(200,
	        'BuildWhere completata con avvisi',
	        TRIM(
	          CASE WHEN vIgnorati IS NOT NULL
	               THEN 'Sinonimi ignorati (non mappati): ' || TRIM(vIgnorati) || '. '
	               ELSE '' END ||
	          CASE WHEN vWarnings IS NOT NULL
	               THEN 'FLT allarga visibilità per: ' || TRIM(vWarnings)
	               ELSE '' END
	        ),
	        NULL);
	    ELSE
	      -- 200 senza avvisi: tutti gli attributi sono stati mappati correttamente
	      SELF.Esito := OBJ_Esito.Imposta(200, 'BuildWhere completata', NULL, NULL);
	    END IF;

	  EXCEPTION
	    WHEN OTHERS THEN
	      -- 500: errore interno (tipicamente valore non valido per tipo N o D in FormatVal)
	      SELF.Esito := OBJ_Esito.Imposta(500,
	        'BuildWhere non riuscita per errore interno',
	        SQLERRM, SQLERRM);
	      pWhere := NULL;
	  END BuildWhere;

END;
