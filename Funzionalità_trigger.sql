# tutte le funzioni e le procedure, più i trigger che non vanno messi prima del popolamento
DROP PROCEDURE IF EXISTS RichiediVisualizzazione;
DROP PROCEDURE IF EXISTS TerminaVisualizzazione;
DROP FUNCTION IF EXISTS GetCountryByIP;
drop procedure if exists InserisciConnessione;
drop procedure if exists Disconnessione;
drop TRIGGER if exists trg_ins_con;
drop FUNCTION if exists CalcolaDistanza;
DROP PROCEDURE IF EXISTS Caching;
DROP PROCEDURE IF EXISTS InserisciFile;
DROP FUNCTION IF EXISTS RatingZona;
DROP PROCEDURE IF EXISTS InserisciRecensione;
DROP PROCEDURE IF EXISTS ConsigliaFilm;
DROP PROCEDURE IF EXISTS InserisciSottoscrizione;
DROP FUNCTION IF EXISTS RatingPersnalizzato;

DROP PROCEDURE IF EXISTS ClassificaFilmPaese;
DROP PROCEDURE IF EXISTS ClassificaFilmArea;
DROP PROCEDURE IF EXISTS ClassificaFormatiPaese;
DROP PROCEDURE IF EXISTS ClassificaFormatiArea;

DROP FUNCTION IF EXISTS LivelloMassimoConsentito;
DROP FUNCTION IF EXISTS Compatibile;


# funzione Livello massimo consentito, non testata
DELIMITER //
CREATE FUNCTION LivelloMassimoConsentito(Abb_ VARCHAR(20)) 
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE max_cons VARCHAR(20);
    
    SELECT Contenuti into max_cons
    FROM pianotariffario
    WHERE Nome = Abb_;
    
    IF max_cons = 'Limitati' THEN 
		RETURN 0;
    ELSEIF max_cons = 'Standard' THEN
		RETURN 1;
	ELSEIF max_cons = 'Extra' THEN
		RETURN 2;
	ELSE
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Piano tariffario inesistente';
	END IF;
END;
//
DELIMITER ;


# funzione Livello compatibile, non testata
DELIMITER //
CREATE FUNCTION Compatibile(Abb_ VARCHAR(20), Formato_ INT) 
RETURNS BOOL
READS SQL DATA
BEGIN
    DECLARE max_cons VARCHAR(20);
    DECLARE q_formato VARCHAR(20);
    
    SELECT QualitaMax into max_cons
    FROM pianotariffario
    WHERE Nome = Abb_;
    
    SELECT qVideo INTO q_formato
    FROM formato
    WHERE formato.Id = Formato_;
    
    IF max_cons = 'SD' THEN 
		IF q_formato = 'SD' THEN
			RETURN True;
		ELSE RETURN False;
        END IF;
    ELSEIF max_cons = 'HD' THEN
		IF q_formato = 'SD' OR q_formato = 'HD' THEN
			RETURN True;
		ELSE RETURN False;
        END IF;
	ELSEIF max_cons = 'UHD' THEN
		RETURN True;
	ELSE
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Piano tariffario inesistente';
	END IF;
END;
//
DELIMITER ;



# funzione distanza
DELIMITER //
CREATE FUNCTION CalcolaDistanza(Conn INT, Serv INT) 
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE dist DECIMAL(10, 2);
    DECLARE lat_paese FLOAT;
    DECLARE lng_paese FLOAT;
    DECLARE lat_serv FLOAT;
    DECLARE lng_serv FLOAT;
    
    SELECT Paese.Lat, Paese.Lng INTO lat_paese, lng_paese
    FROM connessione JOIN paese on connessione.Paese = paese.Cod
    WHERE connessione.Id = Conn;
    
    SELECT server.Lat, server.Lng INTO lat_serv, lng_serv
    FROM server
    WHERE server.Id = Serv;
    
    SET dist = ST_Distance_Sphere(POINT(lng_serv, lat_serv), POINT(lng_paese, lat_paese)) / 1000;
    # distanza in chilometri
    RETURN dist;
END;
//
DELIMITER ;




# funzione GetCountryByIP
DELIMITER //
CREATE FUNCTION GetCountryByIP(ip VARCHAR(100)) 
RETURNS VARCHAR(255)
READS SQL DATA
BEGIN
    DECLARE country VARCHAR(255);
    
    SELECT Paese INTO country
    FROM iprange
    WHERE INET_ATON(ip) >= INET_ATON(Start) AND INET_ATON(ip) <= INET_ATON(End)
    LIMIT 1;
    RETURN country;
END;
//
DELIMITER ;



# funzione inserimento connessione
DELIMITER //
CREATE PROCEDURE InserisciConnessione (IN password_ VARCHAR(20), IN cliente_ INT, IN IP_ VARCHAR(30), IN dispositivo_ INT)
BEGIN
	DECLARE id_max INT;
	# controlla la password
    IF password_ <> (
		SELECT Password
        FROM cliente
        WHERE Id = cliente_
    ) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password Errata';
	END IF;
    
    # controlla l'ultimo id
    SELECT MAX(Id) INTO id_max
    FROM Connessione;

    INSERT INTO connessione (Id, IP, Dispositivo, Cliente, Inizio, Fine, Server, Paese) 
					 VALUES (id_max + 1, IP_, dispositivo_, cliente_, current_time(), NULL, NULL, NULL);
    # qui scatta il trigger che:
    # fai i controlli relativi a cliente.Scadenza
    # controlla che il cliente non abbia connessioni aperte
    # associa IP_ a paese
END //
DELIMITER ;



# funzione disconnessione
DELIMITER //
CREATE PROCEDURE Disconnessione (IN cliente_ INT)
BEGIN
	DECLARE connessione_attiva INT;
	# controlla che il cliente sia effettivamento connesso
    
    SELECT Id into connessione_attiva
    FROM connessione
	WHERE connessione.Fine IS NULL AND
          connessione.Cliente = cliente_;
	
	IF connessione_attiva IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il cliente inserito non è connesso';
	ELSE
		# stoppa un'eventuale visualizzazione in corso, se c'è
        IF EXISTS (
			SELECT *
			FROM visualizzazione
			WHERE visualizzazione.Connessione = connessione_attiva AND
				  visualizzazione.Fine IS NULL
        ) THEN
			CALL TerminaVisualizzazione(cliente_);
		END IF;
        UPDATE connessione
        SET Fine = current_timestamp()
        WHERE Id = connessione_attiva;
        
        
    
	END IF;
END //
DELIMITER ;



# trigger inserimento connessione
DELIMITER //
CREATE TRIGGER trg_ins_con # trigger mette il paese
BEFORE INSERT ON Connessione
FOR EACH ROW
BEGIN
    DECLARE paese_cod VARCHAR(10);
    SELECT GetCountryByIP(NEW.IP) INTO paese_cod;
    IF paese_cod IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'IP non associato a nessun paese';
	ELSE 
		SET NEW.Paese = paese_cod;
	END IF;
    
    IF current_timestamp() > (
		SELECT Scadenza
        FROM cliente
        WHERE cliente.Id = NEW.Cliente
    ) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Abbonamento Scaduto';
	END IF;
    
    
    IF NEW.Cliente IN ( # controlla se ci sono già connessione attive con la stesso cliente
    SELECT connessione.Cliente
    FROM connessione
    WHERE connessione.Fine IS NULL
    ) THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Cliente già connesso';
	END IF;
    
END;
//
DELIMITER ;





# funzione richiesta visualizzazione
# qui manca il controllo della compatibilità con i formati, quando si inserisce va anche ripopolato mettendo molti più file, e valori sensati di formati
DELIMITER //
CREATE PROCEDURE RichiediVisualizzazione (IN cliente_ INT, IN film_ INT)
BEGIN
	DECLARE connessione_attiva INT;
    DECLARE file_scelto INT;
    DECLARE server_scelto INT;
    DECLARE lat_con FLOAT;
    DECLARE lng_con FLOAT;
    DECLARE pt_cliente VARCHAR(20);
    DECLARE paese_con VARCHAR(10);
    
	# controlla che il cliente sia effettivamento connesso
    SELECT Id into connessione_attiva
    FROM connessione
	WHERE connessione.Fine IS NULL AND
          connessione.Cliente = cliente_;
	IF connessione_attiva IS NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il cliente inserito non è connesso';
	END IF;
    
    
    
    # controlla che non ci siano altre visualizzazioni attive
    IF EXISTS (SELECT *
    FROM visualizzazione
    WHERE visualizzazione.Connessione = connessione_attiva AND
    visualizzazione.Fine IS NULL) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il cliente sta già guardando un contenuto';
	END iF;
    
    SELECT Paese into paese_con
    FROM connessione
    WHERE Id = connessione_attiva;

    # AGGIUNGI il controllo della compatibilità tra il livello del contenuto e il file
    SELECT Abbonamento into pt_cliente
    FROM cliente
    WHERE cliente.Id = cliente_;
    
    # controlla se il cliente ha un abbonamento compatibile con il film richiesto 
    IF (
		SELECT LivelloContenuto
		FROM film
		WHERE Id = film_
    ) > LivelloMassimoConsentito(pt_cliente) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Contenuto non incluso nel piano tariffario';    
	END IF;
    
    # prendi i file compatibili con la richiesta, in termini di qualità e di formato consentito
    # e restituisci il migliore in base a posizione e carico del server in cui si trova
    SELECT file.Id, Server.Id into file_scelto, server_scelto
    FROM file JOIN Server ON file.Server = Server.Id
    WHERE file.Film = film_
    AND file.Formato NOT IN (
		SELECT nonsupportato.Formato
        FROM nonsupportato
        WHERE nonsupportato.Paese = paese_con
    ) and 
    Compatibile(pt_cliente, file.Formato) = True and 
    server.Carico + (                    # bitrate
		SELECT formato.Bitrate / server.Capacità
        FROM formato
        WHERE formato.Id = file.Formato
    ) <= 1
    ORDER BY (10 ^ (2 * server.Carico) + CalcolaDistanza(connessione_attiva, server.Id) / 100) ASC
    LIMIT 1;
    
    # se non hai trovato un file adatto
    IF file_scelto IS NULL THEN 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nessun file compatibile con la richiesta';    
	END IF;
    
    
    # crea istanza di visualizzazione
    INSERT INTO visualizzazione (Connessione, File, Inizio, Fine)
						VALUES (connessione_attiva, file_scelto, current_timestamp(), NULL);
    # metti server_scelto in connessione
    UPDATE connessione
    SET Server = server_scelto 
    WHERE connessione.Id = connessione_attiva;
    # aggiorna il carico 

    UPDATE server
    SET Carico = Carico + (
		SELECT Bitrate 
        FROM formato join file on file.Formato = Formato.Id
        WHERE file.Id = file_scelto
    ) / Capacità
    WHERE Id = server_scelto;
    
    
    
    
    
    # se il carico del server scelto ha superato una certa soglia di carico
    IF (
		SELECT Carico
        FROM server
        WHERE server.Id = server_scelto
    ) > 0.05 THEN
    # prendi le connessioni che stanno streammando su quel server e valuta lo spostamento del server
    # tutto avviene senza interrompere le visualizzazioni
	
		# spostare il file
        UPDATE file
        SET Server = ( # server migliore
			SELECT s.Id
            FROM server s
            ORDER BY (10 ^ (2 * s.Carico) + CalcolaDistanza(connessione_attiva, s.Id) / 100) ASC
			LIMIT 1
        )
        WHERE file.Id = (
			SELECT visualizzazione.File
            FROM visualizzazione
            WHERE visualizzazione.Connessione = connessione_attiva
        );        
        # spostare la connessione
		UPDATE connessione
        SET Server = ( # server migliore
			SELECT s.Id
            FROM server s
            ORDER BY (10 ^ (2 * s.Carico) + CalcolaDistanza(connessione_attiva, s.Id) / 100) ASC
			LIMIT 1
        )
        WHERE connessione.Server = server_scelto;
        
		# aggiornare i carichi dei server 
        UPDATE server s 
        SET s.Carico = IF(
        EXISTS ( # esistono file che stanno streammando
			SELECT *
            FROM visualizzazione 
            JOIN file on visualizzazione.File = file.Id
            WHERE visualizzazione.Fine IS NULL AND
            file.Server = s.Id
        ),
        (  # somma dei bitrate
			SELECT SUM(formato.Bitrate) / s.Capacità
			FROM file join formato on file.Formato = formato.Id
			WHERE file.Server = s.Id
            AND file.Id IN (
				SELECT visualizzazione.File
                FROM visualizzazione
                WHERE visualizzazione.Fine IS NULL
            )
        ), 0 # altrimenti 0
        );
         
	END IF;
END //
DELIMITER ;



# funzione termina visualizzazione
DELIMITER //
CREATE PROCEDURE TerminaVisualizzazione (IN cliente_ INT)
BEGIN
	# controlla che ci siano visualizzazioni attive di cliente_
    IF NOT EXISTS (
    SELECT *
    FROM visualizzazione JOIN connessione on visualizzazione.Connessione = connessione.Id
    WHERE connessione.Cliente = cliente_ AND
    visualizzazione.Fine IS NULL) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il cliente non sta guardando nessun film';
	END IF;
    
    

    # rimuovi il carico dal server
    UPDATE server
    SET Carico = Carico - (
		SELECT formato.Bitrate / server.Capacità
        FROM formato JOIN file on file.Formato = formato.Id
        WHERE file.Id = (
			SELECT visualizzazione.File
            FROM visualizzazione JOIN connessione on visualizzazione.Connessione = connessione.Id
            WHERE connessione.Cliente = cliente_ and visualizzazione.Fine IS NULL
        )
    )
    WHERE server.Id = (
		SELECT connessione.Server
		FROM connessione JOIN visualizzazione ON visualizzazione.Connessione = connessione.Id
		WHERE connessione.Cliente = cliente_ AND
		visualizzazione.Fine IS NULL
    );
    
    # rimuovi server da connessione
    UPDATE connessione
    SET Server = NULL
    WHERE connessione.Cliente = cliente_ AND
		  connessione.Fine IS NULL;
	
    
	UPDATE visualizzazione # finisci la visualizzazione
    SET Fine = current_timestamp()
    WHERE visualizzazione.Connessione = (
		SELECT connessione.Id
        FROM connessione
        WHERE connessione.Cliente = cliente_ AND
        connessione.Fine IS NULL
    );
    
    
    
    
END //
DELIMITER ;



# funzione RatingPersonalizzato
DELIMITER //
CREATE FUNCTION RatingPersnalizzato(Film_ INT, Cliente_ INT) 
RETURNS DECIMAL(10, 4)
READS SQL DATA
BEGIN
    DECLARE r_Regista FLOAT;
    DECLARE r_Genere FLOAT;
    DECLARE r_Attori FLOAT;
    DECLARE r_PaeseProduzione FLOAT;
    DECLARE r_Critica FLOAT;
    DECLARE r_medio_film FLOAT;
    DECLARE r_visual FLOAT;
    
    DECLARE f_regista INT;
    DECLARE f_genere VARCHAR(25);
    DECLARE f_paese VARCHAR(10);
    
    SELECT Regista, Genere, PaeseProduzione into f_regista, f_genere, f_paese
    FROM film
    WHERE film.Id = Film_;
    
    SELECT IF(
    0 = (SELECT COUNT(*)   
    FROM recensione 
    JOIN film ON recensione.Film = film.Id
    WHERE recensione.Cliente = Cliente_ AND film.Regista = f_regista),
    (SELECT AVG(recensione.Voto)                  # voto medio di tutte le recensioni a film con regista di Film_
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
		WHERE film.Regista = f_regista),
	(SELECT AVG(recensione.Voto)              # voto medio di tutte le recensioni a film con regista di Film_, date da Cliente_
    FROM recensione 
    JOIN film ON recensione.Film = film.Id
    WHERE recensione.Cliente = Cliente_ AND film.Regista = f_regista)
    )
	INTO r_Regista;
    
    SELECT IF(
    0 = (
		SELECT COUNT(*)   
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
		WHERE recensione.Cliente = Cliente_ AND film.PaeseProduzione = f_paese
	),
    (
		SELECT AVG(recensione.Voto)             # voto medio di tutte le recensioni a film con paeseProduzione di Film_
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
		WHERE film.PaeseProduzione = f_paese
	),
	(
		SELECT AVG(recensione.Voto)     # voto medio di tutte le recensioni a film con paeseProduzione di Film_, date da Cliente_
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
		WHERE recensione.Cliente = Cliente_ AND film.PaeseProduzione = f_paese
	)
    )
	INTO r_PaeseProduzione;
    
    SELECT IF(
    0 = (
		SELECT COUNT(*)   
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
		WHERE recensione.Cliente = Cliente_ AND film.Genere = f_genere),
    (	
		SELECT AVG(recensione.Voto)             # voto medio di tutte le recensioni a film con genere di Film_
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
		WHERE film.Genere = f_genere),
	(
		SELECT AVG(recensione.Voto)     # voto medio di tutte le recensioni a film con genere di Film_, date da Cliente_
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
		WHERE recensione.Cliente = Cliente_ AND film.Genere = f_genere)
    )
	INTO r_Genere;
    
    SELECT IF(
    0 = (SELECT COUNT(*)   # recensioni di Cliente a film che contengono almeno un attore in comune con Film_
    FROM recensione 
    JOIN film ON recensione.Film = film.Id
    JOIN parte on parte.Film = film.Id
    WHERE recensione.Cliente = Cliente_ AND parte.Attore IN (
		SELECT Attore   # attori di Film_
        FROM parte 
        WHERE parte.Film = Film_
    ) ),
    (SELECT AVG(recensione.Voto)  # voto medio di tutte le recensioni di tutti i film che hanno almeno un attore in comune con Film_
		FROM recensione 
		JOIN film ON recensione.Film = film.Id
        JOIN parte on parte.Film = film.Id
		WHERE parte.Attore IN (
			SELECT Attore   # attori di Film_
			FROM parte 
			WHERE parte.Film = Film_
    ) ),
	(SELECT AVG(recensione.Voto)     # voto medio di tutte le recensioni di tutti i film che hanno almeno un attore in comune con Film_, date da Cliente_
    FROM recensione 
    JOIN film ON recensione.Film = film.Id
    JOIN parte on parte.Film = film.Id
    WHERE recensione.Cliente = Cliente_ AND parte.Attore IN (
		SELECT Attore   # attori di Film_
        FROM parte 
        WHERE parte.Film = Film_
    ) )
    )
	INTO r_Attori;
    
    SELECT avg(Voto) INTO r_Critica
    FROM critica
    WHERE Film = Film_;
    IF r_Critica IS NULL THEN 
		SET r_Critica = 5;
	END IF;
    
    SELECT RatingMedio INTO r_medio_film
    FROM film
    WHERE Id = film_;
    IF r_medio_film IS NULL THEN 
		SET r_medio_film = 5;
	END IF;
    
    SELECT 10 * nVisualizzazioni / (
		SELECT MAX(film.nVisualizzazioni)
        FROM film
    ) into r_visual
	FROM film
    WHERE Id = film_;
	
    # mancano premi, 
    # mancano i pesi per le preferenze
    
    RETURN (r_Regista + r_PaeseProduzione + r_Genere + r_Attori + r_Critica + r_medio_film + r_visual) / 7;
    
END;
//
DELIMITER ;




# funzione caching
# fatto ma al momento troppo lento per essere fatto
DELIMITER //
CREATE PROCEDURE Caching(IN rapporto FLOAT)
BEGIN
	DECLARE resto INT;
	# verifica il rapporto
    IF rapporto > 1 OR rapporto < 0.001 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rapporto non valido';
	END IF;
    SET resto = ROUND((RAND() * 1000), 0) % ROUND(1 / rapporto, 0);
    
    
    UPDATE file
    SET Server = (
		# server nell'area geografica è più apprezzato
		SELECT server.Id
        FROM server
        ORDER BY RatingZona(server.Id, file.Film) desc
        LIMIT 1
    )
    WHERE file.Id not in (
		SELECT visualizzazione.File
        FROM visualizzazione
        WHERE visualizzazione.Fine IS NULL
    ) AND file.Id % ROUND(1 / rapporto, 0) = resto;
    
END //
DELIMITER ;





# funzione RatingZona
DELIMITER //
CREATE FUNCTION RatingZona(Area_ INT, Film_ INT) 
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
	DECLARE r FLOAT;
    # conta quante visualizzazioni ha avuto da residenti dell'area
	SELECT count(*) into r
    FROM file
    right JOIN visualizzazione on visualizzazione.File = file.Id
    JOIN connessione on visualizzazione.Connessione = connessione.Id
    JOIN cliente on connessione.Cliente = cliente.Id
	JOIN paese on cliente.PaeseResidenza = paese.Cod
    WHERE paese.AreaGeografica = Area_ and file.Film = Film_;
    
    RETURN r;
END;
//
DELIMITER ;





# funzione inserimento file
DELIMITER //
CREATE PROCEDURE InserisciFile(IN Film_ INT, IN Formato_ INT, IN Dimensione_ INT, IN DurataVideo_ INT)
BEGIN
	DECLARE id_max INT;

	# trova il server migliore
    DECLARE server_migliore VARCHAR(10);
    
	SELECT paese.AreaGeografica into server_migliore
	FROM cliente
	JOIN paese ON paese.Cod = cliente.PaeseResidenza
	GROUP BY paese.AreaGeografica
	ORDER BY avg(RatingPersnalizzato(Film_, cliente.Id)) desc
	limit 1;
    
    
	
	# controlla l'ultimo id
    SELECT MAX(Id) INTO id_max
    FROM file;

    
    # fai l'inserimento
    INSERT INTO file (Id, Film, Formato, DataInserimento, Dimensione, Durata, Server) 
    VALUES (id_max + 1, Film_, Formato_, current_timestamp(), Dimensione_, DurataVideo_, server_migliore);
    # il trigger già presente controllerà se il film esiste
    
END //
DELIMITER ;


# funzione inserimento recensione
DELIMITER //
CREATE PROCEDURE InserisciRecensione(IN Film_ INT, IN Cliente_ INT, IN Voto_ FLOAT)
BEGIN
	DECLARE id_max INT;
	# controlla se cliente è connesso alla piattaforma
    IF NOT EXISTS (
		SELECT *
		FROM connessione
		WHERE connessione.Fine IS NULL AND
        connessione.Cliente = Cliente_
    ) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il cliente non è connesso';
	END IF;
    
	# controlla l'ultimo id
    SELECT MAX(Id) INTO id_max
    FROM recensione;
    
    # fai l'inserimento
    INSERT INTO recensione (Id, Film, Cliente, Voto, Data) 
    VALUES (id_max + 1, Film_, Cliente_, Voto_, current_timestamp());
    # il trigger già presente controllerà se il cliente ha già visto il film
    
END //
DELIMITER ;





# funzione consiglia film, non ancora testata
DELIMITER //
CREATE PROCEDURE ConsigliaFilm(IN Cliente_ INT)
BEGIN
	# verifica che il cliente selezionato è connesso alla piattaforma
    IF NOT EXISTS (
		SELECT *
        FROM connessione JOIN cliente on cliente.Id = connessione.Cliente
        WHERE connessione.Fine IS NULL AND cliente.Id = Cliente_
    ) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il cliente non è connesso';
	END IF;
    
    SELECT film.*
    FROM film
    ORDER BY RatingPersnalizzato(film.Id, Cliente_) desc
    LIMIT 10;
END //
DELIMITER ;




# funzione inserisci sottoscrizione, non ancora testata 
DELIMITER //
CREATE PROCEDURE InserisciSottoscrizione(IN CartadiCredito_ VARCHAR(50), IN PianoTariffario_ VARCHAR(50))
BEGIN
	INSERT INTO sottoscrizione (CartadiCredito, Data, PianoTariffario)
		VALUES (CartadiCredito_, current_timestamp(), PianoTariffario_);
	# il trigger fa i controlli e gli aggiornamenti
END //
DELIMITER ;



# funzione classifica film più visti in un dato paese
DELIMITER //
CREATE PROCEDURE ClassificaFilmPaese(IN paese_ VARCHAR(50))
BEGIN
	WITH FilmVisualizzati AS (
		SELECT Film.*, COUNT(visualizzazione.File) AS VisualizzazioniInPaese
        FROM cliente 
		JOIN connessione ON cliente.Id = connessione.Cliente
		JOIN visualizzazione ON connessione.Id = visualizzazione.Connessione
		JOIN file ON visualizzazione.File = file.Id
		JOIN film ON file.Film = film.Id
		WHERE cliente.PaeseResidenza = paese_
		GROUP BY file.Film
	)
	SELECT RANK() OVER (ORDER BY VisualizzazioniInPaese DESC) AS Ranking, FilmVisualizzati.*
	FROM FilmVisualizzati
	ORDER BY Ranking;

END //
DELIMITER ;



# funzione classifica film più visti una certa area
DELIMITER //
CREATE PROCEDURE ClassificaFilmArea(IN area_ INT)
BEGIN
	WITH FilmVisualizzati AS (
		SELECT Film.*, COUNT(visualizzazione.File) AS VisualizzazioniInArea
        FROM cliente 
		JOIN connessione ON cliente.Id = connessione.Cliente
		JOIN visualizzazione ON connessione.Id = visualizzazione.Connessione
		JOIN file ON visualizzazione.File = file.Id
		JOIN film ON file.Film = film.Id
		WHERE cliente.PaeseResidenza IN (
			SELECT paese.Cod
            FROM paese
            WHERE paese.AreaGeografica = area_
        )
		GROUP BY file.Film
	)
	SELECT RANK() OVER (ORDER BY VisualizzazioniInArea DESC) AS Ranking, FilmVisualizzati.*
	FROM FilmVisualizzati
	ORDER BY Ranking;

END //
DELIMITER ;




# funzione classifica formati paese, testata
DELIMITER //
CREATE PROCEDURE ClassificaFormatiPaese(IN paese_ VARCHAR(50))
BEGIN
	WITH FormatiVisualizzati AS (
		SELECT Formato.*, COUNT(visualizzazione.File) AS VisualizzazioniInPaese
        FROM cliente 
		JOIN connessione ON cliente.Id = connessione.Cliente
		JOIN visualizzazione ON connessione.Id = visualizzazione.Connessione
		JOIN file ON visualizzazione.File = file.Id
		JOIN formato ON file.Formato = formato.Id
		WHERE cliente.PaeseResidenza = paese_
		GROUP BY file.Formato
	)
	SELECT RANK() OVER (ORDER BY VisualizzazioniInPaese DESC) AS Ranking, FormatiVisualizzati.*
	FROM FormatiVisualizzati
	ORDER BY Ranking;

END //
DELIMITER ;




# funzione classifica formati paese, testata
DELIMITER //
CREATE PROCEDURE ClassificaFormatiArea(IN area_ VARCHAR(50))
BEGIN
	WITH FormatiVisualizzati AS (
		SELECT Formato.*, COUNT(visualizzazione.File) AS VisualizzazioniInArea
        FROM cliente 
		JOIN connessione ON cliente.Id = connessione.Cliente
		JOIN visualizzazione ON connessione.Id = visualizzazione.Connessione
		JOIN file ON visualizzazione.File = file.Id
		JOIN formato ON file.Formato = formato.Id
		WHERE cliente.PaeseResidenza IN (
			SELECT paese.Cod
            FROM paese
            WHERE paese.AreaGeografica = area_
        )
		GROUP BY file.Formato
	)
	SELECT RANK() OVER (ORDER BY VisualizzazioniInArea DESC) AS Ranking, FormatiVisualizzati.*
	FROM FormatiVisualizzati
	ORDER BY Ranking;

END //
DELIMITER ;







# ricavi divisi per area geografica

# ricavi divisi per film



