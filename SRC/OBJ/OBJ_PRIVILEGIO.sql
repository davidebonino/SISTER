----------------------------------------------------------------------------
--  Privilegio
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Privilegio UNDER OBJ_Profilatore (
  IdPrivilegio  NUMBER,
  IdAzione      NUMBER,
  IdRuolo       NUMBER,
  DataIns       DATE,
  UtenteIns     NUMBER,
  DataAgg       DATE,
  UtenteAgg     NUMBER,
  Attivo        VARCHAR2(1),
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
  STATIC FUNCTION Carica(pIdPrivilegio IN NUMBER) RETURN OBJ_Privilegio,
  STATIC FUNCTION Carica(pIdAzione IN NUMBER, pIdRuolo IN NUMBER) RETURN OBJ_Privilegio,
  STATIC FUNCTION Cerca(pIdAzione IN NUMBER, pIdRuolo IN NUMBER) RETURN NUMBER,
  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN,
  MEMBER PROCEDURE Crea,
  MEMBER PROCEDURE Modifica,
  MEMBER PROCEDURE Elimina,
  CONSTRUCTOR FUNCTION OBJ_Privilegio RETURN SELF AS RESULT
);
----------------------------------------------------------------------------


CREATE OR REPLACE TYPE BODY OBJ_Privilegio AS

  CONSTRUCTOR FUNCTION OBJ_Privilegio RETURN SELF AS RESULT
  IS
  BEGIN
    SELF.IdPrivilegio := NULL;
    SELF.IdAzione     := NULL;
    SELF.IdRuolo      := NULL;
    SELF.DataIns      := NULL;
    SELF.UtenteIns    := NULL;
    SELF.DataAgg      := NULL;
    SELF.UtenteAgg    := NULL;
    SELF.Attivo       := NULL;
    RETURN;
  END;


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'PRIVILEGIO';
  END Info;
  --------------------------------------------------------------------------


  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN IS
  BEGIN
    RETURN TRUE;
  END ControlliLogici;
  --------------------------------------------------------------------------


  -- Carica il privilegio
  STATIC FUNCTION Carica(pIdPrivilegio IN NUMBER) RETURN OBJ_Privilegio IS
    vPrivilegio OBJ_Privilegio;
  BEGIN
    vPrivilegio := OBJ_Privilegio();

    SELECT ID_PRIVILEGIO
         , ID_AZIONE
         , ID_RUOLO
         , DATAINS
         , UTENTEINS
         , DATAAGG
         , UTENTEAGG
         , ATTIVO
      INTO vPrivilegio.IdPrivilegio,
           vPrivilegio.IdAzione,
           vPrivilegio.IdRuolo,
           vPrivilegio.DataIns,
           vPrivilegio.UtenteIns,
           vPrivilegio.DataAgg,
           vPrivilegio.UtenteAgg,
           vPrivilegio.Attivo
      FROM TBL_PRIVILEGI PR
       WHERE PR.ID_PRIVILEGIO = pIdPrivilegio;

     IF vPrivilegio.IdAzione IS NOT NULL THEN
       vPrivilegio.Esito := OBJ_Esito.Imposta(200, 'Privilegio caricato con successo', NULL, NULL);
       RETURN vPrivilegio;
     ELSE
       vPrivilegio.Esito := OBJ_Esito.Imposta(204, 'Privilegio non trovato', 'Privilegio non trovato per i parametri forniti', NULL);
       RETURN vPrivilegio;
     END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Privilegio non trovato
      vPrivilegio.Esito := OBJ_Esito.Imposta(204, 'Privilegio non trovato, parametri errati', 'Privilegio non trovato, parametri errati' || SQLERRM, SQLERRM);
      RETURN vPrivilegio;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vPrivilegio.Esito := OBJ_Esito.Imposta(500, 'Privilegio non trovato per errore interno', 'Privilegio non trovato per errore interno' || SQLERRM, SQLERRM);
      RETURN vPrivilegio;
  END Carica;
  --------------------------------------------------------------------------


  -- Carica il privilegio
  STATIC FUNCTION Carica(pIdAzione IN NUMBER, pIdRuolo IN NUMBER) RETURN OBJ_Privilegio IS
    vPrivilegio OBJ_Privilegio;
  BEGIN
    vPrivilegio := OBJ_Privilegio();

    SELECT ID_PRIVILEGIO
         , ID_AZIONE
         , ID_RUOLO
         , DATAINS
         , UTENTEINS
         , DATAAGG
         , UTENTEAGG
         , ATTIVO
      INTO vPrivilegio.IdPrivilegio,
           vPrivilegio.IdAzione,
           vPrivilegio.IdRuolo,
           vPrivilegio.DataIns,
           vPrivilegio.UtenteIns,
           vPrivilegio.DataAgg,
           vPrivilegio.UtenteAgg,
           vPrivilegio.Attivo
      FROM TBL_PRIVILEGI PR
       WHERE PR.ID_AZIONE = pIdAzione
         AND PR.ID_RUOLO  = pIdRuolo
         AND ROWNUM = 1;

     IF vPrivilegio.IdPrivilegio IS NOT NULL THEN
       vPrivilegio.Esito := OBJ_Esito.Imposta(200, 'Privilegio caricato con successo', NULL, NULL);
       RETURN vPrivilegio;
     ELSE
       vPrivilegio.Esito := OBJ_Esito.Imposta(204, 'Privilegio non trovato', 'Privilegio non trovato per i parametri forniti', NULL);
       RETURN vPrivilegio;
     END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Privilegio non trovato
      vPrivilegio.Esito := OBJ_Esito.Imposta(204, 'Privilegio non trovato, parametri errati', 'Privilegio non trovato, parametri errati' || SQLERRM, SQLERRM);
      RETURN vPrivilegio;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vPrivilegio.Esito := OBJ_Esito.Imposta(500, 'Privilegio non trovato per errore interno', 'Privilegio non trovato per errore interno' || SQLERRM, SQLERRM);
      RETURN vPrivilegio;
  END Carica;
  --------------------------------------------------------------------------


  -- Cerca l'ID dell'oggetto Privilegio
  STATIC FUNCTION Cerca(pIdAzione IN NUMBER, pIdRuolo IN NUMBER) RETURN NUMBER IS
    vPrivilegio OBJ_Privilegio;
  BEGIN
    vPrivilegio := Carica(pIdAzione, pIdRuolo);

     IF vPrivilegio.Esito.StatusCode = 200 THEN
       -- Privilegio trovato restituzione di IdPrivilegio
       RETURN vPrivilegio.IdPrivilegio;
     ELSE
       -- Privilegio non trovato
       RETURN NULL;
     END IF;
  END Cerca;
  --------------------------------------------------------------------------


  -- Crea un oggetto Privilegio nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Crea IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'PRIVILEGIO', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.IdPrivilegio := PRIVILEGI_ID_PRIVILEGIO.NEXTVAL;
      SELF.Attivo       := 'S';
      SELF.DataIns      := SYSDATE;
      SELF.UtenteIns    := OBJ_Utente.MioIdUtente();
      SELF.DataAgg      := SYSDATE;
      SELF.UtenteAgg    := OBJ_Utente.MioIdUtente();

      INSERT INTO TBL_PRIVILEGI (
        ID_PRIVILEGIO,
        ID_AZIONE,
        ID_RUOLO,
        DATAINS,
        UTENTEINS,
        DATAAGG,
        UTENTEAGG,
        ATTIVO
      ) VALUES (
        SELF.IdPrivilegio,
        SELF.IdAzione,
        SELF.IdRuolo,
        SELF.DataIns,
        SELF.UtenteIns,
        SELF.DataAgg,
        SELF.UtenteAgg,
        SELF.Attivo
      );
      SELF.Esito := OBJ_Esito.Imposta(200, 'Privilegio creato con successo', NULL, NULL);

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Privilegio non inserito per errore interno', 'Privilegio non inserito per errore interno' || SQLERRM, SQLERRM);

    END Crea;
    --------------------------------------------------------------------------


  -- Modifica un oggetto Privilegio nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Modifica IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('MODIFICA', 'PRIVILEGIO', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.DataAgg   := SYSDATE;
      SELF.UtenteAgg := OBJ_Utente.MioIdUtente();

      UPDATE TBL_PRIVILEGI SET
        ID_AZIONE = SELF.IdAzione,
        ID_RUOLO = SELF.IdRuolo,
        DATAAGG = SELF.DataAgg,
        UTENTEAGG = SELF.UtenteAgg,
        ATTIVO = SELF.Attivo
      WHERE ID_PRIVILEGIO = SELF.IdPrivilegio;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Privilegio modificato con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Privilegio non trovato per modifica', 'Privilegio non trovato per modifica', 'OBJ_Privilegio.Modifica: Nessun record aggiornato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Privilegio non modificato per errore interno', 'Privilegio non modificato per errore interno' || SQLERRM, SQLERRM);

    END Modifica;
    --------------------------------------------------------------------------


  -- Elimina un oggetto Privilegio nel database (soft delete) impostando Attivo a 'N'
  MEMBER PROCEDURE Elimina IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('ELIMINAZIONE', 'PRIVILEGIO', NULL, TRUE);
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.DataAgg   := SYSDATE;
      SELF.UtenteAgg := OBJ_Utente.MioIdUtente();
      SELF.Attivo    := 'N';

      UPDATE TBL_PRIVILEGI SET
        ATTIVO = SELF.Attivo,
        DATAAGG = SELF.DataAgg,
        UTENTEAGG = SELF.UtenteAgg
      WHERE ID_PRIVILEGIO = SELF.IdPrivilegio;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Privilegio eliminato con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Privilegio non trovato per eliminazione', 'Privilegio non trovato per eliminazione', 'OBJ_Privilegio.Elimina: Nessun record aggiornato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Privilegio non eliminato per errore interno', 'Privilegio non eliminato per errore interno' || SQLERRM, SQLERRM);

    END Elimina;
    --------------------------------------------------------------------------

END;
