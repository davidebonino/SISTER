----------------------------------------------------------------------------
--  Profilo
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Profilo UNDER OBJ_Profilatore (
  IdProfilo     NUMBER,
  IdUtente      NUMBER,
  IdRuolo       NUMBER,
  Nome          VARCHAR2(80),
  DataIns       DATE,
  UtenteIns     NUMBER,
  DataAgg       DATE,
  UtenteAgg     NUMBER,
  Attivo        VARCHAR2(1),
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2,
  STATIC FUNCTION Carica(pIdProfilo IN NUMBER) RETURN OBJ_Profilo,
  STATIC FUNCTION CaricaContestoAbilitazioni(pIdProfilo IN NUMBER) RETURN NUMBER,
  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN,
  MEMBER PROCEDURE Crea,
  MEMBER PROCEDURE Modifica,
  MEMBER PROCEDURE Elimina(pFisica BOOLEAN DEFAULT FALSE),
  CONSTRUCTOR FUNCTION OBJ_Profilo RETURN SELF AS RESULT
  );
----------------------------------------------------------------------------


CREATE OR REPLACE TYPE BODY OBJ_Profilo AS

  -- Costruttore
  CONSTRUCTOR FUNCTION OBJ_Profilo RETURN SELF AS RESULT IS
    BEGIN
      SELF.IdProfilo := NULL;
      SELF.IdUtente  := NULL;
      SELF.IdRuolo   := NULL;
      SELF.Nome      := NULL;
      SELF.DataIns   := NULL;
      SELF.UtenteIns := NULL;
      SELF.DataAgg   := NULL;
      SELF.UtenteAgg := NULL;
      SELF.Attivo    := NULL;
      RETURN;
    END;


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
    BEGIN
      RETURN 'PROFILO';
    END Info;
  --------------------------------------------------------------------------


  OVERRIDING MEMBER FUNCTION RisolviSinonimo(pSinonimo IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE UPPER(pSinonimo)
      WHEN 'ID_PROFILO' THEN 'ID_PROFILO|N'
      WHEN 'ID_UTENTE'  THEN 'ID_UTENTE|N'
      WHEN 'ID_RUOLO'   THEN 'ID_RUOLO|N'
      WHEN 'NOME'       THEN 'NOME|V'
      WHEN 'ATTIVO'     THEN 'ATTIVO|V'
      ELSE NULL
    END;
  END RisolviSinonimo;
  --------------------------------------------------------------------------


  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN IS
    BEGIN
      RETURN TRUE;
    END ControlliLogici;
    --------------------------------------------------------------------------


  -- Crea un oggetto Profilo nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Crea IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'PROFILO', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.IdProfilo  := PROFILI_ID_PROFILO.NEXTVAL;
      SELF.Attivo     := 'S';
      SELF.DataIns    := SYSDATE;
      SELF.UtenteIns  := OBJ_Profilo.MioIdUtente();
      SELF.DataAgg    := SYSDATE;
      SELF.UtenteAgg  := OBJ_Profilo.MioIdUtente();

      INSERT INTO PROFILI (
        ID_PROFILO,
        ID_UTENTE,
        ID_RUOLO,
        NOME,
        DATAINS,
        UTENTEINS,
        DATAAGG,
        UTENTEAGG,
        ATTIVO)
      VALUES (
        SELF.IdProfilo,
        SELF.IdUtente,
        SELF.IdRuolo,
        SELF.Nome,
        SELF.DataIns,
        SELF.UtenteIns,
        SELF.DataAgg,
        SELF.UtenteAgg,
        SELF.Attivo
      );

      SELF.Esito := OBJ_Esito.Imposta(200, 'Profilo creato con successo', NULL, NULL);

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Profilo non inserito per errore interno', 'Profilo non inserito per errore interno' || SQLERRM, SQLERRM);

    END Crea;
    --------------------------------------------------------------------------


  -- Modifica un oggetto Profilo nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Modifica IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('MODIFICA', 'PROFILO', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.DataAgg       := SYSDATE;
      SELF.UtenteAgg     := OBJ_Profilo.MioIdUtente();

      UPDATE PROFILI SET
        ID_UTENTE = SELF.IdUtente,
        ID_RUOLO = SELF.IdRuolo,
        NOME = SELF.Nome,
        DATAAGG = SELF.DataAgg,
        UTENTEAGG = SELF.UtenteAgg,
        ATTIVO = SELF.Attivo
      WHERE ID_PROFILO = SELF.IdProfilo;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Profilo modificato con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Profilo non trovato per modifica', 'Profilo non trovato per modifica', 'OBJ_Profilo.Modifica: Nessun record aggiornato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Profilo non modificato per errore interno', 'Profilo non modificato per errore interno' || SQLERRM, SQLERRM);

    END Modifica;
    --------------------------------------------------------------------------


  -- Elimina un oggetto Profilo nel database.
  -- pFisica = FALSE (default): soft delete (Attivo = 'N')
  -- pFisica = TRUE: eliminazione fisica del record
  MEMBER PROCEDURE Elimina(pFisica BOOLEAN DEFAULT FALSE) IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('ELIMINAZIONE', 'PROFILO', NULL, TRUE);
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      IF pFisica THEN
        --Cancellazione fisica
        DELETE FROM PROFILI
        WHERE ID_PROFILO = SELF.IdProfilo;
      ELSE
        --Cancellazione logica (soft delete)
        SELF.DataAgg   := SYSDATE;
        SELF.UtenteAgg := OBJ_Profilo.MioIdUtente();
        SELF.Attivo    := 'N';

        UPDATE PROFILI SET
          ATTIVO    = SELF.Attivo,
          DATAAGG   = SELF.DataAgg,
          UTENTEAGG = SELF.UtenteAgg
        WHERE ID_PROFILO = SELF.IdProfilo;

      END IF;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Profilo eliminato con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Profilo non trovato per eliminazione', 'Profilo non trovato per eliminazione', 'OBJ_Profilo.Elimina: Nessun record aggiornato');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        SELF.Esito := OBJ_Esito.Imposta(500, 'Profilo non eliminato per errore interno', 'Profilo non eliminato per errore interno' || SQLERRM, SQLERRM);

    END Elimina;
    --------------------------------------------------------------------------


  -- Carica il privilegio
  STATIC FUNCTION Carica(pIdProfilo IN NUMBER) RETURN OBJ_Profilo IS
    vProfilo OBJ_Profilo;
	  BEGIN
	    vProfilo := OBJ_Profilo();

	    IF OBJ_Profilo.MioIdRuolo() IS NOT NULL THEN

	      SELECT ID_PROFILO
	          , ID_UTENTE
	          , ID_RUOLO
	          , NOME
	          , DATAINS
	          , UTENTEINS
	          , DATAAGG
	          , UTENTEAGG
	          , ATTIVO
	        INTO vProfilo.IdProfilo,
	            vProfilo.IdUtente,
	            vProfilo.IdRuolo,
	            vProfilo.Nome,
	            vProfilo.DataIns,
	            vProfilo.UtenteIns,
	            vProfilo.DataAgg,
	            vProfilo.UtenteAgg,
	            vProfilo.Attivo
	        FROM PROFILI PR
	        WHERE PR.ID_PROFILO  = pIdProfilo;

	      IF vProfilo.IdProfilo IS NOT NULL THEN
	        vProfilo.Esito := OBJ_Esito.Imposta(200, 'Profilo caricato con successo', NULL, NULL);
	        RETURN vProfilo;
	      ELSE
	        vProfilo.Esito := OBJ_Esito.Imposta(204, 'Profilo non trovato', 'Profilo non trovato per i parametri forniti', NULL);
	        RETURN vProfilo;
	      END IF;
	    ELSE
	      -- Chiamante non autorizzato
	      vProfilo.Esito := OBJ_Esito.Imposta(401, 'Chiamante non autorizzato', 'Chiamante non autorizzato', NULL);
	      RETURN vProfilo;
	    END IF;

	  EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	      -- Profilo non trovato
	      vProfilo.Esito := OBJ_Esito.Imposta(204, 'Profilo non trovato, parametri errati', 'Profilo non trovato, parametri errati' || SQLERRM, SQLERRM);
	      RETURN vProfilo;
	    WHEN OTHERS THEN
	      -- Log dell'errore per debugging
	      vProfilo.Esito := OBJ_Esito.Imposta(500, 'Profilo non trovato per errore interno', 'Profilo non trovato per errore interno' || SQLERRM, SQLERRM);
	      RETURN vProfilo;
	  END Carica;
  --------------------------------------------------------------------------


  -- Carica il contesto delle abilitazioni associate al profilo
  -- !!! verificare se creare un richiamo a OBJ_Abilitazione
  STATIC FUNCTION CaricaContestoAbilitazioni(pIdProfilo IN NUMBER) RETURN NUMBER IS
    vIdAbilitazioni NUMBER;
    vAbilitazione OBJ_Abilitazione;

    -- Raggruppa per CHIAVE+OPERATORE: più valori con stesso operatore → semicolon-separated
    -- Formato nel contesto: VALORI|OPERATORE  (es. "210;211|=")
    CURSOR cAbilitazioni IS
    SELECT CHIAVE,
           OPERATORE,
           LISTAGG(VALORE, ';') WITHIN GROUP (ORDER BY VALORE) AS VALORI
      FROM ABILITAZIONI
     WHERE ID_PROFILO = pIdProfilo
     GROUP BY CHIAVE, OPERATORE;
	  BEGIN
	    PKG_APP.PulisciContesto('CTX_APP_ABL');

	    FOR rec_abil IN cAbilitazioni LOOP
	      PKG_APP.AggiungiContesto('CTX_APP_ABL', rec_abil.CHIAVE, rec_abil.VALORI || '|' || rec_abil.OPERATORE);
	    END LOOP;

	    RETURN vIdAbilitazioni;
	  EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	      RETURN NULL;
	    WHEN OTHERS THEN
	      RETURN NULL;
	  END CaricaContestoAbilitazioni;

END;
