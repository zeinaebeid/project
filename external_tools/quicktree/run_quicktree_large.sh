#!/usr/bin/env bash
# Run QuickTree on one alignment OR on all pfam_small alignments if no args given.
#
# Usage:
#   ./external_tools/quicktree/run_quicktree.sh <alignment_file> <dataset_name> <n_seq>
# OR batch mode:
#   ./external_tools/quicktree/run_quicktree.sh
#

set -u  # NO -e, so batch mode won't exit on first failure

# Determine directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CSV_PATH="${PROJECT_ROOT}/benchmarks/timings_large.csv"

mkdir -p "${PROJECT_ROOT}/benchmarks"

# Ensure CSV has header
if [ ! -f "${CSV_PATH}" ]; then
  echo "dataset,n_seq,tool,real_ms" > "${CSV_PATH}"
fi

############################################
# BATCH MODE — NO ARGS
############################################
if [ $# -eq 0 ]; then
  echo "Running QuickTree in BATCH MODE over pfam_large directory..."

  for f in "${PROJECT_ROOT}"/data/pfam_large/*.alignment.seed; do
    dataset=$(basename "$f" .alignment.seed)
    nseq=$(grep -v '^#' "$f" | grep -v '^//' | wc -l | awk '{print $1}')

    echo " → Running QuickTree on $dataset (n_seq=$nseq)"

    # Run QuickTree and capture timing
    if /usr/bin/time -p quicktree -in a "$f" > /dev/null 2> /tmp/quicktree_time.$$; then
        REAL=$(awk '/^real/ {print $2}' /tmp/quicktree_time.$$ || echo "0")
        # Convert seconds → milliseconds
        MS=$(awk -v sec="$REAL" 'BEGIN {printf "%d", sec * 1000}')
        echo "${dataset},${nseq},quicktree,${MS}" >> "${CSV_PATH}"
    else
        echo "${dataset},${nseq},quicktree,ERROR" >> "${CSV_PATH}"
        echo "   ⚠️ QuickTree failed on $dataset, logged as ERROR"
    fi

    rm -f /tmp/quicktree_time.$$
  done

  echo "Batch complete. Results saved to ${CSV_PATH}"
  exit 0
fi

############################################
# SINGLE-FILE MODE (original behavior)
############################################
if [ $# -ne 3 ]; then
  echo "Usage: $0 <alignment_file> <dataset_name> <n_seq>" >&2
  exit 1
fi

ALIGN="$1"
DATASET="$2"
NSEQ="$3"

# Run QuickTree and capture timing
/usr/bin/time -p quicktree -in a "${ALIGN}" > /dev/null 2> /tmp/quicktree_time.$$
REAL=$(awk '/^real/ {print $2}' /tmp/quicktree_time.$$ || echo "0")
rm -f /tmp/quicktree_time.$$

# Convert to milliseconds
MS=$(awk -v sec="$REAL" 'BEGIN {printf "%d", sec * 1000}')

echo "${DATASET},${NSEQ},quicktree,${MS}" >> "${CSV_PATH}"

echo "Recorded QuickTree runtime: dataset=${DATASET}, n_seq=${NSEQ}, real_ms=${MS}"
