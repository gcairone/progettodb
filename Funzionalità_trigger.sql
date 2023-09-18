# contiene trigger, operazioni sui dati e analytics
DROP PROCEDURE IF EXISTS ClassificaFilmPaese;
DROP PROCEDURE IF EXISTS ClassificaFilmArea;
DROP PROCEDURE IF EXISTS ClassificaFormatiPaese;
DROP PROCEDURE IF EXISTS ClassificaFormatiArea;
DROP PROCEDURE IF EXISTS ConsigliaFilm;
DROP PROCEDURE IF EXISTS AnalisiRicavi;

DROP PROCEDURE IF EXISTS RichiediVisualizzazione;
DROP PROCEDURE IF EXISTS TerminaVisualizzazione;
drop procedure if exists InserisciConnessione;
drop procedure if exists Disconnessione;
DROP PROCEDURE IF EXISTS InserisciFile;
DROP PROCEDURE IF EXISTS InserisciRecensione;
DROP PROCEDURE IF EXISTS InserisciSottoscrizione;
DROP FUNCTION IF EXISTS RatingPersonalizzato;
DROP EVENT IF EXISTS Caching;

DROP TRIGGER IF EXISTS trg_ins_sottoscrizione;
DROP TRIGGER IF EXISTS trg_ins_connessione;
DROP TRIGGER IF EXISTS trg_ins_visualizzazione;
DROP TRIGGER IF EXISTS trg_ins_recensione;
DROP TRIGGER IF EXISTS trg_ins_premio;
DROP TRIGGER IF EXISTS trg_ins_cartadicredito;
DROP TRIGGER IF EXISTS trg_upd_file;
DROP TRIGGER IF EXISTS trg_upd_visualizzazione;

DROP FUNCTION IF EXISTS LivelloMassimoConsentito;
DROP FUNCTION IF EXISTS Compatibile;
DROP FUNCTION IF EXISTS GetCountryByIP;
DROP PROCEDURE IF EXISTS SpostamentoCaching;
DROP FUNCTION IF EXISTS RatingZona;
drop FUNCTION if exists CalcolaDistanza;

# funzioni di utilità
# funzione Livello massimo consentito, serve all'operazione RichiediVisualizzazione
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

# funzione RatingZona, serve a caching
DELIMITER //
CREATE FUNCTION RatingZona(Area_ INT, Film_ INT) 
RETURNS INT
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

# funzione Livello compatibile, serve a RichiediVisualizzazione
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
    
    SELECT QualitaVideo INTO q_formato
    FROM formato
    WHERE formato.Id = Formato_;
    
    IF max_cons = 'HD' THEN 
		IF q_formato = 'HD' THEN
			RETURN True;
		ELSE RETURN False;
        END IF;
    ELSEIF max_cons = 'FHD' THEN
		IF q_formato = 'HD' OR q_formato = 'FHD' THEN
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
CREATE FUNCTION CalcolaDistanza(Paese_ VARCHAR(10), Serv_ INT) 
RETURNS DECIMAL(10, 2)
READS SQL DATA
BEGIN
    DECLARE dist DECIMAL(10, 2);
    DECLARE lat_paese FLOAT;
    DECLARE lng_paese FLOAT;
    DECLARE lat_serv FLOAT;
    DECLARE lng_serv FLOAT;
    
    SELECT Paese.Lat, Paese.Lng INTO lat_paese, lng_paese
    FROM paese
    WHERE paese.Cod = Paese_;
    
    SELECT server.Lat, server.Lng INTO lat_serv, lng_serv
    FROM server
    WHERE server.Id = Serv_;
    
    SET dist = ST_Distance_Sphere(POINT(lng_serv, lat_serv), POINT(lng_paese, lat_paese)) / 1000;
    # distanza in chilometri
    RETURN dist;
END;
//
DELIMITER ;

# funzione GetCountryByIP, serve per avere il paese dall'ip
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

# Operazione alla base del caching
DELIMITER //
CREATE PROCEDURE SpostamentoCaching(IN rapporto FLOAT)
BEGIN
	DECLARE resto INT;
    IF rapporto > 1 OR rapporto < 0.001 THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Rapporto non valido';
	END IF;
    SET resto = ROUND((RAND() * 1000), 0) % ROUND(1 / rapporto, 0); # un intero casuale tra 0 e 1/rapporto
    
    
    UPDATE file
    SET Server = (
		# server nell'area geografica è più apprezzato
		SELECT server.Id
        FROM server
        ORDER BY RatingZona(server.Id, file.Film) desc
        LIMIT 1
    )
    WHERE file.Id not in ( # file non associati a visualizzazioni
		SELECT visualizzazione.File
        FROM visualizzazione
        WHERE visualizzazione.Fine IS NULL
    ) AND file.Id % ROUND(1 / rapporto, 0) = resto;
    
END //
DELIMITER ;












# trigger per il rispetto dei vincoli
# trigger inserimento connessione
DELIMITER //
CREATE TRIGGER trg_ins_connessione 
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

# trigger inserimento carta di credito
DELIMITER //
CREATE TRIGGER trg_ins_cartadicredito
BEFORE INSERT ON cartaDiCredito FOR EACH ROW
BEGIN
  IF NEW.DataScadenza <= CURDATE() THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La carte è scaduta';
  END IF;
END; //
DELIMITER ;

# trigger inserimento sottoscrizione
DELIMITER //
CREATE TRIGGER trg_ins_sottoscrizione
BEFORE INSERT ON sottoscrizione FOR EACH ROW
BEGIN
    DECLARE data_scadenza DATE;
    DECLARE pagante INT;
    SELECT DataScadenza INTO data_scadenza FROM cartaDiCredito WHERE Numero = NEW.cartadiCredito;
    
    IF data_scadenza < NEW.Data THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La carta di credito è scaduta';
    END IF;

	SELECT Proprietario INTO pagante # cliente che paga
    FROM cartadicredito
    WHERE Numero = NEW.CartadiCredito;
    
    
    
	IF NEW.PianoTariffario = (
		SELECT Abbonamento
        FROM cliente
        WHERE Id = pagante
    ) THEN 
		# (rinnovo) caso in cui un cliente ha un abbonamento attivo uguale a quello che si sta inserendo
		# aggiorna scadenza aumentandola di 30
		UPDATE cliente SET Scadenza = date_add(Scadenza, INTERVAL 30 DAY) WHERE cliente.Id = pagante;
	ELSE 
		# tutti gli altri casi (cambio piano, nuovo cliente, cliente con piano scaduto)
		UPDATE cliente SET Scadenza = date_add(NEW.Data, INTERVAL 30 DAY) WHERE cliente.Id = pagante;
		UPDATE cliente SET Abbonamento = NEW.PianoTariffario WHERE cliente.Id = pagante;
    END IF;


																		
    # negli altri casi
    # aggiorna abbonamento
    # aggiorna scadenza mettendo la data + 30 giorni
																
																
																
END; //
DELIMITER ;

# trigger inserimento premio
DELIMITER //
CREATE TRIGGER trg_ins_premio 
BEFORE INSERT ON Premio
FOR EACH ROW
BEGIN
	# trigger che controlla che l'anno del premio sia compreso tra l'anno di uscita del film e il successivo
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

# trigger modifica file
DELIMITER //
CREATE TRIGGER trg_upd_file # trigger per quando si sposta un file in streaming, aggiorna il carico
BEFORE UPDATE ON file
FOR EACH ROW
BEGIN
	DECLARE bitrate_file FLOAT;
    DECLARE capacita_old FLOAT;
    DECLARE capacita_new FLOAT;
    SELECT formato.Bitrate into bitrate_file
    FROM formato
    WHERE NEW.Formato = formato.Id;
    # prendi capacità del server
    
    SELECT Capacità into capacita_old
    FROM server
    WHERE Id = OLD.Server;
    
    SELECT Capacità into capacita_new
    FROM server
    WHERE Id = NEW.Server;
    
    
    IF OLD.Id IN (    # tra i file associati a una visualizzazione attiva
		SELECT File
        FROM visualizzazione
        WHERE Fine IS NULL
    ) AND NEW.Server <> OLD.Server THEN
		# controlla che non venga superata la capacità massima del server di arrivo
        IF (
			SELECT s.Carico
            FROM server s
            WHERE s.Id = NEW.Server
        ) + bitrate_file / (
			SELECT s.Capacità
            FROM server s
            WHERE s.Id = NEW.Server
        ) > 1 THEN
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Il server è già al 100%';
		END IF;
        
		UPDATE server
		SET Carico = Carico - bitrate_file / capacita_old
		WHERE Id = OLD.Server;
        
		UPDATE Server
		SET Carico = Carico + bitrate_file / capacita_new
		WHERE Id = NEW.Server;
	END IF;
        
		
END;
//
DELIMITER ;

# trigger ins visualizzazione
DELIMITER //
CREATE TRIGGER trg_ins_visualizzazione
BEFORE INSERT ON visualizzazione
FOR EACH ROW
BEGIN
    DECLARE conn_inizio DATETIME;
    DECLARE conn_fine DATETIME;
    DECLARE film_file INT;
    DECLARE bitrate_file FLOAT;
    DECLARE server_file INT;
    DECLARE capacita_server FLOAT;

    # Ottieni l'inizio e la fine della connessione corrispondente
    SELECT Inizio, Fine INTO conn_inizio, conn_fine
    FROM Connessione
    WHERE Id = NEW.Connessione;

    # Verifica che l'inizio della visualizzazione sia maggiore o uguale all'inizio della connessione
    IF NEW.Inizio < conn_inizio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'L\'inizio della visualizzazione deve essere maggiore o uguale all\'inizio della connessione.';
    END IF;

    # Verifica che se Fine è non null, sia minore o uguale alla fine della connessione
    IF NEW.Fine IS NOT NULL AND NEW.Fine > conn_fine THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La Fine della visualizzazione deve essere minore o uguale alla Fine della connessione.';
    END IF;
    
    IF NEW.Fine IS NULL AND conn_fine IS NOT NULL THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La Fine della visualizzazione deve essere minore o uguale alla Fine della connessione.';
    END IF;
    
    # Ottieni Id del film
    SELECT Film INTO film_file
    FROM File
    WHERE NEW.File = File.Id;
    
    # aggiorna il carico (verificando che non superi 1)
    # prendi il bitrate del file del quale si sta inserendo la visualizzazione, e il server dove si trova il file
    SELECT formato.Bitrate, file.Server, server.Capacità into bitrate_file, server_file, capacita_server
    FROM formato 
    JOIN file on file.Formato = formato.Id
    JOIN server on file.Server = server.Id
    WHERE file.Id = NEW.File;
    IF (
		SELECT Carico
        FROM server
        WHERE Id = server_file
    ) + bitrate_file / (
		SELECT Capacità
        FROM server
        WHERE Id = server_file
    ) <= 1 THEN 
		UPDATE server
        SET Carico = Carico + bitrate_file / capacita_server
        WHERE Id = server_file;
	ELSE 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Server già al 100%';
	END IF;
    
    # aggiorna numero visualizzazioni
    UPDATE film
	SET nVisualizzazioni = nVisualizzazioni + 1
	WHERE Id = film_file;
    
		
END;
//
DELIMITER ;

# trigger modifica visual
DELIMITER //
CREATE TRIGGER trg_upd_visualizzazione # trigger per termina visualizzazione, che aggiorna il carico
BEFORE UPDATE ON visualizzazione
FOR EACH ROW
BEGIN
	DECLARE bitrate_file FLOAT;
    DECLARE carico_server FLOAT;
    DECLARE capacita_server FLOAT;
    DECLARE server_id INT;
	# prendi il file e il server nel quale si trova
    SELECT formato.Bitrate, server.Capacità, server.Id 
    into bitrate_file, capacita_server, server_id
    FROM formato 
    JOIN file on file.Formato = formato.Id
    JOIN server on file.Server = server.Id
    WHERE file.Id = OLD.File;
    
    IF NEW.Fine IS NOT NULL AND OLD.Fine IS NULL THEN # se la visualizzazione è stata terminata
		UPDATE server
        SET Carico = Carico - bitrate_file / capacita_server
        WHERE Id = server_id;
	END IF;
		
END;
//
DELIMITER ;

# trigger ins recensione
DELIMITER //
CREATE TRIGGER trg_ins_recensione
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
    
END;
//
DELIMITER ;








# le 9 operazioni sui dati
# funzione inserimento connessione
DELIMITER //
CREATE PROCEDURE InserisciConnessione (IN password_ VARCHAR(20), IN cliente_ INT, IN IP_ VARCHAR(30), IN dispositivo_ INT)
BEGIN
	DECLARE max_id INT;
    SELECT count(*) into max_id
    from connessione;
	# controlla la password
    IF password_ <> (
		SELECT Password
        FROM cliente
        WHERE Id = cliente_
    ) THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password Errata';
	END IF;
    

    INSERT INTO connessione (Id, IP, Dispositivo, Cliente, Inizio, Fine, Paese) 
					 VALUES (max_id, IP_, dispositivo_, cliente_, current_time(), NULL, NULL);
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

# funzione richiesta visualizzazione
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
	DECLARE max_id INT;
    SELECT count(*) into max_id
    from visualizzazione;
    
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
    AND file.Id NOT IN (
		SELECT nonsupportato.File
        FROM nonsupportato
        WHERE nonsupportato.Paese = paese_con
    ) and 
    Compatibile(pt_cliente, file.Formato) = True and 
    server.Carico + (                    # bitrate
		SELECT formato.Bitrate / server.Capacità
        FROM formato
        WHERE formato.Id = file.Formato
    ) <= 1
    ORDER BY (10 ^ (2 * server.Carico) + CalcolaDistanza(paese_con, server.Id) / 100) ASC
    LIMIT 1;
    
    # se non hai trovato un file adatto
    IF file_scelto IS NULL THEN 
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Nessun file compatibile con la richiesta';    
	END IF;
    
    INSERT INTO visualizzazione (Id, Connessione, File, Inizio, Fine)
						VALUES (max_id, connessione_attiva, file_scelto, current_timestamp(), NULL);

	# qui il trigger aggiorna il carico
    
    
    
    
    # se il carico del server scelto ha superato una certa soglia di carico
    IF (
		SELECT Carico
        FROM server
        WHERE server.Id = server_scelto
    ) > 0.75 THEN
    # prendi le connessioni che stanno streammando su quel server e valuta lo spostamento del server
    # tutto avviene senza interrompere le visualizzazioni
	
		# spostare il file
        UPDATE file
        SET Server = ( # server migliore
			SELECT s.Id
            FROM server s
            ORDER BY (10 ^ (2 * s.Carico) + CalcolaDistanza(( # paese dal quale sta avvenendo la connessione da spostare
				SELECT connessione.Paese
                FROM connessione 
                JOIN visualizzazione on visualizzazione.Connessione = connessione.Id
                JOIN file f on visualizzazione.File = f.Id
                WHERE visualizzazione.File = file.Id
                AND f.Server = server_scelto
                AND visualizzazione.Fine IS NULL
            ), s.Id) / 100) ASC
			LIMIT 1
        )
        WHERE file.Id = (
			SELECT visualizzazione.File
            FROM visualizzazione
            JOIN connessione ON visualizzazione.Connessione = connessione.Id
            JOIN file f on visualizzazione.File = f.Id
            WHERE f.Server = server_scelto
            AND visualizzazione.Fine IS NULL
        );        
        # qui il trigger aggiorna i carichi
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
    

	UPDATE visualizzazione # finisci la visualizzazione
    SET Fine = current_timestamp()
    WHERE visualizzazione.Connessione = (
		SELECT connessione.Id
        FROM connessione
        WHERE connessione.Cliente = cliente_ AND
        connessione.Fine IS NULL
    );
    
    # qui il trigger aggiorna il carico
    
END //
DELIMITER ;

# funzione RatingPersonalizzato
DELIMITER //
CREATE FUNCTION RatingPersonalizzato(Film_ INT, Cliente_ INT) 
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
    
    SELECT AVG(recensione.Voto) INTO r_medio_film
    FROM recensione
    WHERE recensione.Film = Film_;
    IF r_medio_film IS NULL THEN 
		SET r_medio_film = 5;
	END IF;
    
    SELECT 10 * nVisualizzazioni / (
		SELECT MAX(film.nVisualizzazioni)
        FROM film
    ) into r_visual
	FROM film
    WHERE Id = film_;

    
    RETURN (r_Regista + r_PaeseProduzione + r_Genere + r_Attori + r_Critica + r_medio_film + r_visual) / 7;
    
END;
//
DELIMITER ;

# funzione inserimento file
DELIMITER //
CREATE PROCEDURE InserisciFile(IN Film_ INT, IN Formato_ INT, IN Dimensione_ INT, IN DurataVideo_ INT)
BEGIN
	DECLARE max_id INT;
    DECLARE server_migliore VARCHAR(10);
    SELECT count(*) into max_id
    from file;
    
    
	SELECT paese.AreaGeografica into server_migliore
	FROM cliente
	JOIN paese ON paese.Cod = cliente.PaeseResidenza
	GROUP BY paese.AreaGeografica
	ORDER BY avg(RatingPersonalizzato(Film_, cliente.Id)) desc
	limit 1;
    

    
    # fai l'inserimento
    INSERT INTO file (Id, Film, Formato, DataInserimento, Dimensione, Durata, Server) 
    VALUES (max_id, Film_, Formato_, current_timestamp(), Dimensione_, DurataVideo_, server_migliore);
    # il trigger già presente controllerà se il film esiste
    
END //
DELIMITER ;

# funzione inserimento recensione
DELIMITER //
CREATE PROCEDURE InserisciRecensione(IN Film_ INT, IN Cliente_ INT, IN Voto_ FLOAT)
BEGIN
	DECLARE max_id INT;
    SELECT count(*) into max_id
    from recensione;
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
    
    
    # fai l'inserimento
    INSERT INTO recensione (Id, Film, Cliente, Voto, Data) 
    VALUES (max_id+1000, Film_, Cliente_, Voto_, current_timestamp());
    # il trigger controllerà se il cliente ha già visto il film
    
END //
DELIMITER ;

# funzione inserisci sottoscrizione
DELIMITER //
CREATE PROCEDURE InserisciSottoscrizione(IN CartadiCredito_ VARCHAR(50), IN PianoTariffario_ VARCHAR(50))
BEGIN
	DECLARE max_id INT;
    SELECT count(*) into max_id
    from sottoscrizione;
	INSERT INTO sottoscrizione (Id, CartadiCredito, Data, PianoTariffario)
		VALUES (max_id, CartadiCredito_, current_timestamp(), PianoTariffario_);
	# il trigger fa i controlli e gli aggiornamenti
END //
DELIMITER ;

# event caching
DELIMITER //
CREATE EVENT Caching
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '23:59:59')
DO
BEGIN
    CALL SpostamentoCaching(0.1);
END;
//
DELIMITER ;
ALTER EVENT Caching DISABLE;












# analytics
# funzione consiglia film
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
    ORDER BY RatingPersonalizzato(film.Id, Cliente_) desc
    LIMIT 10;
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

# analytics ricavi
DELIMITER //
CREATE PROCEDURE AnalisiRicavi()
BEGIN
	select paese.Nome as Paese, sum(pianotariffario.Prezzo) as Ricavo
	from pianotariffario
	JOIN sottoscrizione on sottoscrizione.PianoTariffario = pianotariffario.Nome
	join cartadicredito on sottoscrizione.CartadiCredito = cartadicredito.Numero
	join cliente on cartadicredito.Proprietario = cliente.Id
	join paese on cliente.PaeseResidenza = paese.Cod
	group by cliente.PaeseResidenza
	order by ricavo desc;
	
	
	select server.AreaGeografica as Area, sum(pianotariffario.Prezzo) as Ricavo
	from pianotariffario
	JOIN sottoscrizione on sottoscrizione.PianoTariffario = pianotariffario.Nome
	join cartadicredito on sottoscrizione.CartadiCredito = cartadicredito.Numero
	join cliente on cartadicredito.Proprietario = cliente.Id
	join paese on cliente.PaeseResidenza = paese.Cod
	join server on paese.AreaGeografica = server.Id
	group by server.Id
	order by ricavo desc;
	
	
	with RicaviDaClienti as (
		SELECT cartadicredito.Proprietario as cl, sum(pianotariffario.Prezzo) as Ricavo
		from pianotariffario
		JOIN sottoscrizione on sottoscrizione.PianoTariffario = pianotariffario.Nome
		join cartadicredito on sottoscrizione.CartadiCredito = cartadicredito.Numero
		group by cartadicredito.Proprietario
	),	
	VisualizzazioniClienti as (
		SELECT connessione.Cliente as cl, count(*) as nVis
		from visualizzazione
			join connessione on visualizzazione.Connessione = connessione.Id
		group by connessione.Cliente
	),	
	RicaviDaVisualizzazioni as (
		select visualizzazione.*, RicaviDaClienti.Ricavo / (
			select nVis
			from VisualizzazioniClienti
			where cl = cliente.Id
		) as Ricavo
		from visualizzazione
		join connessione on visualizzazione.Connessione = connessione.Id
		join cliente on connessione.Cliente = cliente.Id
		join RicaviDaClienti on RicaviDaClienti.cl = cliente.Id
	)	
	select film.Id, film.Titolo, sum(RicaviDaVisualizzazioni.Ricavo) as Ricavo
	from film 
	join file on file.Film = film.Id
	join RicaviDaVisualizzazioni on RicaviDaVisualizzazioni.File = file.Id
	group by film.Id
	order by ricavo desc;

END //
DELIMITER ;









