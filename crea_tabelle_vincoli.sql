# crea tutte le tabelle, tranne iprange, server, paese
# con chiavi esterne e vincoli generici
/*
CREATE TABLE server (
  Id int NOT NULL,
  AreaGeografica varchar(50) DEFAULT NULL,
  Lat float DEFAULT NULL,
  Lng float DEFAULT NULL,
  Banda float DEFAULT NULL,
  Capacità float DEFAULT NULL,
  Carico float,
  PRIMARY KEY (Id)
);
CREATE TABLE paese (
  Cod varchar(10) NOT NULL,
  Nome varchar(100) DEFAULT NULL,
  AreaGeografica int DEFAULT NULL,
  Lat float DEFAULT NULL,
  Lng float DEFAULT NULL,
  PRIMARY KEY (Cod)
  FOREIGN KEY (AreaGeografica) REFERENCES server(Id)
);
CREATE TABLE iprange (
  Start varchar(32) NOT NULL,
  End varchar(32) DEFAULT NULL,
  Paese varchar(4) DEFAULT NULL,
  PRIMARY KEY (Start),
  CONSTRAINT fk_iprange_paese FOREIGN KEY (Paese) REFERENCES paese (Cod)
)




*/



CREATE TABLE attore (
    Id INT PRIMARY KEY,
    Nome VARCHAR(32),
    Cognome VARCHAR(32)
);
CREATE TABLE regista (
    Id INT PRIMARY KEY,
    Nome VARCHAR(32),
    Cognome VARCHAR(32)
);
CREATE TABLE formato (
    Id INT PRIMARY KEY,
    FormatoVideo VARCHAR(50),
    FormatoAudio VARCHAR(50),
    Risoluzione VARCHAR(32),
    Bitrate INT,
    qVideo VARCHAR(10)
);
CREATE TABLE dispositivo (
    Id INT PRIMARY KEY,
    AziendaProduttrice VARCHAR(50),
    Modello VARCHAR(100),
    Anno INT,
    RAM INT,
    nCore INT,
    fProcessore FLOAT,
    pOrizzontali INT,
    pVerticali INT
);
CREATE TABLE pianoTariffario (
    Nome VARCHAR(20) PRIMARY KEY,
    Prezzo FLOAT,
    Contenuti VARCHAR(30),
    Pubblicità VARCHAR(30),
    QualitàMax VARCHAR(30)
);
CREATE TABLE critico (
    Id INT PRIMARY KEY,
    Nome VARCHAR(20),
    Cognome VARCHAR(20)
);
CREATE TABLE lingua (
    Id INT PRIMARY KEY,
    Nome VARCHAR(30)
);
CREATE TABLE cliente (
    Id INT PRIMARY KEY,
    Nome VARCHAR(32),
    Cognome VARCHAR(32),
    Email VARCHAR(100),
    Password VARCHAR(32),
    Abbonamento VARCHAR(20),
    Scadenza TIMESTAMP,
    FOREIGN KEY (Abbonamento) REFERENCES pianotariffario(Nome)
);











CREATE TABLE cartaDiCredito (
    Numero VARCHAR(30) PRIMARY KEY,
    DataScadenza TIMESTAMP,
    Circuito VARCHAR(30),
    Proprietario INT,
    FOREIGN KEY (Proprietario) REFERENCES cliente(Id)
);
DELIMITER //

CREATE TRIGGER verifica_data_precedente_oggi
BEFORE INSERT ON cartaDiCredito FOR EACH ROW
BEGIN
  IF NEW.DataScadenza <= CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La carte è scaduta';
  END IF;
END; //

DELIMITER ;
CREATE TABLE nonSupportato (
    Formato INT,
    Paese VARCHAR(10),
    PRIMARY KEY (Formato, Paese),
    FOREIGN KEY (Formato) REFERENCES formato(Id),
    FOREIGN KEY (Paese) REFERENCES paese(Cod)
);











CREATE TABLE sottoscrizione (
    CartadiCredito VARCHAR(30),
    Data TIMESTAMP,
    PianoTariffario VARCHAR(20),
    PRIMARY KEY (CartadiCredito, Data, PianoTariffario),
    FOREIGN KEY (CartadiCredito) REFERENCES cartadicredito(Numero),
    FOREIGN KEY (PianoTariffario) REFERENCES pianotariffario(Nome)
);
DELIMITER //

CREATE TRIGGER verifica_scadenza_carta
BEFORE INSERT ON sottoscrizione FOR EACH ROW
BEGIN
    DECLARE data_scadenza DATE;
    SELECT DataScadenza INTO data_scadenza FROM cartaDiCredito WHERE Numero = NEW.cartadiCredito;
    
    IF data_scadenza < CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La carta di credito è scaduta';
    END IF;
END; //

DELIMITER ;
CREATE TABLE film (
    Id INT PRIMARY KEY,
    Titolo VARCHAR(64),
    Descrizione VARCHAR(255),
    Genere VARCHAR(32),
    Durata INT,
    AnnoProduzione INT,
    PaeseProduzione VARCHAR(5),
    Regista INT,
    LivelloContenuto INT,
    nVisualizzazioni INT DEFAULT 0,
    RatingMedio FLOAT DEFAULT 5,
	FOREIGN KEY (PaeseProduzione) REFERENCES paese(Cod),
    FOREIGN KEY (Regista) REFERENCES regista(Id)
);











CREATE TABLE parte (
    Attore INT,
    Film INT,
    PRIMARY KEY (Attore, Film),
	FOREIGN KEY (Attore) REFERENCES attore(Id),
    FOREIGN KEY (Film) REFERENCES film(Id)
);
CREATE TABLE premio (
    Premio VARCHAR(64),
    Categoria VARCHAR(64),
    Anno INT,
    Vincitore INT,
    PRIMARY KEY (Premio, Categoria, Anno),
	FOREIGN KEY (Vincitore) REFERENCES film(Id)
);
DELIMITER //
CREATE TRIGGER trg_check_premio_anno # trigger che controlla che l'anno del premio sia compreso tra l'anno di uscita del film e il successivo
BEFORE INSERT ON Premio
FOR EACH ROW
BEGIN
    DECLARE film_annoProduzione INT;
    
    SELECT annoProduzione INTO film_annoProduzione
    FROM Film
    WHERE Id = NEW.Vincitore;
    
    IF NEW.Anno < film_annoProduzione THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il premio deve essere successivo all\'uscita del film';
    END IF;

    IF NEW.Anno > film_annoProduzione + 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il premio non può essere dato così tardi rispetto all\'uscita del film';
    END IF;
END;
//
DELIMITER ;
CREATE TABLE linguaSottotitoli (
    Film INT,
    Lingua INT,
    PRIMARY KEY (Film, Lingua),
	FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Lingua) REFERENCES lingua(Id)
);
CREATE TABLE linguaAudio (
    Film INT,
    Lingua INT,
    PRIMARY KEY (Film, Lingua),
	FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Lingua) REFERENCES lingua(Id)
);
CREATE TABLE critica (
    Film INT,
    Critico INT,
    Voto INT,
    Data TIMESTAMP,
    FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Critico) REFERENCES critico(Id)
);

CREATE TABLE file (
    Id INT PRIMARY KEY,
    Film INT,
    Formato INT,
    DataInserimento TIMESTAMP,
    Dimensione INT,
    Durata INT,
    Server INT,
    FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Formato) REFERENCES formato(Id),
    FOREIGN KEY (Server) REFERENCES server(Id)
);
CREATE TABLE connessione (
	Id INT PRIMARY KEY,
    IP VARCHAR(20),
    Dispositivo INT,
    Cliente INT,
    Inizio TIMESTAMP,
    Fine TIMESTAMP,
    Server INT,
    Paese VARCHAR(10),
    FOREIGN KEY (Cliente) REFERENCES cliente(Id),
    FOREIGN KEY (Dispositivo) REFERENCES dispositivo(Id),
    FOREIGN KEY (Server) REFERENCES server(Id),
    FOREIGN KEY (Paese) REFERENCES paese(Cod)
);











# viene verificata l'esistenza della connessione, e la compatibilità tra inizi e fine
# non viene verificata la presenza di un file nel server (anche perchè nel durante il popolamento generale non ha senso)
# se facessimo altri controlli, oltre a rendere piò difficile il popolamento si raddoppiano i controlli
# l'aggiornamento delle ridondanze viene fatto

CREATE TABLE visualizzazione ( 
    Connessione INT,
    File INT,
    Inizio TIMESTAMP,
    Fine TIMESTAMP,
    PRIMARY KEY (Connessione, File, Inizio),
    FOREIGN KEY (Connessione) REFERENCES connessione(Id)
);
DELIMITER //
CREATE TRIGGER trg_check_visualizzazione
BEFORE INSERT ON visualizzazione
FOR EACH ROW
BEGIN
    DECLARE conn_inizio DATETIME;
    DECLARE conn_fine DATETIME;
    DECLARE film_file INT;

    -- Ottieni l'inizio e la fine della connessione corrispondente
    SELECT Inizio, Fine INTO conn_inizio, conn_fine
    FROM Connessione
    WHERE Id = NEW.Connessione;

    -- Verifica che l'inizio della visualizzazione sia maggiore o uguale all'inizio della connessione
    IF NEW.Inizio < conn_inizio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L\'inizio della visualizzazione deve essere maggiore o uguale all\'inizio della connessione.';
    END IF;

    -- Verifica che se Fine è non null, sia minore o uguale alla fine della connessione
    IF NEW.Fine IS NOT NULL AND NEW.Fine > conn_fine THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La Fine della visualizzazione deve essere minore o uguale alla Fine della connessione.';
    END IF;
    
    IF NEW.Fine IS NULL AND conn_fine IS NOT NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La Fine della visualizzazione deve essere minore o uguale alla Fine della connessione.';
    END IF;
    
    -- Ottieni Id del film
    SELECT Film INTO film_file
    FROM File
    WHERE NEW.File = File.Id;
    
    UPDATE film
	SET nVisualizzazioni = nVisualizzazioni + 1
	WHERE Id = film_file;
    
		
END;
//
DELIMITER ;
# viene verificata l'esistenza di una visualizzazione 
# vengono aggiornate le ridondanze (rating medio)
CREATE TABLE recensione (
    Film INT,
    Cliente INT,       
    Voto INT,
    Data TIMESTAMP,
    PRIMARY KEY (Film, Cliente),
    FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Cliente) REFERENCES cliente(Id)
);
DELIMITER //
CREATE TRIGGER trg_check_recensione
BEFORE INSERT ON recensione
FOR EACH ROW
BEGIN
	DECLARE controllo_vis INT;
    DECLARE num_recensioni INT; # numero recensioni prima dell'inserimento del film
    
    # fai la query che cerca una visualizzazione compatibile
    SELECT COUNT(*) INTO controllo_vis
    FROM connessione 
    JOIN visualizzazione ON visualizzazione.Connessione = connessione.Id
    JOIN file ON visualizzazione.File = file.Id
	WHERE connessione.Cliente = NEW.Cliente AND
		  file.Film = NEW.Film ;
          
	# controlla il risultato
    IF controllo_vis = 0 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il cliente non ha mai guardato questo film';
    END IF;
    
    
    # num_recensioni
    SELECT COUNT(*) INTO num_recensioni
    FROM recensione 
    WHERE Film = NEW.Film;
    
	# aggiorna rating medio
	UPDATE Film
	SET RatingMedio = (num_recensioni * RatingMedio + NEW.Voto) / (num_recensioni + 1)
	WHERE Id = NEW.Film;
END;
//
DELIMITER ;
