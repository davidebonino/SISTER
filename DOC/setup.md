# SISTER - Sistema Informativo Sanitario Territoriale Regionale

**Data inizio**: 17/02/2025
**Tecnologia**: Oracle Database con PL/SQL Object-Oriented

## Sommario

1. [Introduzione]
2. [Architettura del sistema]
3. [Scopo del progetto]
4. [Descrizione metodologia e strumenti]
5. 

## Introduzione

SISTER è un progetto di sviluppo della Regione Piemonte e assegnato all'ASL CN1. E' nato nel 2010 con lo scopo di realizzare un sistema centralizzato per la gestione dei flussi informativi ministeriali FAR e SIAD. 

### Architettura del sistema

Nel corso degli anni lo sviluppo ha subito diverse modifiche, ad oggi esiste un applicazione web realizzata con un sistema RAD di nome Instant Developer in C# che si appoggia su un database ORACLE 19c.
Ci sono molte procedure di back office realizzate in PL/SQL, in particolare per la creazione dei flussi e per la verifica dei dati.
Il sistema hardware è composto da due server applicativi in bilanciamento, un server database e un server per l'integrazione con l'anagrafe regionale degli assistiti (AURA).

## Scopo del progetto

Lo scopo del progetto è la creazione di una nuova infrastruttura software per riscrivere tutto l'applicativo. Il linguaggio utilizzato è il PL/SQL in abbinamento con ORDS (Oracle REST Data Services) per l'esposizione di API per consentire la connessione remota.
L'intenzione è quella di realizzare una netta separazione tra la parte di presentazione e quella della logica applicativa. 

## Descrizione metodologia e strumenti

Questa parte di progetto deve realizzare in PL/SQL una libreria di oggetti e di codice che possano essere utilizzati sia internamente che esternamente con l'ausilio di ORDS. 
La maggior parte delle tabelle è già esistente ma è possibile un certo grado di modifica e di aggiunte per raggiungere lo scopo. Il motivo è dovuto al fatto che non si vuole una sostituzione netta del sistema ma un passaggio graduale. Per questa ragione si rende necessario il passaggio dal vecchio al nuovo a pezzi.

## Modalità operativa

Il primo passaggio è quello di realizzare l'infrastruttura applicativa, ossia un sistema che gestisca l'autenticazione, la gestione dei profili degli utenti, i messaggi di ritorno dalle chiamate a funzioni e procedure, la gestione delle informazioni applicative, la logica di ricerca e modifica dei dati che tenga conto della visibilità degli utenti, degli aspetti privacy, ecc.
Il paradigma di sviluppo che si intende mantenere è quello più vicino possibile alla programmazione ad oggetti. Le chiamate devono essere il più possibile standardizzate e anche i ritorni dalle funzioni.
Gli oggetti che rappresentano le entità distintive dell'applicazione devono ereditare da un oggetto padre (OBJ_Profilatore) che ne raccoglie le azioni e i dati comuni e condivisi.

## Organizzazione dei nomi

A tendere i nomi dei vari oggetti hanno un prefisso di 3 lettere in maiuscolo ì, che ne descrivono la tipologia (es. OBJ, PKG, ecc.). 

### Nei file 

I nomi dei file sono in maiuscolo e separati dal carattete _.

### Nel codice

In generale i nomi sono in camel case senza _ come separatore.

### Prefissi
OBJ: Oggetti 
PKG: Package
CTX: contesto applicativo

#### Le variabili 
Le variabili hanno un prefisso di un carattere per distinguerne il tipo di provenienza.

g: globale, con visibilità in ogni punto del codice
p: parametro di una funzione o procedura
v: variabile locale definita all'interno di una procedura o funzione

## Oggetti e tabelle

- UTENTI: utente unico che accede al sistema
- PROFILI: profilo di un utente, ogni utente può avere più di un profilo
- TBL_SESSIONI: una sessione rappresenta l'accesso autenticato al sistema ed è collegato al profilo
- TBL_ABILITAZIONI: l'abilitazione è un filtro di visibilità di un profilo, un profilo può avere più abilitazioni
- TBL_RUOLI: il ruolo rappresenta una modalità di accesso di un utente che gli permette di fare determinate azioni sulla base di privilegi concessi
- TBL_AZIONI: rappresentano delle attività atomiche che possono essere svolte all'interno di un applicativo, come la visualizzazione di un certo dato o la sua modifica o la possibilità di attivare un menu dall'interfaccia utente
- TBL_PRIVILEGI: un privilegio mette in relazione un attività con un ruolo


### Sequenza di Login

```
1. Client chiama: PKG_APP.Inizializza(pUsername, pKeyword, pIdProfilo)
   │
   ├─> OBJ_Sessione.Crea(pUsername, pKeyword, pIdProfilo)
   │   └─> Verifica credenziali nella tabella UTENTI
   │   └─> Valida: LOGIN = username, PASSWORD_0 = MD5(password)
   │   └─> Controlla: ATTIVO = 'S', DATA_SCADENZA_PASSWORD >= SYSDATE
   │   └─> Genera: SYS_GUID() → IdSessione (RAW(16))
   │   └─> Inserisce: TBL_SESSIONI (IdSessione, IdProfilo, IdRuolo, Stato, Data)
   │   └─> Ritorna: OBJ_Sessione con Esito = 201 (Created)
   │
   ├─> PKG_PROXY.gIdSessione := gSessione.IdSessione
   │
   ├─> OBJ_Profilo.Carica(gSessione.IdProfilo)
   │   └─> Carica il profilo della sessione
   │   └─> PKG_PROXY.gIdProfilo := gProfilo.IdProfilo
   │   └─> PKG_PROXY.gIdRuolo := gProfilo.IdRuolo
   │
   ├─> OBJ_Profilo.CaricaContestoAbilitazioni(gProfilo.IdProfilo)
   │   └─> Carica tutti i privilegi del profilo in CTX_APP_ABL
   │
   └─> OBJ_Utente.Carica(gProfilo.IdUtente)
       └─> PKG_PROXY.gIdUtente := gUtente.IdUtente
```
