import random
import itertools
import string
import tavola_volumi
import numpy as np
from datetime import datetime, timedelta
import pandas as pd

def generate_random_time_in_range(start_time, end_time):
    time_range = end_time - start_time
    random_seconds = random.randint(0, int(time_range.total_seconds()))
    random_time = start_time + timedelta(seconds=random_seconds)
    return random_time


def random_date_between(start_date, end_date):
    return start_date + timedelta(days=random.randint(0, (end_date - start_date).days))


def get_random_languages(num_languages, n):
    # Genera un numero casuale di indici di lingue in base alla distribuzione di Poisson
    num_indices = np.random.poisson(n)

    # Assicurati che il numero casuale non superi il numero di lingue disponibili
    num_indices = min(num_indices, num_languages)

    # Genera indici unici casuali
    language_indices = random.sample(range(num_languages), num_indices)
    language_indices.append(0)
    return list(set(language_indices))


def g_password_lunga(lunghezza):
    caratteri = string.ascii_letters + string.digits
    password = ''.join(random.choice(caratteri) for _ in range(lunghezza))
    return password


def g_nomi(num):
    us_names = ['John', 'Mary', 'Michael', 'Jennifer', 'David', 'Linda', 'James', 'Sarah', 'Robert', 'Karen']
    brasil_names = ['Pedro', 'Ana', 'Lucas', 'Mariana', 'Rafael', 'Beatriz', 'Gustavo', 'Carolina', 'Fernando',
                    'Isabella']
    france_names = ['Pierre', 'Sophie', 'Antoine', 'Cécile', 'Nicolas', 'Marie', 'Mathieu', 'Juliette', 'Alexandre',
                    'Camille']
    japan_names = ['Takashi', 'Aya', 'Yuki', 'Haruka', 'Hiroshi', 'Nana', 'Kazuki', 'Sakura', 'Kenji', 'Rina']
    china_names = ['Wei', 'Ling', 'Zhang', 'Mei', 'Yuan', 'Chen', 'Xiao', 'Yang', 'Wang', 'Xi']
    india_names = ['Rahul', 'Priya', 'Aryan', 'Asha', 'Rohan', 'Divya', 'Vikram', 'Sonia', 'Amit', 'Anjali']
    germany_names = ['Max', 'Anna', 'Tim', 'Emma', 'Paul', 'Lena', 'Felix', 'Laura', 'Tom', 'Sophie']
    names = us_names + brasil_names + france_names + japan_names + china_names + india_names + germany_names
    us_surnames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Miller', 'Davis', 'Garcia', 'Rodriguez',
                   'Martinez']
    brasil_surnames = ['Silva', 'Santos', 'Oliveira', 'Pereira', 'Souza', 'Costa', 'Rodrigues', 'Ferreira', 'Gomes',
                       'Almeida']
    france_surnames = ['Martin', 'Bernard', 'Dubois', 'Thomas', 'Robert', 'Richard', 'Petit', 'Durand', 'Leroy',
                       'Moreau']
    japan_surnames = ['Sato', 'Suzuki', 'Takahashi', 'Tanaka', 'Watanabe', 'Ito', 'Yamamoto', 'Nakamura', 'Kobayashi',
                      'Saito']
    china_surnames = ['Li', 'Wang', 'Liu', 'Chen', 'Yang', 'Zhao', 'Huang', 'Zhou', 'Wu']
    india_surnames = ['Patel', 'Sharma', 'Kumar', 'Singh', 'Mehta', 'Shah', 'Gupta', 'Verma', 'Chopra', 'Rao']
    germany_surnames = ['Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Schulz', 'Hoffmann', 'Wagner',
                        'Becker']
    surnames = us_surnames + brasil_surnames + france_surnames + japan_surnames + china_surnames + india_surnames + germany_surnames
    prodotto_cartesiano = random.sample(list(itertools.product(names, surnames)), num)
    return prodotto_cartesiano


def g_random_ip():
    ip_parts = [str(random.randint(0, 255)) for _ in range(4)]

    ip = ".".join(ip_parts)
    return ip


# funzione di utilità da usare dentro genera sql
def escape_string(value):
    if pd.notna(value):
        if isinstance(value, str):
            return "'" + str(value) + "'"
        else:
            return str(value)
    else:
        return "NULL"


class Tabella:
    def __init__(self, s, d):
        self.df = d
        self.nome = s

    def stampa(self):
        print(self.df)

    def g_sql(self):
        insert_sql = ""

        for index, row in self.df.iterrows():
            columns = ", ".join(row.index)
            values = ", ".join(escape_string(value) for value in row)
            insert_statement = f"INSERT INTO {self.nome} ({columns}) VALUES ({values}); \n"
            insert_sql += insert_statement

        return insert_sql
    
    def genera_file_sql(self, file_name):

        # Definisci il percorso completo del file
        sql_code = self.g_sql()
        file_path = r'C:\\Users\\Giuseppe\\Desktop\\progetto_DB\\scripts\\' + file_name

        try:
            # Apri il file in modalità scrittura
            with open(file_path, 'w') as sql_file:
                # Scrivi il codice SQL nel file
                sql_file.write(sql_code)
            print(f"File SQL '{file_name}' creato con successo nella directory specificata")
        except Exception as e:
            print(f"Si è verificato un errore durante la creazione del file SQL: {str(e)}")

    def dataframe_to_mysql_ddl(self):
        # Inizializza una stringa per il DDL SQL
        ddl_sql = f"CREATE TABLE {self.nome} (\n"

        # Itera sulle colonne del DataFrame
        for column in self.df.columns:
            # Ottieni il nome della colonna
            col_name = column

            # Ottieni il tipo di dati della colonna
            col_type = self.df[column].dtype

            # Aggiungi una riga al DDL SQL per la colonna
            ddl_sql += f"    {col_name} {col_type},\n"

        # Rimuovi l'ultima virgola e aggiungi una parentesi chiusa
        ddl_sql = ddl_sql[:-2] + "\n);"

        print(ddl_sql)

    def genera_sql_lungo(self, file_name):
        lungh = self.df.shape[0]
        i = 0
        df_temp = None
        lista_stringhe = []
        while i < lungh:
            if i+25000 < lungh:
                df_temp = self.df[i:i+25000]
            else:
                df_temp = self.df[i:]
            i = i + 25000
            insert_sql = ""
            for index, row in df_temp.iterrows():
                columns = ", ".join(row.index)
                values = ", ".join(escape_string(value) for value in row)
                insert_statement = f"INSERT INTO {self.nome} ({columns}) VALUES ({values}); \n"
                insert_sql += insert_statement
            lista_stringhe.append(insert_sql)
        for i in range(len(lista_stringhe)):
            file_name_ = file_name + str(i) + '.sql' 
            file_path = r'C:\\Users\\Giuseppe\\Desktop\\progetto_DB\\scripts\\' + file_name_
            try:
                # Apri il file in modalità scrittura
                with open(file_path, 'w') as sql_file:
                    # Scrivi il codice SQL nel file
                    sql_file.write(lista_stringhe[i])
                print(f"File SQL '{file_name_}' creato con successo nella directory specificata")
            except Exception as e:
                print(f"Si è verificato un errore durante la creazione del file SQL: {str(e)}")
            




def genera_server():
    
    data = [
        {'Id': 0, 'AreaGeografica': 'Australia and New Zealand', 'Lat':-33, 'Lng': 150, 'Banda':1, 'Capacità':1},
        {'Id': 1, 'AreaGeografica': 'Central Asia', 'Lat':50, 'Lng': 70, 'Banda':1, 'Capacità':1},
        {'Id': 2, 'AreaGeografica': 'Eastern Asia', 'Lat':28, 'Lng': 120, 'Banda':1, 'Capacità':1},
        {'Id': 3, 'AreaGeografica': 'Eastern Europe', 'Lat':45, 'Lng': 26, 'Banda':1, 'Capacità':1},
        {'Id': 4, 'AreaGeografica': 'Latin America and the Caribbean', 'Lat':3, 'Lng': -70, 'Banda':1, 'Capacità':1},
        {'Id': 5, 'AreaGeografica': 'Melanesia', 'Lat':-5, 'Lng': 143, 'Banda':1, 'Capacità':1},
        {'Id': 6, 'AreaGeografica': 'Micronesia', 'Lat':14, 'Lng': 145, 'Banda':1, 'Capacità':1},
        {'Id': 7, 'AreaGeografica': 'Northern Africa', 'Lat':34, 'Lng': 9, 'Banda':1, 'Capacità':1},
        {'Id': 8, 'AreaGeografica': 'Northern America', 'Lat':33, 'Lng': -82, 'Banda':1, 'Capacità':1},
        {'Id': 9, 'AreaGeografica': 'Northern Europe', 'Lat':55, 'Lng': 11, 'Banda':1, 'Capacità':1},
        {'Id': 10, 'AreaGeografica': 'Polynesia', 'Lat':-16, 'Lng': -151, 'Banda':1, 'Capacità':1},
        {'Id': 11, 'AreaGeografica': 'South-eastern Asia', 'Lat':15, 'Lng': 103, 'Banda':1, 'Capacità':1},
        {'Id': 12, 'AreaGeografica': 'Southern Asia', 'Lat':19, 'Lng': 73, 'Banda':1, 'Capacità':1},
        {'Id': 13, 'AreaGeografica': 'Southern Europe', 'Lat':42, 'Lng': 12, 'Banda':1, 'Capacità':1},
        {'Id': 14, 'AreaGeografica': 'Sub-Saharan Africa', 'Lat':-6, 'Lng': 24, 'Banda':1, 'Capacità':1},
        {'Id': 15, 'AreaGeografica': 'Western Asia', 'Lat':40, 'Lng': 35, 'Banda':1, 'Capacità':1},
        {'Id': 16, 'AreaGeografica': 'Western Europe', 'Lat':48, 'Lng': 1, 'Banda':1, 'Capacità':1},
    ]

    df = pd.DataFrame(data)
    return Tabella("server", df)


def genera_pianoTariffario():
    data = [{'Nome': "Basic", 'Prezzo': 4.99, 'Contenuti': 'Standard', 'Pubblicità': 'Sì', 'QualitàMax': 'standard'},
            {'Nome': "Premium", 'Prezzo': 7.99, 'Contenuti': 'Standard', 'Pubblicità': 'Poca', 'QualitàMax': 'HD'},
            {'Nome': "Pro", 'Prezzo': 10.99, 'Contenuti': 'Tutti', 'Pubblicità': 'Poca', 'QualitàMax': 'HD'},
            {'Nome': "Deluxe", 'Prezzo': 13.99, 'Contenuti': 'Tutti', 'Pubblicità': 'Nessuna', 'QualitàMax': 'UltraHD'},
            {'Nome': "Ultimate", 'Prezzo': 16.99, 'Contenuti': 'Extra', 'Pubblicità': 'Nessuna',
             'QualitàMax': 'UltraHD'}]
    return Tabella("pianoTariffario", pd.DataFrame(data))


def genera_regista():
    num_righe_da_creare = tavola_volumi.n_Regista
    lista_coppie = g_nomi(num_righe_da_creare)
    lista_diz = [{"Nome": nome, "Cognome": cognome} for nome, cognome in lista_coppie]
    df = pd.DataFrame(lista_diz)
    df['Id'] = df.reset_index().index
    df['Id'] = df['Id'] * 3 + 1
    df = df[['Id', 'Nome', 'Cognome']]
    return Tabella("regista", df)


def genera_film():
    # Film(*Id, Titolo, Descrizione, Genere, Durata, AnnoProduzione, PaeseProduzione, Regista, nVisual)
    # senza paese di produzione, andrà aggiunto dopo
    df = pd.read_csv("film_sakila.csv")
    df = df[['film_id', 'title', 'description', 'length', 'release_year']]
    # creaiamo lista dei paesi produzione
    lista_codici = ['AF', 'AL', 'DZ', 'AS', 'AD', 'AO', 'AI', 'AG', 'AR', 'AM', 'AW', 
             'AU', 'AT', 'AZ', 'BS', 'BH', 'BD', 'BB', 'BY', 'BE', 'BZ', 'BJ', 
             'BM', 'BT', 'BO', 'BQ', 'BA', 'BW', 'BR', 'BN', 'BG', 'BF', 'BI', 
             'CV', 'KH', 'CM', 'CA', 'KY', 'CF', 'TD', 'CL', 'CN', 'CX', 'CO', 
             'KM', 'CG', 'CD', 'CK', 'CR', 'CI', 'HR', 'CU', 'CW', 'CY', 'CZ', 
             'DK', 'DJ', 'DM', 'DO', 'EC', 'EG', 'SV', 'GQ', 'ER', 'EE', 'SZ', 
             'ET', 'FK', 'FO', 'FJ', 'FI', 'FR', 'GF', 'PF', 'GA', 'GM', 'GE', 
             'DE', 'GH', 'GI', 'GR', 'GL', 'GD', 'GP', 'GU', 'GT', 'GN', 'GW', 
             'GY', 'HT', 'VA', 'HN', 'HK', 'HU', 'IS', 'IN', 'ID', 'IR', 'IQ', 
             'IE', 'IM', 'IL', 'IT', 'JM', 'JP', 'JE', 'JO', 'KZ', 'KE', 'KI', 
             
             'KP', 'KR', 'KW', 'KG', 'LA', 'LV', 'LB', 'LS', 'LR', 'LY', 'LI', 
             'LT', 'LU', 'MO', 'MG', 'MW', 'MY', 'MV', 'ML', 'MT', 'MH', 'MQ', 
             'MR', 'MU', 'YT', 'MX', 'FM', 'MD', 'MC', 'MN', 'ME', 'MS', 'MA', 
             'MZ', 'MM', 'NA', 'NR', 'NP', 'NL', 'NC', 'NZ', 'NI', 'NE', 'NG', 
             'NU', 'NF', 'MK', 'MP', 'NO', 'OM', 'PK', 'PW', 'PA', 'PG', 'PY', 
             'PE', 'PH', 'PN', 'PL', 'PT', 'PR', 'QA', 'RE', 'RO', 'RU', 'RW', 
             'BL', 'SH', 'KN', 'LC', 'MF', 'PM', 'VC', 'WS', 'SM', 'ST', 'SA', 
             'SN', 'RS', 'SC', 'SL', 'SG', 'SX', 'SK', 'SI', 'SB', 'SO', 'ZA', 
             'GS', 'SS', 'ES', 'LK', 'SD', 'SR', 'SE', 'CH', 'SY', 'TW', 'TJ', 
             'TZ', 'TH', 'TL', 'TG', 'TO', 'TT', 'TN', 'TR', 'TM', 'TC', 'TV', 
             'UG', 'UA', 'AE', 'GB', 'US', 'UY', 'UZ', 'VU', 'VE', 'VN', 'VG', 
             'VI', 'WF', 'YE', 'ZM', 'ZW', 'XG', 'XK', 'XR', 'XW']
    lista_codici += ['US' for _ in range(70)]
    lista_codici += ['GB' for _ in range(50)]
    lista_codici += ['JP' for _ in range(40)]
    lista_codici += ['CN' for _ in range(30)]
    lista_codici += ['IT' for _ in range(15)]
    lista_codici += ['ES' for _ in range(10)]
    lista_codici += ['DE' for _ in range(5)]
    lista_codici += ['IN' for _ in range(5)]
    df['Regista'] = [random.randint(0, 199) for _ in range(len(df))]
    df['Regista'] = 3 * df['Regista'] + 1
    df['Genere'] = [random.choice(["Action", "Animation", "Children", "Comedy",
                                   "Documentary", "Drama", "Horror", "Music", "Sci-Fi"]) for _ in range(len(df))]
    df['PaeseProduzione'] = [random.choice(lista_codici) for _ in range(len(df))]
    df.rename(columns={'film_id': 'Id', 'title': 'Titolo', 'description': 'Descrizione',
                       'length': 'Durata', 'release_year': 'AnnoProduzione', 
                       'PaeseProduzione':'PaeseProduzione'}, inplace=True)
    df['AnnoProduzione'] = [random.randint(2013, 2022) for _ in range(len(df))]
    df['LivelloContenuto'] = [random.choices([0, 1, 2], weights=[0.6, 0.3, 0.1])[0] for _ in range(len(df))]
    df = df[['Id', 'Titolo', 'Descrizione', 'Genere', 'Durata',
             'AnnoProduzione', 'PaeseProduzione', 'Regista', 'LivelloContenuto']]
    df['Id'] = df['Id'] - 1

    return Tabella("film", df)


def genera_attore():
    df = pd.read_csv("actor_sakila.csv")
    df['actor_id'] = df['actor_id'] - 1
    df = df[['actor_id', 'first_name', 'last_name']]

    df['first_name'] = df['first_name'].str.title()
    df['last_name'] = df['last_name'].str.title()
    df['actor_id'] = df['actor_id'] * 3
    df.rename(columns={'actor_id': 'Id', 'first_name': 'Nome', 'last_name': 'Cognome'}, inplace=True)
    return Tabella("attore", df)


def genera_parte():
    df = pd.read_csv("film_actor_sakila.csv")
    df = df[['actor_id', 'film_id']]
    df.rename(columns={'actor_id': 'Attore', 'film_id': 'Film'}, inplace=True)
    df['Film'] = df['Film'] - 1
    df['Attore'] = 3 * df['Attore'] 
    return Tabella("parte", df)

def genera_parte():
    lista_film = []
    lista_attore = []
    for i in range(tavola_volumi.n_Film):
        # scegli numero di attori
        num = np.random.poisson(tavola_volumi.num_att_per_film)
        # scegli attori
        att_parz = [3 * random.randint(0, tavola_volumi.n_Attore - 1) for _ in range(num)]
        # aggiungi
        lista_film += [i for _ in range(num)]
        lista_attore += att_parz
    df = pd.DataFrame({
        'Film': lista_film,
        'Attore': lista_attore
    })
    return Tabella('parte', df)


def genera_critico():
    num_righe_da_creare = tavola_volumi.n_Critico
    lista_coppie = g_nomi(num_righe_da_creare)
    lista_diz = [{"Nome": nome, "Cognome": cognome} for nome, cognome in lista_coppie]
    df = pd.DataFrame(lista_diz)
    df['Id'] = df.reset_index().index
    df['Id'] = 3 * df['Id'] + 2
    df = df[['Id', 'Nome', 'Cognome']]
    return Tabella("critico", df)


def genera_lingua():
    languages = [
        "English",
        "Spanish",
        "French",
        "Chinese Mandarin",
        "Arabic",
        "Russian",
        "Hindi",
        "Portuguese",
        "German",
        "Japanese",
        "Korean",
        "Italian",
        "Dutch",
        "Turkish",
        "Malay",
        "Indonesian",
        "Thai",
        "Polish",
        "Swedish",
        "Danish",
        "Norwegian",
        "Finnish",
        "Greek",
        "Hebrew",
        "Hungarian",
        "Czech",
        "Slovak",
        "Romanian",
        "Bulgarian",
        "Croatian",
        "Serbian",
        "Slovenian",
        "Latvian",
        "Lithuanian",
        "Estonian",
        "Georgian",
        "Armenian",
        "Kazakh",
        "Ukrainian",
        "Persian",
        "Bengali",
        "Thai",
        "Vietnamese",
        "Filipino",
        "Malay",
        "Swahili",
        "Amharic",
        "Hausa",
        "Somali"
    ]
    # meglio scegliere poche lingue
    languages = languages[:tavola_volumi.n_Lingua]
    lista_diz = [{"Nome": elem} for elem in languages]
    df = pd.DataFrame(lista_diz)
    df['Id'] = df.reset_index().index
    df = df[['Id', 'Nome']]
    return Tabella("lingua", df)


def genera_premio(film):
    # prende in input il dataframe dei film
    categorie_oscar = [
        'Miglior Film',
        'Miglior Regista',
        'Miglior Attore Protagonista',
        'Miglior Attrice Protagonista',
        'Miglior Attore Non Protagonista',
        'Miglior Attrice Non Protagonista',
        'Miglior Sceneggiatura Originale',
        'Miglior Sceneggiatura Non Originale',
        # 'Miglior Film Internazionale',
        # 'Miglior Film d\'Animazione',
        # 'Miglior Documentario',
        'Miglior Fotografia',
        'Migliori Effetti Speciali',
        # 'Miglior Montaggio',
        # 'Miglior Colonna Sonora Originale',
        # 'Miglior Canzone Originale',
        # 'Miglior Costumi',
        # 'Miglior Trucco e Acconciatura',
        # 'Miglior Montaggio del Sonoro',
        # 'Miglior Mix del Sonoro',
        # 'Miglior Design di Produzione'
    ]

    data_oscar = {
        'Premio': ['Oscar'] * len(categorie_oscar),
        'Categoria': categorie_oscar
    }

    categorie_bafta = [
        'Miglior Film',
        'Miglior Regista',
        'Miglior Attore Protagonista',
        # 'Miglior Attrice Protagonista',
        'Miglior Attore Non Protagonista',
        # 'Miglior Attrice Non Protagonista',
        'Migliore Sceneggiatura Originale',
        'Migliore Sceneggiatura Non Originale',
        # 'Miglior Film Britannico',
        # 'Miglior Film Straniero',
        # 'Miglior Film d\'Animazione',
        # 'Miglior Fotografia',
        # 'Miglior Montaggio',
        # 'Miglior Colonna Sonora Originale',
        # 'Miglior Canzone Originale',
        # 'Miglior Design di Produzione',
        # 'Migliori Costumi',
        # 'Miglior Trucco e Acconciatura',
        # 'Migliori Effetti Speciali',
        # 'Miglior Sonoro'
    ]

    data_bafta = {
        'Premio': ['BAFTA'] * len(categorie_bafta),
        'Categoria': categorie_bafta
    }

    categorie_cannes = [
        
        'Gran Prix',
        'Premio della Giuria',
        'Miglior Regista',
        # 'Miglior Sceneggiatura',
        # 'Miglior Attore',
        # 'Migliore Attrice',
        # 'Miglior Film d\'Animazione',
        # 'Miglior Cortometraggio',
        # 'Miglior Opera Prima'
    ]

    data_cannes = {
        'Premio': ['Cannes Film Festival'] * len(categorie_cannes),
        'Categoria': categorie_cannes
    }

    categorie_berlin = [
        'Golden Bear',
        'Silver Bear',
        'Premio Speciale della Giuria',
        'Miglior Regista',
        # 'Miglior Sceneggiatura',
        # 'Miglior Attore',
        # 'Migliore Attrice',
        # 'Miglior Film d\'Animazione',
        # 'Miglior Contributo Artistico'
    ]

    data_berlin = {
        'Premio': ['Berlin Film Festival'] * len(categorie_berlin),
        'Categoria': categorie_berlin
    }

    categorie_venice = [
        'Golden Lion',
        'Silver Lion',
        'Premio Speciale della Giuria',
        # 'Coppa Volpi per il Miglior Attore',
        # 'Coppa Volpi per la Migliore Attrice',
        # 'Premio Marcello Mastroianni per il Miglior Attore Emergente',
        'Miglior Regista',
        'Miglior Sceneggiatura',
        # 'Miglior Film d\'Animazione',
        # 'Miglior Documentario',
        # 'Miglior Opera Prima',
        # 'Miglior Contributo Tecnico'
    ]

    data_venice = {
        'Premio': ['Venice Film Festival'] * len(categorie_venice),
        'Categoria': categorie_venice
    }

    # Dizionario risultante
    result_dict = {}

    # Unione dei diz con le stesse chiavi
    for d in [data_venice, data_berlin, data_cannes, data_bafta, data_oscar]:
        for key, value in d.items():
            result_dict.setdefault(key, []).extend(value)

    df = pd.DataFrame(result_dict)
    L = list(range(2015, 2023)) # intervallo dei premi

    # Prodotti cartesiani tra righe di df ed elementi di L
    cartesian_product = list(itertools.product(df.iterrows(), L))

    # Creazione del DataFrame df_1
    df = pd.DataFrame({
        'Premio': [row[1]['Premio'] for row, val in cartesian_product],
        'Categoria': [row[1]['Categoria'] for row, val in cartesian_product],
        'Anno': [val for row, val in cartesian_product],
        'Vincitore': None
        })
    lista_vincitori = []
    for index, rowP in df.iterrows():
        lista_film_adatti = []
        for index, rowF in film.iterrows():
            if rowF['AnnoProduzione'] <= rowP['Anno'] and rowF['AnnoProduzione'] >= rowP['Anno'] - 1:
                lista_film_adatti.append(rowF['Id'])
        lista_vincitori.append(random.choice(lista_film_adatti))
    #df['Vincitore'] = [random.randint(0, 999) for _ in range(len(df))]
    #lista_anni = [film[film['Id'] == val]['AnnoProduzione'] for val in df['Vincitore']]
    #lista_anni = [lista_anni[i] + random.choices([0, 1], weights=[0.8, 0.2]) for i in range(len(lista_anni))]
    #df['Anno'] = lista_anni
    df['Vincitore'] = lista_vincitori
    return Tabella("premio", df)


def genera_clienti():
    df = pd.read_csv("clienti_sakila.csv")
    df['first_name'] = df['first_name'].str.title()
    df['last_name'] = df['last_name'].str.title()
    df['email'] = df['email'].str.lower()
    df['customer_id'] = df['customer_id'] - 1
    df['password'] = [g_password_lunga(10) for _ in range(len(df))]
    df.rename(columns={'customer_id': 'Id', 'first_name': 'Nome',
                       'last_name': 'Cognome', 'email': 'Email', 'password': 'Password'}, inplace=True)
    df['Email'] = df['Email'].str.replace('@sakilacustomer.org', '@gmail.com')
    df['Id'] = df.reset_index().index
    return Tabella("cliente", df)


def genera_lingueAudio():
    lista_film = []
    lista_lingue = []
    for i in range(1000):
        rr = get_random_languages(tavola_volumi.n_Lingua, tavola_volumi.num_lingue_per_film)
        lista_film += [i for _ in range(len(rr))]
        lista_lingue += rr
    data = {
        'Film': lista_film,
        'Lingua': lista_lingue
    }
    return Tabella("linguaAudio", pd.DataFrame(data))


def genera_linguaSottotitoli():
    lista_film = []
    lista_lingue = []
    for i in range(1000):
        rr = get_random_languages(tavola_volumi.n_Lingua, tavola_volumi.num_lingue_per_film)
        lista_film += [i for _ in range(len(rr))]
        lista_lingue += rr
    data = {
        'Film': lista_film,
        'Lingua': lista_lingue
    }
    return Tabella("linguaSottotitoli", pd.DataFrame(data))


def genera_carteDiCredito():
    num = tavola_volumi.n_CartadiCredito
    data = []
    circuits = ["Visa", "MasterCard", "American Express", "Discover"]
    #proprietari = list(range(599))  # Lista di proprietari unici da 0 a 999
    #random.shuffle(proprietari)  # Mischia l'ordine dei proprietari
    numeri = set()
    proprietari = list(range(599)) + [random.randint(0, 599) for _ in range(num - 599)]

    for i in range(num):
        numero = None
        while numero is None or numero in numeri:
            numero = f"{random.randint(1000, 9999)} {random.randint(1000, 9999)} {random.randint(1000, 9999)} {random.randint(1000, 9999)}"

        numeri.add(numero)

        start_date = datetime(2024, 1, 1)
        end_date = datetime(2027, 12, 31)
        delta = end_date - start_date
        random_days = random.randint(0, delta.days)
        data_scadenza = start_date + timedelta(days=random_days)
        data_scadenza_mysql_format = data_scadenza.strftime('%Y-%m-%d')

        circuito = random.choice(circuits)
        # Usa proprietari fino a esaurimento, poi genera casualmente
        proprietario = proprietari[i]

        data.append([numero, data_scadenza_mysql_format, circuito, proprietario])

    
    columns = ["Numero", "DataScadenza", "Circuito", "Proprietario"]
    return Tabella("cartaDiCredito", pd.DataFrame(data, columns=columns))


def genera_critica():
    data = []
    for critic in range(tavola_volumi.n_Critico):
        num_critiques = np.random.poisson(tavola_volumi.num_critiche_per_critico)
        for _ in range(num_critiques):
            film = np.random.randint(0, tavola_volumi.n_Film)
            voto = int(np.clip(np.random.normal(7, 3), 0, 10))  # Distribuzione normale tagliata

            today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            n_months_ago = today - timedelta(days=tavola_volumi.num_mesi * 30)
            random_date = np.random.choice(pd.date_range(n_months_ago, today))

            data.append((film, critic, voto, random_date))
    df = pd.DataFrame(data, columns=["Film", "Critico", "Voto", "Data"])
    df['Data'] = df['Data'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    df['Critico'] = 3 * df['Critico'] + 2
    return Tabella("critica", df)


def genera_dispositivo():
    data = {
        "AziendaProduttrice": ["Apple", "Samsung", "Microsoft", "HP", "Dell", "Lenovo", "Google", "Asus", "Sony",
                                "Xiaomi",
                                "Acer", "LG", "Huawei", "Toshiba", "Razer", "MSI", "Amazon", "OnePlus", "Nokia",
                                "Sony"],
        "Modello": ["iPad Pro", "Galaxy S21", "Surface Laptop 4", "Spectre x360", "XPS 13", "ThinkPad X1 Carbon",
                    "Pixel 6",
                    "ZenBook 14", "Xperia 1 III", "Mi 11", "Swift 3", "Gram 17", "MateBook X Pro", "Satellite",
                    "Blade 15",
                    "GS66 Stealth", "Fire HD 10", "9 Pro", "8.3", "Xperia 5 II"],
        "Anno": [2021, 2021, 2021, 2021, 2020, 2021, 2021, 2021, 2021, 2021, 2020, 2021, 2020, 2021, 2021, 2020, 2021,
                 2021, 2020, 2020],
        "RAM": [8, 12, 16, 16, 16, 16, 8, 16, 12, 8, 8, 16, 16, 8, 16, 16, 3, 12, 8, 8],
        "nCore": [8, 8, 8, 4, 4, 6, 8, 6, 8, 8, 4, 4, 8, 4, 6, 6, 8, 8, 8, 8],
        "fProcessore": [2.5, 2.9, 3.0, 2.4, 1.8, 2.6, 2.8, 2.7, 2.8, 2.84, 1.0, 1.8, 1.9, 1.8, 2.3, 2.6, 2.0, 2.8, 2.0, 2.0],
        "pOrizzontali": [2732, 2400, 2256, 1920, 3840, 2560, 2340, 1920, 1644, 1440, 1920, 2560, 3000, 1366, 1920, 1920,
                         1920, 1440, 1080, 2520],
        "pVerticali": [2048, 1080, 1504, 1080, 2400, 1440, 1080, 1080, 3840, 3200, 1080, 1600, 2000, 768, 1080, 1080,
                       1200, 3168, 1920, 1080]
    }
    # massimo 20 righe
    df = pd.DataFrame(data).sample(tavola_volumi.n_Dispositivo)
    df['Id'] = df.reset_index().index
    df = df[['Id', 'AziendaProduttrice', 'Modello', 'Anno', 'RAM', 'nCore', 'fProcessore',
             'pOrizzontali', 'pVerticali']]
    return Tabella("dispositivo", df)

"""
def genera_abbonamento():
    clienti = list(range(tavola_volumi.n_Cliente))
    piano = [random.choice(["Basic", "Premium", "Pro", "Deluxe", "Ultimate"]) for _ in range(tavola_volumi.n_Cliente)]

    current_date = datetime.now()
    start_date = current_date - timedelta(days=tavola_volumi.num_mesi * 30)  # Assuming 30 days per month

    random_dates = []
    for _ in range(tavola_volumi.n_Cliente):
        random_timestamp = start_date + timedelta(days=random.randint(0, (current_date - start_date).days))
        random_dates.append(random_timestamp.strftime('%Y-%m-%d %H:%M:%S'))
    data = {
        'Cliente': clienti,
        'PianoTariffario': piano,
        'DataInizio': random_dates,
        'DataFine': None
    }
    return Tabella('abbonamento', pd.DataFrame(data))


def genera_fattura(car, abb, pia):
    # passare come parametri il dataframe di cartediCredit, quello di Abbonamento e quello di piano tariffario
    # ipotizziamo che nel periodo tra adesso e num_mesi mesi fa tutti abbiano pagato con regolarità
    cliente = []
    carte = []
    dateL = []
    importi = []
    # trasf da stringhe a datetime
    abb['DataInizio'] = abb['DataInizio'].apply(lambda x: datetime.strptime(x, '%Y-%m-%d %H:%M:%S'))
    # abb['DataFine'] = abb['DataFine'].apply(lambda x: datetime.strptime(x, '%Y-%m-%d %H:%M:%S'))
    for i in range(tavola_volumi.n_Cliente):
        carta = car.loc[car['Proprietario'] == i, 'Numero'].iloc[0]
        date_list = []
        current_date = abb.loc[abb['Cliente'] == i, 'DataInizio'].iloc[0]
        # trasformazione in datetime
        # current_date = datetime.strptime(current_date, '%Y-%m-%d %H:%M:%S')
        while current_date < datetime.now():
            date_list.append(current_date)
            current_date += timedelta(days=30)
        # trova in abb la riga tale che DataInizio < d < DataFine
        abb['DataFine'] = abb['DataFine'].fillna(datetime.now())
        piani = [abb.loc[(abb['Cliente'] == i) & (abb['DataInizio'] <= d) &
                         (d <= abb['DataFine']), 'PianoTariffario'].iloc[0]
                 for d in date_list]
        # print(piani[0])
        tariffe = [pia.loc[pia['Nome'] == pi, 'Prezzo'].iloc[0] for pi in piani]

        for _ in range(len(date_list)):
            cliente.append(i)
            carte.append(carta)
        dateL += date_list
        importi += tariffe

    df = pd.DataFrame({
        'Cliente': cliente,  # lista di numeri che indicano i clienti
        'CartadiCredito': carte,  # lista di stringhe che indicano i numeri delle carte di credito
        'Data': dateL,  # lista di stringhe date in timestamp format
        'Importo': importi  # lista importo del pagamento
    })
    df['Id'] = df['Id'] = df.reset_index().index
    df['Data'] = df['Data'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    return Tabella('fattura', df)

"""

def genera_sottoscrizione(cart):
    # prende in input i dataframe di clienti e di carte
    pianit = ["Basic", "Premium", "Pro", "Deluxe", "Ultimate"]
    lista_carte = []
    lista_date = []
    lista_piani = []
    # per ogni cliente
    for i in range(tavola_volumi.n_Cliente):
        # trova carte di credito
        carte_da_scegliere = cart[cart['Proprietario'] == i]['Numero'].tolist()
        if len(carte_da_scegliere) > 2:
            carte_da_scegliere = carte_da_scegliere[:2]
        # scegli data primo addebito
        data_iniz = generate_random_time_in_range(datetime.now() - timedelta(days=tavola_volumi.num_mesi * 30), 
                                                  datetime.now() - 0.7 * timedelta(days=tavola_volumi.num_mesi * 30))
        # crea elenco date addebiti, con giorni tra l'una e l'altra presi casualmente da una gaussiana molto stretta con valore medio 26
        lista_date_parz = [data_iniz]
        for _ in range(tavola_volumi.num_mesi):
            periodo_scelto = timedelta(days = min(max(int(np.random.normal(25, 2)), 10), 40))
            if lista_date_parz[-1] + periodo_scelto < datetime.now():
                lista_date_parz.append(lista_date_parz[-1] + periodo_scelto)
            else:
                break
        # scegli l'insieme piani tariffari
        lista_piani_poss = [random.choice(pianit) for _ in range(random.choices([1, 2], weights=[0.9, 0.1])[0])]
        # crea la lista pianitariffari con alta prob di consecutivi uguali
        lista_0_1 = [0]
        for _ in range(len(lista_date_parz) - 1):
            if random.choices([True, False], weights=[0.9, 0.1])[0]:
                lista_0_1.append(lista_0_1[-1])
            else:
                lista_0_1.append(1 - lista_0_1[-1])
        if len(lista_piani_poss) == 1:
            lista_0_1 = [0 for _ in range(len(lista_date_parz))]
        lista_piani_parz = [lista_piani_poss[lista_0_1[i]] for i in range(len(lista_0_1))]
        # crea la lista carte di credito
        lista_carte_parz = [random.choice(carte_da_scegliere) for _ in range(len(lista_date_parz))]
        # aggiungile
        lista_date += lista_date_parz
        lista_carte += lista_carte_parz
        lista_piani += lista_piani_parz
        pass
        

    df = pd.DataFrame({
        'CartadiCredito': lista_carte,
        'Data': lista_date,
        'PianoTariffario': lista_piani,
    })
    df['Data'] = df['Data'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    return Tabella('sottoscrizione', df)


def genera_connessione():
    list_cl = []
    list_ip = []
    list_disp = []
    list_in = []
    list_fin = []
    for i in range(tavola_volumi.n_Cliente):
        quanti_ip, quanti_disp = random.choices([1, 2], weights=[0.9, 0.1])[0], random.choice([1, 2])
        # liste di ip e disp "preferiti" del cliente
        ip_scelti = [g_random_ip() for _ in range(quanti_ip)]
        disp_scelti = [random.randint(0, tavola_volumi.n_Dispositivo - 1) for _ in range(quanti_disp)]

        # scegli len_l1, len_l2 tali che 2*len_l2 + len_l1 = num_conn_per_cliente * num_mesi
        len_l2 = random.randint(int(0.10 * tavola_volumi.num_conn_per_cliente * tavola_volumi.num_mesi),
                                int(0.25 * tavola_volumi.num_conn_per_cliente * tavola_volumi.num_mesi))
        len_l1 = tavola_volumi.num_conn_per_cliente * tavola_volumi.num_mesi - 2 * len_l2
        # scegli l1 ed l2, liste di date casuali tra adesso e num_mesi fa, liste disgiunte
        today = datetime.now()
        months_ago = today - timedelta(days=tavola_volumi.num_mesi * 30)  # Approssimazione di 30 giorni per un mese
        date_list = []
        while len(date_list) < len_l1 + len_l2:
            random_days = random.randint(0, (today - months_ago).days)
            random_date = months_ago + timedelta(days=random_days)
            if random_date not in date_list:
                date_list.append(random_date)
        random.shuffle(date_list)
        l1 = date_list[:len_l1]
        l2 = date_list[len_l1:]

        iniz_parz, fin_parz = [], []
        for data in l1 + l2:
            if data in l1:
                # scegli istante tra le 7 e le 23 di data
                is_in = generate_random_time_in_range(data.replace(hour=7, minute=0, second=0, microsecond=0), 
                                                      data.replace(hour=22, minute=0, second=0, microsecond=0))
                # scegli durata tra 2 e 4 ore
                random_timedelta = timedelta(hours=random.randint(2, 4), 
                                             minutes=random.randint(0, 59), 
                                             seconds=random.randint(0, 59))
                # appendi in e in+durata a iniz_parz e a fin_parz
                iniz_parz.append(is_in)
                fin_parz.append(is_in + random_timedelta)
            if data in l2:
                # scegli istante tra le 7 e le 12 di data
                is_in = generate_random_time_in_range(data.replace(hour=7, minute=0, second=0, microsecond=0), 
                                                      data.replace(hour=12, minute=0, second=0, microsecond=0))
                # scegli durata tra 2 e 4 ore
                random_timedelta = timedelta(hours=random.randint(2, 4), 
                                             minutes=random.randint(0, 59), 
                                             seconds=random.randint(0, 59))
                # appendi in e in+durata a iniz_parz e a fin_parz
                iniz_parz.append(is_in)
                fin_parz.append(is_in + random_timedelta)
                # scegli istante tra le 17 e le 23 di data
                is_in = generate_random_time_in_range(data.replace(hour=17, minute=0, second=0, microsecond=0), 
                                                      data.replace(hour=22, minute=0, second=0, microsecond=0))
                # scegli durata tra 2 e 4 ore
                random_timedelta = timedelta(hours=random.randint(2, 4), 
                                             minutes=random.randint(0, 59), 
                                             seconds=random.randint(0, 59))
                # appendi in e in+durata a iniz_parz e a fin_parz
                iniz_parz.append(is_in)
                fin_parz.append(is_in + random_timedelta)

        list_cl += [i for _ in range((len(l1) + 2 * len(l2)))]
        list_ip += [random.choice(ip_scelti) for _ in range((len(l1) + 2 * len(l2)))]
        list_disp += [random.choice(disp_scelti) for _ in range((len(l1) + 2 * len(l2)))]
        list_in += iniz_parz
        list_fin += fin_parz
    # Connessione(*Id, IP, Dispositivo, Cliente, Inizio, Fine)
    df = pd.DataFrame({
        'IP': list_ip,
        'Dispositivo': list_disp,
        'Cliente': list_cl,
        'Inizio': list_in,
        'Fine': list_fin
    })
    df['Inizio'] = df['Inizio'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    df['Fine'] = df['Fine'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    df['Id'] = df['Id'] = df.reset_index().index
    df['Server'] = None
    df = df[['Id', 'IP', 'Dispositivo', 'Cliente', 'Inizio', 'Fine', 'Server']]
    return Tabella('connessione', df)


def genera_formato():
    # senza rapporto, perchè determinato da risoluzione
    data = {
        'nomeFormato': ['MP4', 'Formato2', 'Formato3', 'Formato4', 'Formato5',
                        'Formato6', 'Formato7', 'Formato8', 'Formato9', 'Formato10'],
        'Risoluzione': ['1920x1080', '1280x720', '3840x2160', '1920x1080', '2560x1440',
                        '1280x720', '3840x2160', '1920x1080', '2560x1440', '1280x720'],
        'Bitrate': [8000, 4000, 15000, 6000, 12000, 3500, 18000, 8000, 10000, 2500],
        'qAudio': [0.85, 0.75, 0.95, 0.80, 0.90, 0.70, 0.92, 0.82, 0.88, 0.65],
        'qVideo': [0.90, 0.85, 0.98, 0.88, 0.92, 0.80, 0.95, 0.87, 0.90, 0.75]
    }
    df = pd.DataFrame(data)
    df['Id'] = df.reset_index().index
    df = df[['Id', 'nomeFormato', 'Risoluzione', 'Bitrate', 'qAudio', 'qVideo']]
    return Tabella('formato', df)


def genera_file(tabella_formati, tabella_film):
    # richiede in input la tabella film, e quella formati
    # File(*Id, nomeFormato, DataInserimento, dimensione, durata, film, server)
    list_formati = []
    list_film = []
    list_date = []
    list_dim = []
    list_dur = []
    # itera sui film
    for i in range(tavola_volumi.n_Film):
        # scegli il numero di file
        quanti_file = np.random.poisson(tavola_volumi.num_file_per_film)
        if quanti_file > 9:
            quanti_file = tavola_volumi.num_file_per_film
        # crea dataframe con righe formato
        formati_list = tabella_formati.sample(quanti_file)
        # scegli lista id formati
        format_parz = formati_list['Id'].tolist()
        # scegli lista dateinserimento
        dateins_parz = [random_date_between(datetime.now() - timedelta(days=tavola_volumi.num_mesi * 30), 
                                            datetime.now() - timedelta(days=tavola_volumi.num_mesi * 15)) 
                                            + timedelta(seconds=random.randint(-36000, 36000))
                                            for _ in range(quanti_file)]
        # scegli lista durata in secondi
        durata_parz = [random.randint(-10, 10) + 60 * tabella_film.loc[i, 'Durata'] for _ in range(quanti_file)]
        # scegli lista dimensione
        dim_parz = [dur * rate for dur, rate in zip(durata_parz, formati_list['Bitrate'].tolist())]
        # appendi
        list_formati += format_parz
        list_date += dateins_parz
        list_dim += dim_parz
        list_dur += durata_parz
        list_film += [i for _ in range(quanti_file)]

    df = pd.DataFrame({
        'Formato': list_formati,
        'DataInserimento': list_date,
        'Dimensione': list_dim,
        'Durata': list_dur,
        'Film': list_film
    })
    df['Id'] = df.reset_index().index
    df['Server'] = None
    df['DataInserimento'] = df['DataInserimento'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    df = df[['Id', 'Film', 'Formato', 'DataInserimento', 'Dimensione', 'Durata', 'Server']]
    return Tabella('file', df)


def genera_visualizzazione(tabella_connessioni, tabella_file):
    # attenzione perchè inizio e fine di Connessione, non sono strighe ma datetime
    # prende in input i dataframe delle connessioni e del file
    # Visualizzazione(*Connessione, *File, *Inizio, Fine)
    list_conn = []
    list_file = []
    list_ini = []
    list_fine = []
    for i in range(tabella_connessioni.shape[0]):
        quante_vis = np.random.poisson(tavola_volumi.num_vis_per_conn)
        lista_file = tabella_file.sample(quante_vis).reset_index(drop=True) # dataframe
        # eventuale controllo di compatibiltà con dispositivo
        file_parz = lista_file['Id'].tolist() 

        iniz_parz = []
        fine_parz = []
        # partiziona (InizioConnessione, FineConnessione) in quante_vis parti ottenendo una lista
        in_conn, fi_conn = tabella_connessioni.loc[i, 'Inizio'], tabella_connessioni.loc[i, 'Fine']
        # trasformo in_conn fi_conn in datetime
        in_conn, fi_conn = datetime.strptime(in_conn, '%Y-%m-%d %H:%M:%S'), datetime.strptime(fi_conn, '%Y-%m-%d %H:%M:%S')
        
        l_partiz = [in_conn + ii*(fi_conn - in_conn) / quante_vis for ii in range(quante_vis)]
        l_partiz.append(fi_conn)
        for ii in range(quante_vis):
            # scegli InizioVis e FineVis tra (Inizio-i-esimapart, min(Fine-i.esimapart, Inizio-i-esimapart + durata))
            iniziovis = generate_random_time_in_range(l_partiz[ii], 
                                                      l_partiz[ii] + 0.1 * (l_partiz[ii+1]-l_partiz[ii]))
            
            finevis = generate_random_time_in_range(iniziovis, 
                                                    min(l_partiz[ii+1], 
                                                        iniziovis + timedelta(seconds=int(lista_file.loc[ii, 'Durata']))))
            # appendi inizioVis e FineVis a iniz_part e fine_part
            iniz_parz.append(iniziovis)
            fine_parz.append(finevis)
        list_conn += [i for _ in range(quante_vis)]
        list_file += file_parz
        list_ini += iniz_parz
        list_fine += fine_parz

    df = pd.DataFrame({
        'Connessione': list_conn,
        'File': list_file,
        'Inizio': list_ini,
        'Fine': list_fine
    })
    df['Inizio'] = df['Inizio'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    df['Fine'] = df['Fine'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    return Tabella('visualizzazione', df)


def genera_recensione(tabella_visualizzazioni, tabella_file, tabella_connessioni):
    # prende in input il dataframe con le visualizzazioni
    # Recensione(*Film, *Cliente, Votazione, data)
    list_film = []
    list_cliente = []
    list_voto = []
    list_data = []
    # per ogni row di visualizzazioni
    for index, row in tabella_visualizzazioni.iterrows():
        # scegli se mettere una recensione o no
        if np.random.choice([True, False], p=[tavola_volumi.num_rec_per_vis, 
                                              1 - tavola_volumi.num_rec_per_vis]):
            # ottieni film da file
            list_film.append(tabella_file.loc[row['File'], 'Film'])
            # ottieni cliente da conn
            list_cliente.append(tabella_connessioni.loc[row['Connessione'], 'Cliente'])
            # metti un voto a caso
            list_voto.append(np.random.randint(1, 10))
            # metti una data a caso entro 12 ore dalla visione del film
            inizio_p = datetime.strptime(row['Inizio'], '%Y-%m-%d %H:%M:%S')
            list_data.append(generate_random_time_in_range(inizio_p, inizio_p + timedelta(hours=12)))
    df = pd.DataFrame({
        'Film': list_film,
        'Cliente': list_cliente,
        'Votazione': list_voto,
        'Data': list_data
    })
    # rimuovi duplicati su Film, Cliente
    df = df.drop_duplicates(subset=['Film', 'Cliente'])
    df['Data'] = df['Data'].apply(lambda x: x.strftime('%Y-%m-%d %H:%M:%S'))
    return Tabella('recensione', df)


def genera_paese():
    # Paese(*Cod, Nome, AreaGeografica, Lat, Lng)

    # prendiamo df_github
    df_github = pd.read_csv('ds-github.csv')
    df_github = df_github[['name', 'alpha-2', 'region', 'sub-region']]
    df_github.loc[153, 'alpha-2'] = 'NA'
    df_github = df_github._append({'name': 'Gaza Strip', 
                                'alpha-2':'XG', 
                                'region': 'Asia', 
                                'sub-region':'Western Asia'}, ignore_index=True)
    df_github = df_github._append({'name': 'Kosovo', 
                                'alpha-2':'XK', 
                                'region': 'Europe', 
                                'sub-region':'Southern Europe'}, ignore_index=True)
    df_github = df_github._append({'name': 'Svalbard', 
                                'alpha-2':'XR', 
                                'region': 'Europe', 
                                'sub-region':'Northern Europe'}, ignore_index=True)
    df_github = df_github._append({'name': 'West Bank', 
                                'alpha-2':'XW', 
                                'region': 'Asia', 
                                'sub-region':'Western Asia'}, ignore_index=True)

    # prendiamo ds-cities
    df_cities = pd.read_csv('ds-cities.csv')
    df_cities = df_cities[['lat', 'lng', 'iso2', 'country']]
    df_cities.loc[df_cities['country'] == 'Namibia', 'iso2'] = 'NA'
    # quelli che non sono in cities li tolgo da github
    for index, row in df_github.iterrows():
        if row['alpha-2'] not in df_cities['iso2'].unique():
            df_github = df_github.drop(index)
    # al momento sono uguali

    # adesso creiamo una tabella df_country(cod, country, lat, long, region)

    # Creiamo un DataFrame vuoto per df_country con gli attributi desiderati
    df_country = pd.DataFrame(columns=['code', 'name', 'zona', 'lat', 'lng'])

    # Iteriamo su ogni riga di df_github
    for index, row in df_github.iterrows():
        code = row['alpha-2']
        name = row['name']
        zona = row['sub-region']

        # Selezioniamo le righe corrispondenti in df_cities
        filtered_cities = df_cities[df_cities['iso2'] == code]

        # Calcoliamo la media delle 'lat' e 'lng' per queste righe
        lat_mean = filtered_cities['lat'].mean()
        lng_mean = filtered_cities['lng'].mean()

        # Aggiungiamo una nuova riga a df_country con le informazioni calcolate
        df_country = df_country._append({'code': code, 'name': name, 'zona': zona, 'lat': lat_mean, 'lng': lng_mean}, ignore_index=True)

    # Estrai i valori unici dalla colonna 'AreaGeografica' e ordinali alfabeticamente
    lista_c = sorted(df_country['zona'].unique())

    # Crea un dizionario che mappa i valori della colonna 'AreaGeografica' agli indici nella lista_c
    mappatura = {valore: indice for indice, valore in enumerate(lista_c)}

    # Sostituisci i valori nella colonna 'AreaGeografica' con gli indici dalla mappatura
    df_country['zona'] = df_country['zona'].map(mappatura)

    # Ora df_country contiene le informazioni richieste
    # Paese(*Cod, Nome, AreaGeografica, Lat, Lng)
    df_country.rename(columns={'code': 'Cod', 'name': 'Nome', 'zona': 'AreaGeografica', 'lat': 'Lat', 'lng':'Lng'}, inplace=True)
    return Tabella('paese', df_country)


def genera_iprange():
    df = pd.read_csv('dataset-iprange.csv')
    return Tabella('IPrange', df)


def genera_NonSupportato():
    lista_formati = list(range(tavola_volumi.num_Formato))
    lista_codici = ['AF', 'AL', 'DZ', 'AS', 'AD', 'AO', 'AI', 'AG', 'AR', 'AM', 'AW', 
            'AU', 'AT', 'AZ', 'BS', 'BH', 'BD', 'BB', 'BY', 'BE', 'BZ', 'BJ', 
            'BM', 'BT', 'BO', 'BQ', 'BA', 'BW', 'BR', 'BN', 'BG', 'BF', 'BI', 
            'CV', 'KH', 'CM', 'CA', 'KY', 'CF', 'TD', 'CL', 'CN', 'CX', 'CO', 
            'KM', 'CG', 'CD', 'CK', 'CR', 'CI', 'HR', 'CU', 'CW', 'CY', 'CZ', 
            'DK', 'DJ', 'DM', 'DO', 'EC', 'EG', 'SV', 'GQ', 'ER', 'EE', 'SZ', 
            'ET', 'FK', 'FO', 'FJ', 'FI', 'FR', 'GF', 'PF', 'GA', 'GM', 'GE', 
            'DE', 'GH', 'GI', 'GR', 'GL', 'GD', 'GP', 'GU', 'GT', 'GN', 'GW', 
            'GY', 'HT', 'VA', 'HN', 'HK', 'HU', 'IS', 'IN', 'ID', 'IR', 'IQ', 
            'IE', 'IM', 'IL', 'IT', 'JM', 'JP', 'JE', 'JO', 'KZ', 'KE', 'KI', 
            
            'KP', 'KR', 'KW', 'KG', 'LA', 'LV', 'LB', 'LS', 'LR', 'LY', 'LI', 
            'LT', 'LU', 'MO', 'MG', 'MW', 'MY', 'MV', 'ML', 'MT', 'MH', 'MQ', 
            'MR', 'MU', 'YT', 'MX', 'FM', 'MD', 'MC', 'MN', 'ME', 'MS', 'MA', 
            'MZ', 'MM', 'NA', 'NR', 'NP', 'NL', 'NC', 'NZ', 'NI', 'NE', 'NG', 
            'NU', 'NF', 'MK', 'MP', 'NO', 'OM', 'PK', 'PW', 'PA', 'PG', 'PY', 
            'PE', 'PH', 'PN', 'PL', 'PT', 'PR', 'QA', 'RE', 'RO', 'RU', 'RW', 
            'BL', 'SH', 'KN', 'LC', 'MF', 'PM', 'VC', 'WS', 'SM', 'ST', 'SA', 
            'SN', 'RS', 'SC', 'SL', 'SG', 'SX', 'SK', 'SI', 'SB', 'SO', 'ZA', 
            'GS', 'SS', 'ES', 'LK', 'SD', 'SR', 'SE', 'CH', 'SY', 'TW', 'TJ', 
            'TZ', 'TH', 'TL', 'TG', 'TO', 'TT', 'TN', 'TR', 'TM', 'TC', 'TV', 
            'UG', 'UA', 'AE', 'GB', 'US', 'UY', 'UZ', 'VU', 'VE', 'VN', 'VG', 
            'VI', 'WF', 'YE', 'ZM', 'ZW', 'XG', 'XK', 'XR', 'XW']
    l_Formato = [random.choice(lista_formati) for _ in range(tavola_volumi.n_NonSupportato)]
    l_paesi = [random.choice(lista_codici) for _ in range(tavola_volumi.n_NonSupportato)]
    df = pd.DataFrame({
        'Formato': l_Formato,
        'Paese': l_paesi
    })
    return Tabella('nonSupportato', df)






"""
att = genera_attore()
# att.dataframe_to_mysql_ddl()
att.genera_file_sql('popolamento_attore.sql')

reg = genera_regista()
# reg.dataframe_to_mysql_ddl()
reg.genera_file_sql('popolamento_regista.sql')


form = genera_formato()
# form.dataframe_to_mysql_ddl()
form.genera_file_sql('popolamento_formato.sql')


cli = genera_clienti()
# cli.dataframe_to_mysql_ddl()
cli.genera_file_sql('popolamento_cliente.sql')

disp = genera_dispositivo()
# disp.dataframe_to_mysql_ddl()
disp.genera_file_sql('popolamento_dispositivo.sql')

pia = genera_pianoTariffario()
# pia.dataframe_to_mysql_ddl()
pia.genera_file_sql('popolamento_pianotariffario.sql')

cr = genera_critico()
# cr.dataframe_to_mysql_ddl()
cr.genera_file_sql('popolamento_critico.sql')

li = genera_lingua()
# li.dataframe_to_mysql_ddl()
li.genera_file_sql('popolamento_lingua.sql')

conn = genera_connessione()
# conn.dataframe_to_mysql_ddl()
conn.genera_file_sql('popolamento_connessione.sql')

cart = genera_carteDiCredito()
# cart.dataframe_to_mysql_ddl()
cart.genera_file_sql('popolamento_cartadicredito.sql')

nons = genera_NonSupportato()
# nons.dataframe_to_mysql_ddl()
nons.genera_file_sql('popolamento_nonsupportato.sql')

film = genera_film()
# film.dataframe_to_mysql_ddl()
film.genera_file_sql('popolamento_film.sql')

sott = genera_sottoscrizione(cart.df)
# sott.dataframe_to_mysql_ddl()
sott.genera_file_sql('popolamento_sottoscrizione.sql')

part = genera_parte()
# part.dataframe_to_mysql_ddl()
part.genera_file_sql('popolamento_parte.sql')

premio = genera_premio(film.df)
# premio.dataframe_to_mysql_ddl()
premio.genera_file_sql('popolamento_premio.sql')

linguaa = genera_lingueAudio()
# linguaa.dataframe_to_mysql_ddl()
linguaa.genera_file_sql('popolamento_linguaaudio.sql')

linguas = genera_linguaSottotitoli()
# linguas.dataframe_to_mysql_ddl()
linguas.genera_file_sql('popolamento_linguasottotitoli.sql')

cra = genera_critica()
# cra.dataframe_to_mysql_ddl()
cra.genera_file_sql('popolamento_critica.sql')

files = genera_file(form.df, film.df)
# files.dataframe_to_mysql_ddl()
files.genera_file_sql('popolamento_file.sql')

"""


part = genera_parte()