#!/usr/bin/env bash
# Run PHYLIP NEIGHBOR on one distance matrix OR on all matrices in batch mode.
#
# Single mode:
#   ./external_tools/phylip/run_phylip.sh <dist_matrix> <dataset_name> <n_seq>
#
# Batch mode (no args; uses data/dist_matrices_small/*.dist):
#   ./external_tools/phylip/run_phylip.sh
#

set -u  # no -e so a failure on one dataset doesn't kill the whole batch

########################################
# Paths
########################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CSV_PATH="${PROJECT_ROOT}/benchmarks/timings_small.csv"

# Distance matrices (same ones used by BioNJ)
DIST_DIR="${PROJECT_ROOT}/data/dist_matrices_small"

# Optional: where to stash PHYLIP trees if you want to keep them
TREE_DIR="${PROJECT_ROOT}/results/phylip_small"

mkdir -p "${PROJECT_ROOT}/benchmarks" "${TREE_DIR}"

########################################
# Ensure CSV header exists
########################################

if [ ! -f "${CSV_PATH}" ]; then
  echo "dataset,n_seq,tool,real_ms" > "${CSV_PATH}"
fi

########################################
# Detect neighbor binary
########################################

if command -v neighbor >/dev/null 2>&1; then
  NEIGHBOR_CMD="neighbor"
else
  echo "❌ Error: PHYLIP 'neighbor' program not found in PATH." >&2
  echo "    Install PHYLIP (or EMBOSS with 'neighbor') and try again." >&2
  exit 1
fi

############################################
# Helper: run neighbor on a single matrix
############################################
run_neighbor_on_matrix () {
  local dist_file="$1"
  local dataset="$2"
  local nseq="$3"

  # Work in a temporary directory so infile/outfile/outtree don't collide
  local tmpdir
  tmpdir=$(mktemp -d -t phylip_neighbor_XXXXXX)

  # PHYLIP expects 'infile' by default
  cp "${dist_file}" "${tmpdir}/infile"

  pushd "${tmpdir}" >/dev/null

  # Run neighbor:
  #   - It prints a settings menu and then asks:
  #       "Are these settings correct? (type Y or letter for one to change):"
  #   - We just pipe "Y" to accept defaults and run.
  #
  # /usr/bin/time -p writes timing to stderr; redirect that to neighbor_time.log
  if /usr/bin/time -p bash -c "echo Y | ${NEIGHBOR_CMD}" > /dev/null 2> neighbor_time.log; then
    local REAL
    REAL=$(awk '/^real/ {print $2}' neighbor_time.log || echo "0")
    local MS
    MS=$(awk -v sec="$REAL" 'BEGIN {printf "%d", sec * 1000}')

    echo "${dataset},${nseq},phylip,${MS}" >> "${CSV_PATH}"

    # Optional: keep the tree if you care (PHYLIP writes it to 'outtree')
    if [ -f "outtree" ]; then
      cp outtree "${TREE_DIR}/${dataset}.phylip.nwk"
    fi
  else
    echo "${dataset},${nseq},phylip,ERROR" >> "${CSV_PATH}"
    echo "   ⚠️ PHYLIP neighbor failed on ${dataset}" >&2
  fi

  popd >/dev/null
  rm -rf "${tmpdir}"
}

############################################
# BATCH MODE — no args
############################################
if [ $# -eq 0 ]; then
  echo "Running PHYLIP NEIGHBOR in BATCH MODE over dist_matrices_small (*.dist)…"

  shopt -s nullglob
  for dist in "${DIST_DIR}"/*.dist; do
    [ -e "$dist" ] || continue  # skip if no matches

    dataset=$(basename "$dist" .dist)
    # n_seq = first number on the first line in PHYLIP distance matrix
    nseq=$(head -n 1 "$dist" | awk '{print $1}')

    echo " → Running neighbor on ${dataset} (n_seq=${nseq})"
    run_neighbor_on_matrix "$dist" "$dataset" "$nseq"
  done

  echo "Batch complete. Results saved to ${CSV_PATH}"
  exit 0
fi

############################################
# SINGLE MODE
############################################
if [ $# -ne 3 ]; then
  echo "Usage: $0 <dist_matrix> <dataset_name> <n_seq>" >&2
  exit 1
fi

DIST_FILE="$1"
DATASET="$2"
NSEQ="$3"

run_neighbor_on_matrix "${DIST_FILE}" "${DATASET}" "${NSEQ}"
