"""
preparazione tavola volumi in funzione di altre variabili
modifica le variabili generali e genera il codice latex
"""


class Elem:
    def __init__(self, no, t, num):
        self.nome = no
        self.tipo = t
        self.num = num

    def __str__(self):
        st = ""
        st += self.nome
        st += " & "
        st += self.tipo
        st += " & "
        st += str(int(self.num))
        return st


lista_volumi = []
# quelle decise a prescindere da sakila
n_PianoTariffario = 5 
n_Server = 17



lista_volumi.append(Elem("Server", "E", n_Server))
lista_volumi.append(Elem("PianoTariffario", "E", n_PianoTariffario))
# quelle in sakila
n_Film = 1000
n_Attore = 200

num_att_per_film = 5
n_Parte = n_Film * num_att_per_film
n_Cliente = 599
n_Paese = 249 # codici iso
n_IPrange = 250000  
n_Localizzazione = n_IPrange

n_Produzione = n_Paese
n_Appartenenza = n_Paese
n_Regia = n_Film
num_film_per_regista = 1.1
n_Regista = int(n_Film / num_film_per_regista)

lista_volumi.append(Elem("Film", "E", n_Film))
lista_volumi.append(Elem("Attore", "E", n_Attore))
lista_volumi.append(Elem("Parte", "R", n_Parte))
lista_volumi.append(Elem("Cliente", "E", n_Cliente))
lista_volumi.append(Elem("Paese", "E", n_Paese))
lista_volumi.append(Elem("IPrange", "E", n_IPrange))
lista_volumi.append(Elem("Localizzazione", "E", n_Localizzazione))
lista_volumi.append(Elem("Produzione", "R", n_Produzione))
lista_volumi.append(Elem("Appartenenza", "R", n_Appartenenza))
lista_volumi.append(Elem("Regia", "R", n_Regia))
lista_volumi.append(Elem("Regista", "E", n_Regista))

"""
si suppone che la piattaforma venga inizialmente popolata usando i dati di un periodo lungo
num_mesi, 
i volumi dovranno essere relativi a un valore atteso che potrebbe anche essere diverso da quello
ottenuto dopo il popolamento, per queesto motivo esiste la variabile
num_mesi_exp, 
che indica il numero di mesi atteso a partire da quando viene popolato
"""

num_mesi = 3
num_mesi_exp = 2
# di quanti anni dovranno essere inseriti i premi
num_anni_premio = 7
# quanti tipi di premio esistono
num_premi = 32
n_Premio = num_anni_premio * num_premi
n_Assegnazione = n_Premio

lista_volumi.append(Elem("Premio", "E", n_Premio))
lista_volumi.append(Elem("Assegnazione", "R", n_Assegnazione))

# pagamenti
num_carte_per_cliente = 1.1
n_CartadiCredito = int(n_Cliente * num_carte_per_cliente)
n_Possesso = n_CartadiCredito

num_pagamenti_al_mese = 1.2
n_Sottoscrizione = int(n_Cliente * num_pagamenti_al_mese * (num_mesi+num_mesi_exp))
n_Pagamento = n_Sottoscrizione
n_Abbonamento = n_Sottoscrizione
lista_volumi.append(Elem("CartadiCredito", "E", n_CartadiCredito))
lista_volumi.append(Elem("Possesso", "R", n_Possesso))
lista_volumi.append(Elem("Sottoscrizione", "E", n_Sottoscrizione))
lista_volumi.append(Elem("Abbonamento", "R", n_Abbonamento))
lista_volumi.append(Elem("Pagamento", "R", n_Pagamento))


# conn-serv
num_conn_per_cliente = 10  # al mese
n_Connessione = num_conn_per_cliente * (num_mesi + num_mesi_exp) * n_Cliente

num_vis_per_conn = 1.3 
n_Visualizzazione = n_Connessione * num_vis_per_conn
n_ConnessioneCliente = n_Connessione
n_Mezzo = n_Connessione
n_FV = n_Visualizzazione
n_VC = n_Visualizzazione
num_rec_per_vis = 0.7 ### 0.7
n_Recensione = n_Visualizzazione * num_rec_per_vis 
n_Dispositivo = 10

lista_volumi.append(Elem("Connessione", "E", n_Connessione))
lista_volumi.append(Elem("Visualizzazione", "E", n_Visualizzazione))
lista_volumi.append(Elem("ConnessioneCliente", "R", n_ConnessioneCliente))
lista_volumi.append(Elem("Mezzo", "R", n_Mezzo))
lista_volumi.append(Elem("FV", "R", n_FV))
lista_volumi.append(Elem("VC", "R", n_VC))
lista_volumi.append(Elem("Dispositivo", "E", n_Dispositivo))
lista_volumi.append(Elem("Recensione", "E", n_Recensione))

# file
num_file_per_film = 2
n_File = n_Film * num_file_per_film
n_Codifica = n_File
n_NonSupportato = 15
num_Formato = 10





n_Presenza = n_File


perc_vis_att = 0.25 # in un giorno in cui un utente si connette, per quanto tempo lo fa in perc?
num_vis_attive = int(n_Cliente * (num_conn_per_cliente  /  30) * perc_vis_att)

n_ConnessioneServer = num_vis_attive


lista_volumi.append(Elem("File", "E", n_File))
lista_volumi.append(Elem("Codifica", "R", n_Codifica))
lista_volumi.append(Elem("Presenza", "R", n_Presenza))
lista_volumi.append(Elem("ConnessioneServer", "R", n_ConnessioneServer))
lista_volumi.append(Elem("NonSupportato", "R", n_NonSupportato))

# critica, lingua
n_Critico = 5
num_critiche_per_critico = 20
n_Critica = n_Critico * num_critiche_per_critico

n_Lingua = 10
num_lingue_per_film = 3
n_LinguaAudio = n_Film * num_lingue_per_film
n_LinguaSottotitoli = n_LinguaAudio

lista_volumi.append(Elem("Critico", "E", n_Critico))
lista_volumi.append(Elem("Critica", "R", n_Critica))
lista_volumi.append(Elem("Lingua", "E", n_Lingua))
lista_volumi.append(Elem("LinguaAudio", "R", n_LinguaAudio))
lista_volumi.append(Elem("LinguaSottotitoli", "R", n_LinguaSottotitoli))


lista_frequenze = []
class Operazione:
    def __init__(self, no, f):
        self.nome = no
        self.freq = f

    def __str__(self):
        st = ""
        st += self.nome
        st += " & "
        st += str(int(self.freq))
        return st
# frequenze mensili

fr_conn = n_Cliente * num_conn_per_cliente
lista_frequenze.append(Operazione("Inserisci connessione", fr_conn))
lista_frequenze.append(Operazione("Disconnessione", fr_conn))
fr_vis = fr_conn * num_vis_per_conn
lista_frequenze.append(Operazione("Richiedi visualizzazione", fr_vis))
lista_frequenze.append(Operazione("Termina visualizzazione", fr_vis))
fr_rec = fr_vis * num_rec_per_vis
lista_frequenze.append(Operazione("Inserisci recensione", fr_rec))
fr_calc_dist = fr_vis * (n_Server + num_vis_attive)
lista_frequenze.append(Operazione("Calcolo distanza", fr_calc_dist))
lista_frequenze.append(Operazione("Inserimento sottoscrizione", num_pagamenti_al_mese * n_Cliente))
fr_rat_pers = fr_conn * n_Film
lista_frequenze.append(Operazione("Rating personalizzato", fr_rat_pers))
# caching
# inserimento file

def stampa_latex_volumi():
    str_cod = ""

    for e in lista_volumi:
        str_cod += str(e)
        str_cod += " \\\ "
        str_cod += "\n \hline \n"
    str_cod += "\n" + "Frequenze operazioni" + "\n"

    for e in lista_frequenze:
        str_cod += str(e)
        str_cod += " \\\ "
        str_cod += "\n \hline \n"
    print(str_cod)

stampa_latex_volumi()


