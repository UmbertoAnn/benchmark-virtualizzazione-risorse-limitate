# Benchmarking di Virtualizzazione e Containerizzazione su Hardware a Risorse Limitate

## Panoramica

Questo repository contiene gli **artefatti sperimentali e i risultati dei benchmark** prodotti nell’ambito di una tesi di Laurea Magistrale in Informatica incentrata sulla **Analisi comparativa prestazionale tra ambienti bare-metal, containerizzati e virtualizzati su risorse hardware limitate**.

L’obiettivo dell’attività sperimentale è analizzare l’overhead introdotto da:
- virtualizzazione hardware (macchine virtuali),
- virtualizzazione a livello di sistema operativo (container Docker),
- combinazione delle due tecnologie,

utilizzando sia **carichi di lavoro sintetici** sia **benchmark applicativi**.

Tutti i test sono stati eseguiti tramite **script di automazione**, al fine di garantire ripetibilità e coerenza dei risultati.

---

## Struttura del repository

Il repository è organizzato come segue:

- ├── RESULTS_BARE/ --- (contiene i risultati dei benchmark applicativi eseguiti dal client verso "bare-metal" e "container su bare-metal")
- │ ├── http_1kb_bare_YYYYMMDD-HHMM.txt
- │ ├── redis_bare_YYYYMMDD-HHMM.txt
- │ ├── http_1kb_docker_YYYYMMDD-HHMM.txt
- │ ├── redis_docker_YYYYMMDD-HHMM.txt
- │ └── ...
- │
- ├── RESULTS_VM/ --- (contiene i risultati dei benchmark applicativi eseguiti dal client verso "macchina virtuale" e "container su macchina virtuale")
- │ ├── http_1kb_bare_YYYYMMDD-HHMM.txt
- │ ├── postgres_bare_YYYYMMDD-HHMM.txt
- │ ├── http_1kb_docker_YYYYMMDD-HHMM.txt
- │ ├── postgres_docker_YYYYMMDD-HHMM.txt
- │ └── ...
- │
- ├── RESULTS_LATO_SERVER_BARE/ --- (contiene i risultati dei benchmark sintetici eseguiti su server su ambiente "bare-metal" e su "container su bare-metal")
- │ ├── sysbench_cpu_bare_.txt
- │ ├── fio_seq64k_bare_.txt
- │ └── ...
- │
- ├── RESULTS_LATO_SERVER_VM/ --- (contiene i risultati dei benchmark sintetici eseguiti su server su macchina virtuale e su "container su macchina virtuale")
- │ ├── sysbench_cpu_bare_.txt
- │ ├── fio_seq64k_bare_.txt
- │ └── ...
- │
- ├── RESULTS_LATO_SERVER_VM_direct1_nocache_fio64k/ --- (contiene i risultati fio64k eseguiti in modalità Direct I/O, ossia senza uso della cache)
- │ ├── fio_seq64k_bare_.txt
- │ └── ...
- │
- ├── scripts/
- │ ├── run_bench.sh
- │ ├── Makefile.client
- │ └── Makefile.server
- │
- └── README.md


---

## Ambienti sperimentali considerati

Gli esperimenti sono stati condotti nei seguenti ambienti di esecuzione:

- **Bare metal**
- **Container su bare metal**
- **Macchina virtuale (KVM)**
- **Container su macchina virtuale**

Per i **benchmark sintetici lato server** (CPU, memoria, I/O su disco) sono state considerate esclusivamente le configurazioni **bare metal** e **macchina virtuale**, in quanto, come spiegato nella tesi, i container condividono il kernel del sistema host e non introducono un ambiente di esecuzione kernel-level distinto.

---

## Benchmark utilizzati

### Misurazione capacità del sottosistema di rete (effettuato dal client)
- **iperf3** – caratterizzazione del sottosistema di rete

### Benchmark sintetici (effettuati sul server)
- **sysbench** – valutazione delle prestazioni CPU e memoria
- **fio** – analisi delle prestazioni del sottosistema di I/O su storage
- **stress-ng** – test qualitativi di stabilità del sistema sotto carico misto

### Benchmark applicativi (effettuati dal client)
- **wrk** – benchmarking HTTP del web server Nginx
- **pgbench** – valutazione delle prestazioni del database PostgreSQL
- **memtier_benchmark** – benchmarking del database Redis
- **YCSB** – valutazione delle prestazioni del database MongoDB

---

## Convenzione di denominazione dei file di risultato

Ogni esecuzione di benchmark produce un file di output testuale denominato secondo la seguente convenzione:

<workload>_<ambiente>_<YYYYMMDD-HHMM>.txt


Esempio:

http_1kb_bare_20251122-2311.txt


Dove:
- `<workload>` identifica il tipo di benchmark eseguito,
- `<ambiente>` indica l’ambiente di esecuzione,
- `<YYYYMMDD-HHMM>` rappresenta la data e l’orario di esecuzione.

**NOTA:** nelle cartelle che contengono i risultati ottenuti su macchina virtuale (RESULTS_VM, RESULTS_LATO_SERVER_VM, RESULTS_LATO_SERVER_VM_direct1_nocache_fio64k) i file testuali nominati `<workload>_bare_<YYYYMMDD-HHMM>.txt` contengono i risultati ottenuti in maniera "bare" su macchina virtuale.

Ogni benchmark è stato eseguito **7 volte** (loop implementato dallo script **run_bench.sh**); i risultati riportati nella tesi considerano la metrica **throughput** e rappresentano la **media aritmetica delle 7 esecuzioni**.

---

## Riproducibilità degli esperimenti

I benchmark sono stati eseguiti mediante script di automazione (`run_bench.sh`) e Makefile, in modo da garantire la riproducibilità delle misure.  
I dettagli relativi alla configurazione degli ambienti, ai parametri di esecuzione e alla procedura sperimentale sono descritti nella tesi e supportati dai file presenti in questo repository.

Questo repository è reso disponibile al fine di:
- garantire **trasparenza**,
- consentire la **verifica dei risultati**,
- facilitare **eventuali estensioni future** del lavoro sperimentale.

---

## Relazione con la tesi

Il presente repository accompagna la tesi di laurea magistrale:

> **Analisi comparativa prestazionale tra ambienti bare-metal, containerizzati e virtualizzati su risorse hardware limitate**

Il repository contiene esclusivamente **materiale sperimentale** (script e output dei benchmark).  
L’analisi dei dati, la loro aggregazione e l’interpretazione dei risultati sono discusse all’interno del documento di tesi.

---

## Note

- Gli output dei benchmark sono mantenuti in forma grezza per evitare alterazioni dovute a post-elaborazioni.
- I grafici e i risultati aggregati sono stati generati separatamente a partire da tali output.
- Il repository non è concepito come framework di benchmarking, ma come **materiale di supporto a fini accademici**.

---

## Licenza

Il materiale contenuto in questo repository è fornito esclusivamente per scopi accademici e di ricerca.





