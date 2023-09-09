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


lista_elem = []
# quelle decise a prescindere da sakila
n_PianoTariffario = 5 
n_Server = 17



lista_elem.append(Elem("Server", "E", n_Server))
lista_elem.append(Elem("PianoTariffario", "E", n_PianoTariffario))
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

lista_elem.append(Elem("Film", "E", n_Film))
lista_elem.append(Elem("Attore", "E", n_Attore))
lista_elem.append(Elem("Parte", "R", n_Parte))
lista_elem.append(Elem("Cliente", "E", n_Cliente))
lista_elem.append(Elem("Paese", "E", n_Paese))
lista_elem.append(Elem("IPrange", "E", n_IPrange))
lista_elem.append(Elem("Localizzazione", "E", n_Localizzazione))
lista_elem.append(Elem("Produzione", "R", n_Produzione))
lista_elem.append(Elem("Appartenenza", "R", n_Appartenenza))
lista_elem.append(Elem("Regia", "R", n_Regia))
lista_elem.append(Elem("Regista", "E", n_Regista))

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

lista_elem.append(Elem("Premio", "E", n_Premio))
lista_elem.append(Elem("Assegnazione", "R", n_Assegnazione))

# pagamenti
num_carte_per_cliente = 1.1
n_CartadiCredito = int(n_Cliente * num_carte_per_cliente)
n_Possesso = n_CartadiCredito

num_pagamenti_al_mese = 1.2
n_Sottoscrizione = int(n_Cliente * num_pagamenti_al_mese)
n_Pagamento = n_Sottoscrizione
n_Abbonamento = n_Sottoscrizione
lista_elem.append(Elem("CartadiCredito", "E", n_CartadiCredito))
lista_elem.append(Elem("Possesso", "R", n_Possesso))
lista_elem.append(Elem("Sottoscrizione", "E", n_Sottoscrizione))
lista_elem.append(Elem("Abbonamento", "R", n_Abbonamento))
lista_elem.append(Elem("Pagamento", "R", n_Pagamento))


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

lista_elem.append(Elem("Connessione", "E", n_Connessione))
lista_elem.append(Elem("Visualizzazione", "E", n_Visualizzazione))
lista_elem.append(Elem("ConnessioneCliente", "R", n_ConnessioneCliente))
lista_elem.append(Elem("Mezzo", "R", n_Mezzo))
lista_elem.append(Elem("FV", "R", n_FV))
lista_elem.append(Elem("VC", "R", n_VC))
lista_elem.append(Elem("Dispositivo", "E", n_Dispositivo))
lista_elem.append(Elem("Recensione", "E", n_Recensione))

# file
num_file_per_film = 2
n_File = n_Film * num_file_per_film
n_Codifica = n_File
n_NonSupportato = 15
num_Formato = 10





n_Presenza = n_File


perc_conn_att = 0.25 # in un giorno in cui un utente si connette, per quanto tempo lo fa in perc?
num_conn_attive = int(n_Cliente * (num_conn_per_cliente  /  30) * perc_conn_att)

n_ConnessioneServer = num_conn_attive


lista_elem.append(Elem("File", "E", n_File))
lista_elem.append(Elem("Codifica", "R", n_Codifica))
lista_elem.append(Elem("Presenza", "R", n_Presenza))
lista_elem.append(Elem("ConnessioneServer", "R", n_ConnessioneServer))
lista_elem.append(Elem("NonSupportato", "R", n_NonSupportato))

# critica, lingua
n_Critico = 5
num_critiche_per_critico = 20
n_Critica = n_Critico * num_critiche_per_critico

n_Lingua = 10
num_lingue_per_film = 3
n_LinguaAudio = n_Film * num_lingue_per_film
n_LinguaSottotitoli = n_LinguaAudio

lista_elem.append(Elem("Critico", "E", n_Critico))
lista_elem.append(Elem("Critica", "R", n_Critica))
lista_elem.append(Elem("Lingua", "E", n_Lingua))
lista_elem.append(Elem("LinguaAudio", "R", n_LinguaAudio))
lista_elem.append(Elem("LinguaSottotitoli", "R", n_LinguaSottotitoli))




def stampa_latex():
    str_cod = ""

    for e in lista_elem:
        str_cod += str(e)
        str_cod += " \\\ "
        str_cod += "\n \hline \n"

    print(str_cod)

