

CREATE SCHEMA filmSphere;
USE filmSphere;

# creazione tabelle
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
  PRIMARY KEY (Cod),
  FOREIGN KEY (AreaGeografica) REFERENCES server(Id)
);
CREATE TABLE iprange (
  Start varchar(32) NOT NULL,
  End varchar(32) DEFAULT NULL,
  Paese varchar(4) DEFAULT NULL,
  PRIMARY KEY (Start),
  FOREIGN KEY (Paese) REFERENCES paese (Cod)
);




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
    CodecVideo VARCHAR(50),
    CodecAudio VARCHAR(50),
    Risoluzione VARCHAR(32),
    Bitrate INT,
    QualitaVideo VARCHAR(10)
);
CREATE TABLE dispositivo (
    Id INT PRIMARY KEY,
    AziendaProduttrice VARCHAR(50),
    Modello VARCHAR(100),
    RAM INT,
    Risoluzione VARCHAR(40)
);
CREATE TABLE pianoTariffario (
    Nome VARCHAR(20) PRIMARY KEY,
    Prezzo FLOAT,
    Contenuti VARCHAR(30),
    Pubblicita VARCHAR(30),
    QualitaMax VARCHAR(30)
);
CREATE TABLE critico (
    Id INT PRIMARY KEY,
    Nome VARCHAR(20),
    Cognome VARCHAR(20)
);
CREATE TABLE lingua (
    Nome VARCHAR(30) PRIMARY KEY
);
CREATE TABLE cliente (
    Id INT PRIMARY KEY,
    Nome VARCHAR(32),
    Cognome VARCHAR(32),
    Email VARCHAR(100),
    Password VARCHAR(32),
    Abbonamento VARCHAR(20),
    Scadenza TIMESTAMP,
    PaeseResidenza VARCHAR(10),
    FOREIGN KEY (Abbonamento) REFERENCES pianotariffario(Nome),
    FOREIGN KEY (PaeseResidenza) REFERENCES paese(Cod)
);
CREATE TABLE cartaDiCredito (
    Numero VARCHAR(30) PRIMARY KEY,
    DataScadenza TIMESTAMP,
    Circuito VARCHAR(30),
    Proprietario INT,
    FOREIGN KEY (Proprietario) REFERENCES cliente(Id)
); 

CREATE TABLE sottoscrizione (
	Id INT PRIMARY KEY,
    CartadiCredito VARCHAR(30),
    Data TIMESTAMP,
    PianoTariffario VARCHAR(20),
    FOREIGN KEY (CartadiCredito) REFERENCES cartadicredito(Numero),
    FOREIGN KEY (PianoTariffario) REFERENCES pianotariffario(Nome)
);


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
    #RatingMedio FLOAT DEFAULT 5,
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

CREATE TABLE linguaSottotitoli (
    Film INT,
    Lingua VARCHAR(40),
    PRIMARY KEY (Film, Lingua),
	FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Lingua) REFERENCES lingua(Nome)
);
CREATE TABLE linguaAudio (
    Film INT,
    Lingua VARCHAR(40),
    PRIMARY KEY (Film, Lingua),
	FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Lingua) REFERENCES lingua(Nome)
);
CREATE TABLE critica (
	Id INT PRIMARY KEY,
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

CREATE TABLE nonSupportato (
    File INT,
    Paese VARCHAR(10),
    PRIMARY KEY (File, Paese),
    FOREIGN KEY (File) REFERENCES file(Id),
    FOREIGN KEY (Paese) REFERENCES paese(Cod)
);
CREATE TABLE connessione (
	Id INT PRIMARY KEY,
    IP VARCHAR(20),
    Dispositivo INT,
    Cliente INT,
    Inizio TIMESTAMP,
    Fine TIMESTAMP,
    Paese VARCHAR(10),
    FOREIGN KEY (Cliente) REFERENCES cliente(Id),
    FOREIGN KEY (Dispositivo) REFERENCES dispositivo(Id),
    FOREIGN KEY (Paese) REFERENCES paese(Cod)
);

CREATE TABLE visualizzazione ( 
	Id INT PRIMARY KEY,
    Connessione INT,
    File INT,
    Inizio TIMESTAMP,
    Fine TIMESTAMP,
    FOREIGN KEY (Connessione) REFERENCES connessione(Id)
);

CREATE TABLE recensione (
	Id INT PRIMARY KEY,
    Film INT,
    Cliente INT,       
    Voto INT,
    Data TIMESTAMP,
    FOREIGN KEY (Film) REFERENCES film(Id),
    FOREIGN KEY (Cliente) REFERENCES cliente(Id)
);






