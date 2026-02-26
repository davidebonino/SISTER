----------------------------------------------------------------------------
--  Abilitazione
----------------------------------------------------------------------------
CREATE OR REPLACE TYPE OBJ_Abilitazione UNDER OBJ_Profilatore (
  IdChiave NUMBER,
  IdProfilo NUMBER,
  Tipo NUMBER,
  Chiave VARCHAR2(30),
  Valore VARCHAR2(100),
  DataIns DATE,
  UtenteIns NUMBER,
  DataAgg DATE,
  UtenteAgg NUMBER,
  Operatore VARCHAR2(3),
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2,
  --STATIC FUNCTION Crea(pIdAccesso VARCHAR2) RETURN OBJ_Abilitazione,
  STATIC FUNCTION Carica(pIdSessione VARCHAR2, pIdAbilitazione NUMBER) RETURN OBJ_Abilitazione,
  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN,
  MEMBER PROCEDURE Crea,
  MEMBER PROCEDURE Modifica,
  MEMBER PROCEDURE Elimina,
  CONSTRUCTOR FUNCTION OBJ_Abilitazione RETURN SELF AS RESULT
);
----------------------------------------------------------------------------


CREATE OR REPLACE TYPE BODY OBJ_Abilitazione AS

  -- Costruttore
  CONSTRUCTOR FUNCTION OBJ_Abilitazione RETURN SELF AS RESULT
  IS
  BEGIN
    SELF.IdChiave := NULL;
    SELF.IdProfilo := NULL;
    SELF.Tipo := NULL;
    SELF.Chiave := NULL;
    SELF.Valore := NULL;
    SELF.DataIns := NULL;
    SELF.UtenteIns := NULL;
    SELF.DataAgg := NULL;
    SELF.UtenteAgg := NULL;
    SELF.Operatore := NULL;
    SELF.Condizioni := OBJ_Condizioni();
    RETURN;
  END;


  -- Informazioni sull'oggetto
  OVERRIDING MEMBER FUNCTION Info RETURN VARCHAR2 IS
  BEGIN
    RETURN 'ABILITAZIONE';
  END Info;
  --------------------------------------------------------------------------


  MEMBER FUNCTION ControlliLogici RETURN BOOLEAN IS
  BEGIN
    RETURN TRUE;
  END ControlliLogici;
  --------------------------------------------------------------------------


  -- Carica un Abilitazione
  STATIC FUNCTION Carica(pIdSessione VARCHAR2, pIdAbilitazione NUMBER) RETURN OBJ_Abilitazione IS
    vEsitoAccesso OBJ_Esito;
    vAbilitazione OBJ_Abilitazione;
  BEGIN
    vAbilitazione := OBJ_Abilitazione();

    vEsitoAccesso := PKG_APP.VerificaAccesso('VISUALIZZAZIONE', 'ABILITAZIONE', NULL, TRUE);
    IF vEsitoAccesso.StatusCode <> 200 THEN
      vAbilitazione.Esito := vEsitoAccesso;
      RETURN vAbilitazione;
    END IF;

    SELECT Id_Chiave,
           Id_Profilo,
           Tipo,
           Chiave,
           Valore,
           DataIns,
           UtenteIns,
           DataAgg,
           UtenteAgg,
           Operatore
      INTO vAbilitazione.IdChiave,
           vAbilitazione.IdProfilo,
           vAbilitazione.Tipo,
           vAbilitazione.Chiave,
           vAbilitazione.Valore,
           vAbilitazione.DataIns,
           vAbilitazione.UtenteIns,
           vAbilitazione.DataAgg,
           vAbilitazione.UtenteAgg,
           vAbilitazione.Operatore
      FROM TBL_ABILITAZIONI
     WHERE Id_Chiave = pIdAbilitazione;

    IF vAbilitazione.IdChiave IS NOT NULL THEN
      vAbilitazione.Esito := OBJ_Esito.Imposta(200, 'Abilitazione caricata con successo', NULL, NULL);
      RETURN vAbilitazione;
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Abilitazione non trovata
      vAbilitazione.Esito := OBJ_Esito.Imposta(204, 'Abilitazione non trovata, parametri errati', 'Abilitazione non trovata, parametri errati' || SQLERRM, SQLERRM);
      RETURN vAbilitazione;
    WHEN OTHERS THEN
      -- Log dell'errore per debugging
      vAbilitazione.Esito := OBJ_Esito.Imposta(500, 'Abilitazione non trovata per errore interno', 'Abilitazione non trovata per errore interno' || SQLERRM, SQLERRM);
      RETURN vAbilitazione;
  END Carica;
  --------------------------------------------------------------------------


  -- Crea un oggetto Abilitazione nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Crea IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('INSERIMENTO', 'ABILITAZIONE', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.IdChiave  := ABILITAZIONI_ID_CHIAVE.NEXTVAL;
      SELF.DataIns   := SYSDATE;
      SELF.UtenteIns := OBJ_Utente.MioIdUtente();
      SELF.DataAgg   := SYSDATE;
      SELF.UtenteAgg := OBJ_Utente.MioIdUtente();

      INSERT INTO TBL_ABILITAZIONI (
        Id_Chiave,
        Id_Profilo,
        Tipo,
        Chiave,
        Valore,
        DataIns,
        UtenteIns,
        DataAgg,
        UtenteAgg,
        Operatore
      ) VALUES (
        SELF.IdChiave,
        SELF.IdProfilo,
        SELF.Tipo,
        SELF.Chiave,
        SELF.Valore,
        SELF.DataIns,
        SELF.UtenteIns,
        SELF.DataAgg,
        SELF.UtenteAgg,
        SELF.Operatore
      );
      SELF.Esito := OBJ_Esito.Imposta(200, 'Abilitazione creata con successo', NULL, NULL);

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Abilitazione non inserita per errore interno', 'Abilitazione non inserita per errore interno' || SQLERRM, SQLERRM);

    END Crea;
    --------------------------------------------------------------------------


  -- Modifica un oggetto Abilitazione nel database partendo da un oggetto in memoria
  MEMBER PROCEDURE Modifica IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('MODIFICA', 'ABILITAZIONE', NULL, SELF.ControlliLogici());
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.DataAgg   := SYSDATE;
      SELF.UtenteAgg := OBJ_Utente.MioIdUtente();

      UPDATE TBL_ABILITAZIONI A SET
        Id_Profilo = SELF.IdProfilo,
        Tipo = SELF.Tipo,
        Chiave = SELF.Chiave,
        Valore = SELF.Valore,
        DataAgg = SELF.DataAgg,
        UtenteAgg = SELF.UtenteAgg,
        Operatore = SELF.Operatore
      WHERE Id_Chiave = SELF.IdChiave;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Abilitazione modificata con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Abilitazione non trovata per modifica', 'Abilitazione non trovata per modifica', 'OBJ_Abilitazione.Modifica: Nessun record aggiornato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Abilitazione non modificata per errore interno', 'Abilitazione non modificata per errore interno' || SQLERRM, SQLERRM);

    END Modifica;
    --------------------------------------------------------------------------


  -- Elimina un oggetto Abilitazione nel database (soft delete) impostando ... (cosa? Non c'è Attivo in Abilitazioni)
  MEMBER PROCEDURE Elimina IS
    vEsitoAccesso OBJ_Esito;
    BEGIN

      vEsitoAccesso := PKG_APP.VerificaAccesso('ELIMINAZIONE', 'ABILITAZIONE', NULL, TRUE);
      IF vEsitoAccesso.StatusCode <> 200 THEN
        SELF.Esito := vEsitoAccesso;
        RETURN;
      END IF;

      SELF.DataAgg   := SYSDATE;
      SELF.UtenteAgg := OBJ_Utente.MioIdUtente();

      DELETE FROM TBL_ABILITAZIONI
      WHERE Id_Chiave = SELF.IdChiave;

      IF SQL%ROWCOUNT > 0 THEN
        SELF.Esito := OBJ_Esito.Imposta(200, 'Abilitazione eliminata con successo', NULL, NULL);
      ELSE
        SELF.Esito := OBJ_Esito.Imposta(404, 'Abilitazione non trovata per eliminazione', 'Abilitazione non trovata per eliminazione', 'OBJ_Abilitazione.Elimina: Nessun record eliminato');
      END IF;

      EXCEPTION
      WHEN OTHERS THEN
        -- Log dell'errore per debugging
        SELF.Esito := OBJ_Esito.Imposta(500, 'Abilitazione non eliminata per errore interno', 'Abilitazione non eliminata per errore interno' || SQLERRM, SQLERRM);

    END Elimina;
    --------------------------------------------------------------------------

END;

