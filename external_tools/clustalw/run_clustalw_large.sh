#!/usr/bin/env bash

set -u   

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CSV_PATH="${PROJECT_ROOT}/benchmarks/timings_large.csv"
PFAM_DIR="${PROJECT_ROOT}/data/pfam_large"
FA_DIR="${PROJECT_ROOT}/data/pfam_large_fa"

mkdir -p "${PROJECT_ROOT}/benchmarks" "${FA_DIR}"

# Ensure CSV header
if [ ! -f "${CSV_PATH}" ]; then
  echo "dataset,n_seq,tool,real_ms" > "${CSV_PATH}"
fi

# Decide ClustalW binary
if command -v clustalw2 >/dev/null 2>&1; then
  CLUSTAL_CMD="clustalw2"
elif command -v clustalw >/dev/null 2>&1; then
  CLUSTAL_CMD="clustalw"
else
  echo "❌ Error: clustalw/clustalw2 not found in PATH." >&2
  exit 1
fi

############################################
# BATCH MODE — no args: use *.alignment.seed
############################################
if [ $# -eq 0 ]; then
  echo "Running ClustalW in BATCH MODE over pfam_large (*.alignment.seed)…"

  for stk in "${PFAM_DIR}"/*.alignment.seed; do
    [ -e "$stk" ] || continue   # skip if no matches

    dataset=$(basename "$stk" .alignment.seed)
    fasta="${FA_DIR}/${dataset}.aln.fa" 

    # Convert Stockholm -> FASTA
    # Lines that are not comments (#) or end markers (//):
    # first field = sequence ID, second = aligned sequence
    awk '!/^#/ && !/^\/\// {print ">" $1 "\n" $2}' "$stk" > "$fasta"

    # Count sequences in FASTA
    nseq=$(grep -c "^>" "$fasta")

    echo " → Running ClustalW on $dataset (n_seq=$nseq)"

    if /usr/bin/time -p "${CLUSTAL_CMD}" -INFILE="$fasta" -TREE > /dev/null 2> /tmp/clustalw_time.$$; then
      REAL=$(awk "/^real/ {print \$2}" /tmp/clustalw_time.$$ || echo "0")
      MS=$(awk -v sec="$REAL" 'BEGIN {printf "%d", sec * 1000}')
      echo "${dataset},${nseq},clustalw,${MS}" >> "${CSV_PATH}"
    else
      echo "${dataset},${nseq},clustalw,ERROR" >> "${CSV_PATH}"
      echo "   ⚠️ ClustalW failed on $dataset" >&2
    fi

    rm -f /tmp/clustalw_time.$$
  done

  echo "Batch complete. Results in ${CSV_PATH}"
  exit 0
fi

if [ $# -ne 3 ]; then
  echo "Usage: $0 <alignment_fasta> <dataset_name> <n_seq>" >&2
  exit 1
fi

ALIGN="$1"
DATASET="$2"
NSEQ="$3"

# Single run
/usr/bin/time -p "${CLUSTAL_CMD}" -INFILE="${ALIGN}" -TREE > /dev/null 2> /tmp/clustalw_time.$$

REAL=$(awk '/^real/ {print $2}' /tmp/clustalw_time.$$ || echo "0")
rm -f /tmp/clustalw_time.$$
MS=$(awk -v sec="$REAL" 'BEGIN {printf "%d", sec * 1000}')

echo "${DATASET},${NSEQ},clustalw,${MS}" >> "${CSV_PATH}"

echo "Recorded ClustalW runtime: dataset=${DATASET}, n_seq=${NSEQ}, real_ms=${MS}"
