#!/usr/bin/env bash
# Run BioNJ on all small Pfam distance matrices and record timings in timings.csv
# Matches the style of the ClustalW and QuickTree timing scripts.

set -u   # no -e so one failure doesn't kill the whole batch

########################################
# Paths
########################################

# Folder that contains this script: project/external_tools/bionj
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root: go two levels up from SCRIPT_DIR
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Always run from project root for consistent relative paths
cd "$PROJECT_ROOT"

BIONJ_BIN="$SCRIPT_DIR/bionj"
DIST_DIR="$PROJECT_ROOT/data/dist_matrices_small"
TREE_DIR="$PROJECT_ROOT/results/bionj_small"
CSV_PATH="$PROJECT_ROOT/benchmarks/timings_small.csv"

mkdir -p "$TREE_DIR" "$PROJECT_ROOT/benchmarks"

########################################
# Ensure CSV header
########################################
if [ ! -f "$CSV_PATH" ]; then
  echo "dataset,n_seq,tool,real_ms" > "$CSV_PATH"
fi

########################################
# Sanity checks
########################################

if [ ! -x "$BIONJ_BIN" ]; then
  echo "❌ Error: BioNJ binary not found or not executable at $BIONJ_BIN" >&2
  exit 1
fi

shopt -s nullglob
DISTS=( "$DIST_DIR"/*.dist )
if [ ${#DISTS[@]} -eq 0 ]; then
  echo "❌ No .dist files found in $DIST_DIR" >&2
  exit 1
fi

########################################
# Main loop
########################################

echo "Running BioNJ in BATCH MODE over dist_matrices_small (*.dist)…"

for dist in "${DISTS[@]}"; do
  [ -e "$dist" ] || continue

  DATASET=$(basename "$dist" .dist)
  # n_seq = first number in PHYLIP distance file
  NSEQ=$(awk 'NR==1 {print $1}' "$dist")

  echo " → Running BioNJ on ${DATASET} (n_seq=${NSEQ})"

  # BioNJ is interactive ("Enter input file :"), so we feed:
  #   1) input distance-matrix path
  #   2) output tree path
  #   3) 'N' (for "no rooting", if prompted)
  #
  # We wrap it in sh -c so we can pass those as "$1", "$2", "$3"
  # and time the whole thing with /usr/bin/time -p.
  /usr/bin/time -p \
    sh -c 'printf "%s\n%s\nN\n" "$1" "$2" | "$3"' \
    _ "$dist" "$TREE_DIR/${DATASET}.bionj.nwk" "$BIONJ_BIN" \
    2> /tmp/bionj_time.$$

  REAL=$(awk '/^real/ {print $2}' /tmp/bionj_time.$$ || echo "0")
  rm -f /tmp/bionj_time.$$

  # Convert seconds → integer milliseconds
  MS=$(awk -v sec="$REAL" 'BEGIN {printf "%d", sec * 1000}')

  echo "${DATASET},${NSEQ},bionj,${MS}" >> "$CSV_PATH"
done

echo "BioNJ batch complete. Results saved to ${CSV_PATH}"
