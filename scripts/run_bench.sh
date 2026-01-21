#!/usr/bin/env bash
# run_bench.sh — wrapper generico per benchmark con output timestampato
# Output: RESULTS/<workload>_<env>_<YYYYMMDD-HHMM>.txt + file cumulativo *_ALL.txt

set -euo pipefail

# ---------- default ----------
REPS="${REPS:-7}"
SLEEP_SECS="${SLEEP_SECS:-90}"
WORKLOAD="${WORKLOAD:-unset}"
ENVIRONMENT="${ENVIRONMENT:-unset}"
RESULTS_DIR="${RESULTS_DIR:-RESULTS}"

# ---------- util ----------
ts() { date +"%Y%m%d-%H%M"; }               # timestamp locale
log() { printf "%s %s\n" "$(date '+%H:%M:%S')" "$*" >&2; }

usage() {
  cat <<EOF
Usage:
  $0 -w <workload> -e <environment> -- <command ...>

Preset (più comodi):
  $0 -w http_1kb   -e bare   wrk   --url http://\$SERVER_IP/1kb    --threads 4 --conns 128 --dur 60s
  $0 -w redis      -e docker memtier --server \$SERVER_IP --port 6379 --ratio 1:10 --threads 4 --clients 50 --datasize 64 --requests 500000
  $0 -w pgbench    -e vm     pgbench --host \$SERVER_IP --user postgres --db postgres --clients 32 --threads 8 --time 60 --init-scale 10
  $0 -w iperf      -e bare   iperf3 --server \$SERVER_IP --time 60
  $0 -w fio_rr4k   -e bare   fio    --file /srv/bench/io/testfile --rw randread --bs 4k --iodepth 32 --numjobs 4 --size 2G --time 60
  $0 -w sb_cpu     -e bare   sysbench --cpu --threads 2 --time 60
  $0 -w stress_mix -e vm     stressng --cpu 4 --vm 2 --vm-bytes 1G --io 2 --time 120

Opzioni ambientali (facoltative):
  REPS=<n>           numero di ripetizioni (default: 7)
  SLEEP_SECS=<n>     pausa tra run in secondi (default: 90)
  RESULTS_DIR=<dir>  cartella risultati (default: RESULTS)

Esempio generico:
  $0 -w http_100kb -e docker -- curl -s http://\$SERVER_IP/100kb

EOF
  exit 1
}

# ---------- parse min ----------
[[ $# -lt 1 ]] && usage
CMD=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -w|--workload) WORKLOAD="$2"; shift 2 ;;
    -e|--env)      ENVIRONMENT="$2"; shift 2 ;;
    --) shift; CMD=("$@"); break ;;
    wrk|memtier|pgbench|iperf3|fio|sysbench|stressng)
      # modalita' preset breve: <preset> [args...]
      PRESET="$1"; shift
      PRESET_ARGS=("$@"); CMD=("__PRESET__" "$PRESET" "${PRESET_ARGS[@]}"); break ;;
    *) usage ;;
  esac
done

[[ "$WORKLOAD" == "unset" || "$ENVIRONMENT" == "unset" || -z "${CMD[*]-}" ]] && usage

mkdir -p "$RESULTS_DIR"
ALL_FILE="${RESULTS_DIR}/${WORKLOAD}_${ENVIRONMENT}_ALL.txt"

# ---------- builder preset ----------
build_cmd() {
  local preset="$1"; shift
  case "$preset" in
    wrk)
      # args: --url URL [--threads N] [--conns N] [--dur 60s]
      local URL="" THREADS=4 CONNS=128 DUR=60s
      while [[ $# -gt 0 ]]; do case "$1" in
        --url) URL="$2"; shift 2 ;;
        --threads) THREADS="$2"; shift 2 ;;
        --conns) CONNS="$2"; shift 2 ;;
        --dur) DUR="$2"; shift 2 ;;
        *) shift ;;
      esac; done
      [[ -z "$URL" ]] && { echo "wrk: --url required" >&2; exit 2; }
      printf "wrk -t%s -c%s -d%s %s" "$THREADS" "$CONNS" "$DUR" "$URL"
      ;;
    memtier)
      # args: --server IP --port 6379 --ratio 1:10 --threads 4 --clients 50 --datasize 64 --requests 500000 --password PASS(opt)
      local S="" P=6379 R="1:10" T=4 C=50 D=64 N=500000 A=""
      while [[ $# -gt 0 ]]; do case "$1" in
        --server) S="$2"; shift 2 ;;
        --port) P="$2"; shift 2 ;;
        --ratio) R="$2"; shift 2 ;;
        --threads) T="$2"; shift 2 ;;
        --clients) C="$2"; shift 2 ;;
        --datasize) D="$2"; shift 2 ;;
        --requests) N="$2"; shift 2 ;;
        --password) A=" -a $2"; shift 2 ;;
        *) shift ;;
      esac; done
      [[ -z "$S" ]] && { echo "memtier: --server required" >&2; exit 2; }
      printf "memtier_benchmark -s %s -p %s --ratio=%s -t %s -c %s -d %s -n %s%s" "$S" "$P" "$R" "$T" "$C" "$D" "$N" "$A"
      ;;
    pgbench)
      # args: --host IP --user USER --db DB --clients 32 --threads 8 --time 60 --init-scale 10(opt)
      local H="" U="postgres" DB="postgres" C=32 J=8 T=60 S=""
      while [[ $# -gt 0 ]]; do case "$1" in
        --host) H="$2"; shift 2 ;;
        --user) U="$2"; shift 2 ;;
        --db) DB="$2"; shift 2 ;;
        --clients) C="$2"; shift 2 ;;
        --threads) J="$2"; shift 2 ;;
        --time) T="$2"; shift 2 ;;
        --init-scale) S="$2"; shift 2 ;;
        *) shift ;;
      esac; done
      [[ -z "$H" ]] && { echo "pgbench: --host required" >&2; exit 2; }
      if [[ -n "$S" ]]; then
        echo "pgbench -h $H -U $U -i -s $S $DB && pgbench -h $H -U $U -c $C -j $J -T $T $DB"
      else
        echo "pgbench -h $H -U $U -c $C -j $J -T $T $DB"
      fi
      ;;
    iperf3)
      # args: --server IP --time 60
      local S="" T=60
      while [[ $# -gt 0 ]]; do case "$1" in
        --server) S="$2"; shift 2 ;;
        --time) T="$2"; shift 2 ;;
        *) shift ;;
      esac; done
      [[ -z "$S" ]] && { echo "iperf3: --server required" >&2; exit 2; }
      printf "iperf3 -c %s -t %s" "$S" "$T"
      ;;
    fio)
      # args: --file PATH --rw randread|read|randwrite|write --bs 4k --iodepth 32 --numjobs 4 --size 2G --time 60
      local F="" RW="randread" BS="4k" QD=32 NJ=4 SZ="2G" TM=60
      while [[ $# -gt 0 ]]; do case "$1" in
        --file) F="$2"; shift 2 ;;
        --rw) RW="$2"; shift 2 ;;
        --bs) BS="$2"; shift 2 ;;
        --iodepth) QD="$2"; shift 2 ;;
        --numjobs) NJ="$2"; shift 2 ;;
        --size) SZ="$2"; shift 2 ;;
        --time) TM="$2"; shift 2 ;;
        *) shift ;;
      esac; done
      [[ -z "$F" ]] && { echo "fio: --file required" >&2; exit 2; }
      printf "fio --name=bench --filename=%s --rw=%s --bs=%s --iodepth=%s --numjobs=%s --size=%s --time_based --runtime=%s --group_reporting" \
        "$F" "$RW" "$BS" "$QD" "$NJ" "$SZ" "$TM"
      ;;
    sysbench)
      # args: --cpu [--threads N --time 60]  |  --memory [--block 1M --total 10G]
      local MODE="" THREADS=2 TIME=60 BLOCK="1M" TOTAL="10G"
      while [[ $# -gt 0 ]]; do case "$1" in
        --cpu) MODE="cpu"; shift ;;
        --memory) MODE="memory"; shift ;;
        --threads) THREADS="$2"; shift 2 ;;
        --time) TIME="$2"; shift 2 ;;
        --block) BLOCK="$2"; shift 2 ;;
        --total) TOTAL="$2"; shift 2 ;;
        *) shift ;;
      esac; done
      [[ -z "$MODE" ]] && { echo "sysbench: choose --cpu or --memory" >&2; exit 2; }
      if [[ "$MODE" == "cpu" ]]; then
        printf "sysbench cpu --threads=%s --time=%s run" "$THREADS" "$TIME"
      else
        printf "sysbench memory --memory-block-size=%s --memory-total-size=%s run" "$BLOCK" "$TOTAL"
      fi
      ;;
    stressng)
      # args: passthrough after 'stressng'
      printf "stress-ng %s" "$(printf "%q " "$@")"
      ;;
    *) echo "unknown preset: $preset" >&2; exit 2 ;;
  esac
}

# ---------- run loop ----------
for ((i=1; i<=REPS; i++)); do
  TS="$(ts)"
  OUT_FILE="${RESULTS_DIR}/${WORKLOAD}_${ENVIRONMENT}_${TS}.txt"
  log "Run $i/$REPS → ${OUT_FILE}"

  if [[ "${CMD[0]}" == "__PRESET__" ]]; then
    PRESET_CMD="$(build_cmd "${CMD[1]}" "${CMD[@]:2}")"
  else
    PRESET_CMD="${CMD[*]}"
  fi

  {
    echo "=== $(date '+%Y-%m-%d %H:%M:%S') — workload=${WORKLOAD} env=${ENVIRONMENT} run=${i}/${REPS} ==="
    echo "\$ ${PRESET_CMD}"
    eval "${PRESET_CMD}"
    echo "=== end ==="
  } | tee "${OUT_FILE}" -a "${ALL_FILE}"

  if [[ $i -lt $REPS ]]; then
    log "sleep ${SLEEP_SECS}s…"
    sleep "${SLEEP_SECS}"
  fi
done

log "Done. Files in ${RESULTS_DIR}/"

