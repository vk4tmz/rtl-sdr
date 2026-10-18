#!/usr/bin/env bash
# Capture controlled live rtl_fm PCM outputs from three filter modes.
# Run on devlap200 with the NooElec idle. Does not install or alter devices.
set -euo pipefail
cd "$(dirname "$0")/.."
BIN="$PWD/build-fm-isolation/src/rtl_fm"
LIB="$PWD/build-fm-isolation/src"
OUT="${1:-/tmp/rtl-fm-compare-927}"
FREQ="${2:-92.7M}"
SECONDS="${3:-12}"
mkdir -p "$OUT"
if [[ ! -x "$BIN" ]]; then echo "First run: bash scripts/build-isolated-rtl-fm.sh" >&2; exit 1; fi
printf 'Binary: %s\n' "$BIN"
sha256sum "$BIN" > "$OUT/binary.sha256"
LD_LIBRARY_PATH="$LIB" ldd "$BIN" > "$OUT/ldd.txt"
for mode in baseline fir9 sharp; do
  options=()
  case "$mode" in
    baseline) ;;
    fir9) options=(-F 9) ;;
    sharp) options=(-E sharp) ;;
  esac
  echo "=== $mode: $FREQ, ${SECONDS}s ==="
  start=$(date +%s%N)
  # timeout sends SIGINT so rtl_fm can close the SDR normally; 3 seconds
  # grace before kill. Exit 124 is expected for elapsed capture period.
  set +e
  timeout -s INT -k 3s "${SECONDS}s" env LD_LIBRARY_PATH="$LIB" "$BIN" \
    -f "$FREQ" -M fm -s 240k -o 4 -A fast -r 48000 \
    -g 19.7 -p 44 -E deemp "${options[@]}" \
    > "$OUT/${mode}.pcm" 2> "$OUT/${mode}.log"
  rc=$?
  set -e
  finish=$(date +%s%N)
  bytes=$(stat -c %s "$OUT/${mode}.pcm")
  elapsed=$(awk -v a="$start" -v b="$finish" 'BEGIN {printf "%.3f", (b-a)/1000000000}')
  echo "$mode rc=$rc bytes=$bytes duration_wall_s=$elapsed" | tee -a "$OUT/measurements.txt"
  grep -E 'Tuned to|Sampling at|Output at|Oversampling|sharp FIR|Sharp FIR|error|Error' "$OUT/${mode}.log" || true
  if (( bytes < 48000 * 2 )); then echo "WARNING: insufficient PCM for $mode" >&2; fi
  if (( rc != 0 && rc != 124 && rc != 130 )); then echo "WARNING: unexpected exit $rc ($mode)" >&2; fi
done
printf '\nPCM: signed 16-bit little-endian MONO; nominal playback 48 kHz.\n'
printf 'Listen locally after transfer, or ssh host cat file | aplay -q -t raw -f S16_LE -r 48000 -c 1\n'
printf 'Capture logs/PCM kept in: %s\n' "$OUT"
