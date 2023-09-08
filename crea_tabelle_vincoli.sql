# crea tutte le tabelle, tranne iprange, server, paese
# con chiavi esterne e vincoli generici

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
    NomeFormato VARCHAR(50),
    Risoluzione VARCHAR(32),
    Bitrate INT,
    qAudio FLOAT,
    qVideo FLOAT
);
CREATE TABLE cliente (
    Id INT PRIMARY KEY,
    Nome VARCHAR(32),
    Cognome VARCHAR(32),
    Email VARCHAR(100),
    Password VARCHAR(32)
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











CREATE TABLE connessione (
	Id INT PRIMARY KEY,
    IP VARCHAR(20),
    Dispositivo INT,
    Cliente INT,
    Inizio TIMESTAMP,
    Fine TIMESTAMP,
    Server INT,
    FOREIGN KEY (Cliente) REFERENCES cliente(Id),
    FOREIGN KEY (Dispositivo) REFERENCES dispositivo(Id),
    FOREIGN KEY (Server) REFERENCES server(Id)
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
	FOREIGN KEY (PaeseProduzione) REFERENCES paese(Cod),
    FOREIGN KEY (Regista) REFERENCES regista(Id)
);

# fino a qui funziona l'inserimento di tabelle





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


/*


CREATE TABLE visualizzazione (
    Connessione INT,
    File INT,
    Inizio TIMESTAMP,
    Fine TIMESTAMP,
    PRIMARY KEY (Connessione, File, Inizio),
    FOREIGN KEY (Connessione) REFERENCES connessione(Id)
);




CREATE TABLE recensione (
    Film INT,
    Cliente INT,       
    Votazione INT,
    Data TIMESTAMP,
    PRIMARY KEY (Film, Cliente),
    FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Cliente) REFERENCES clienti(Id)
);

/*

