#!/usr/bin/env bash
set -euo pipefail

###################################
# ALWAYS WORK RELATIVE TO THIS FILE
###################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

###################################
# CONFIG – PROJECT-SPECIFIC PATHS #
###################################

# Pfam SEED alignments directory (SMALL dataset)
SEED_DIR="pfam_large"

# File extension pattern of your Pfam files
# Since files are like PF00271.alignment.seed, the extension is "alignment.seed"
SEED_EXT="alignment.seed"

# Output directory for PHYLIP distance matrices
OUT_DIR="dist_matrices_large"

# Temporary working directory for protdist
TMP_DIR=".tmp_protdist"

# Distance program to use (protdist = protein)
DIST_PROG="protdist"

###################################
# SETUP DIRECTORIES               #
###################################

mkdir -p "$OUT_DIR" "$TMP_DIR"

echo "=== Building distance matrices for SMALL Pfam families ==="
echo " Script dir  : $SCRIPT_DIR"
echo " Input seeds : $SEED_DIR"
echo " Extension   : *.$SEED_EXT"
echo " Output      : $OUT_DIR"
echo " Temp dir    : $TMP_DIR"
echo "=========================================================="
echo

###################################
# MAIN LOOP                       #
###################################

shopt -s nullglob
files=( "$SEED_DIR"/*."$SEED_EXT" )

if [ ${#files[@]} -eq 0 ]; then
    echo "ERROR: No *.$SEED_EXT files found in $SCRIPT_DIR/$SEED_DIR"
    exit 1
fi

for aln in "${files[@]}"; do
    base=$(basename "$aln")              # PF00271.alignment.seed
    fam="${base%%.*}"                    # extract PF00271 before first dot

    echo ">>> Processing $fam"

    # Make sure old outfile from previous iteration is gone
    rm -f "$TMP_DIR/outfile"

    # 1) Convert alignment into PHYLIP format for protdist
    esl-reformat phylip "$aln" > "$TMP_DIR/infile"

    # 2) Run protdist – reads 'infile', writes 'outfile'
    (
        cd "$TMP_DIR"
        "$DIST_PROG" <<EOF
Y
EOF
    )

    # 3) Move result to dist_matrices_small/ with nice name
    mv "$TMP_DIR/outfile" "$OUT_DIR/${fam}.dist"

    echo "    -> Created $OUT_DIR/${fam}.dist"
    echo
done

echo "=== DONE! All LARGE Pfam distance matrices are in $OUT_DIR ==="
