# analisi_prestazioni
import pandas as pd
import tavola_volumi as tv
class Ridondanza:
    def __init__(self, n) -> None:
        self.nome = n
        self.op_agg = [] #lista operazioni che aggiornano la rid
        self.op_risp = [] # lista operazioni che beneficiano della rid
    def print_latex(self):
        print('Frequenza di aggiornamento: ', self.op_agg[0].frequenza)
        delta = 0
        for op in self.op_risp:
            # cerca tavola accessi di op senza la rid
            # cerca tavola accessi di op con la rid
            # fai la diff e moltiplicala per la frq di op, avrai ottenuto il delta di op, aggiungilo al delta generale
            pass
        
        # calcola il num di operazioni el per l'aggiornamento, moltiplicalo per la fr di agg, avrai trovato nA
        # se delta > nA, conviene
        return

        

class Operazione:
    def __init__(self, n, inp, outp, freq) -> None:
        self.nome = n
        self.frequenza = freq # giornaliera
        self.input = inp
        self.output = outp
        self.tavole_Accessi = [] # lista di dizionari che contengono ridondanza e tabella associata
    def print_latex(self):
        print(self.nome)
        print('Input:', self.input)
        print('Output:', self.output)
        print('Frequenza:', self.frequenza)
        for t in self.tavole_Accessi:
            if t['Ridondanza'] is None:
                print('Tabella accessi dell\'operazione senza ridondanze')
            else:
                print('Tabella degli accessi con ridondanza')
            print(t['Tabella'])
        pass

def calcola_operazioni(df):
    # calcola numero di operazioni elementari data una tabella degli accessi
    op = 0
    for index, row in df.iterrows():
        if row['Accesso'] == 'L':
            op += row['Numero']
        else:
            op += 3 * row['Numero']
    return round(op, 1)

ins_conn = Operazione(n='Inserimento connessione',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
calc_dist = Operazione(n='Calcolo distanza',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
ric_best_server = Operazione(n='Ricerca server migliore',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
r_visual = Operazione(n='Richiesta visualizzazione',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
racc_cont = Operazione(n='Raccomandazione contenuti',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
evita_sovrac = Operazione(n='Evita sovraccarico',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
ins_sott = Operazione(n='Inserimento sottoscrizione',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
ins_rec = Operazione(n='Inserimento recensione',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)
caching = Operazione(n='Caching',
                      inp='Email, Password, IP',
                      outp='Record nella tabella Connessione',
                      freq=0)

abb_ut = Ridondanza(n='Abbonamento cliente')
scad_ut = Ridondanza(n='Scadenza abbonamento cliente')
dist = Ridondanza(n='Distanze paesi-server')
paese_conn = Ridondanza(n='Paese della connessione')
n_vis = Ridondanza(n='Numero visualizzazioni')
rat_medio = Ridondanza(n='Rating madio di ogni film')
car_serv = Ridondanza(n='Carico server')
rat_coppie = Ridondanza(n='Rating per ogni coppia persona-film')


# tabella accessi Inserimento Connessione senza_rid
tabella = pd.DataFrame([
    ['Cliente', 'E', 'L', 1, 'Email e Password'],
    ['Possesso', 'R', 'L', tv.num_carte_per_cliente, 'Carte del cliente'],
    ['CartadiCredito', 'E', 'L', tv.num_carte_per_cliente, 'Carte del cliente'],
    ['Pagamento', 'R', 'L', tv.num_pagamenti_al_mese*tv.num_mesi, 'Pagamenti'],
    ['Sottoscrizione', 'E', 'L', tv.num_pagamenti_al_mese*tv.num_mesi, 'Controllare data'],
    ['Connessione', 'E', 'S', 1, 'Record Connessione']
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
ins_conn.tavole_Accessi.append({'Ridondanza': None, 'Tabella': tabella})

# tabella accessi Inserimento Connessione con rid scadenza
tabella = pd.DataFrame([
    ['Cliente', 'E', 'L', 1, 'Email e Password'],
    ['Connessione', 'E', 'S', 1, 'Record Connessione']
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
ins_conn.tavole_Accessi.append({'Ridondanza': scad_ut, 'Tabella': tabella})
scad_ut.op_risp.append(scad_ut)

# tabella accessi Inserimento Connessione con rid posiz in conn
tabella = pd.DataFrame([
    ['Cliente', 'E', 'L', 1, 'Email e Password'],
    ['Possesso', 'R', 'L', tv.num_carte_per_cliente, 'Carte del cliente'],
    ['CartadiCredito', 'E', 'L', tv.num_carte_per_cliente, 'Carte del cliente'],
    ['Pagamento', 'R', 'L', tv.num_pagamenti_al_mese*tv.num_mesi, 'Pagamenti'],
    ['Sottoscrizione', 'E', 'L', tv.num_pagamenti_al_mese*tv.num_mesi, 'Controllare data'],
    ['Iprange', 'E', 'L', 1, 'Cercare paese'],
    ['Connessione', 'E', 'S', 1, 'Record Connessione']
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
ins_conn.tavole_Accessi.append({'Ridondanza': paese_conn, 'Tabella': tabella})
paese_conn.op_agg.append(ins_conn)




#||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||




# tabella accessi Calcola Distanza senza rid
tabella = pd.DataFrame([
    ['Connessione'],
    ['IPrange']
    ['Localizzazione']
    ['Paese']
    ['Server']
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
calc_dist.tavole_Accessi.append({'Ridonanza': None, 'Tabella': tabella})

# tabella accessi Calcola Distanza con rid distanza
tabella = pd.DataFrame([
    ['Connessione'],
    ['IPrange']
    ['Localizzazione']
    ['Paese-server']
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
calc_dist.tavole_Accessi.append({'Ridonanza': dist, 'Tabella': tabella})
dist.op_risp.append(calc_dist)


# tabella accessi Calcola Distanza con rid paese
tabella = pd.DataFrame([
    ['Connessione']
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
calc_dist.tavole_Accessi.append({'Ridonanza': paese_conn, 'Tabella': tabella})
paese_conn.op_risp.append(calc_dist)



#|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||



# tabella accessi ricerca del server migliore senza rid
tabella = pd.DataFrame([ # la visualizzazione, mi servono distanza e carico
    ['Visualizzazione'],
    ['Connessione'],
    ['IPrange'],
    ['Localizzazione'],
    ['Paese'], # a questo punto ho le coordinate del paese
    ['Server'], # a questo punto ho le distanze
    ['Connessione'],
    ['ConnessioneServer'],
    ['Server'] # a quetso punto ho il carico
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
ric_best_server.tavole_Accessi.append({'Ridonanza': None, 'Tabella': tabella})

# tabella accessi ricerca del server migliore senza rid
tabella = pd.DataFrame([ # la visualizzazione, mi servono distanza e carico
    ['Visualizzazione'],
    ['Connessione'],
    ['IPrange'],
    ['Localizzazione'],
    ['Paese'], # a questo punto ho le coordinate del paese
    ['Server'], # a questo punto ho le distanze
    ['Connessione'],
    ['ConnessioneServer'],
    ['Server'] # a quetso punto ho il carico
], columns=['Nome', 'Tipo', 'Accesso', 'Numero', 'Descrizione'])
ric_best_server.tavole_Accessi.append({'Ridonanza': None, 'Tabella': tabella})







