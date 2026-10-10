#!/bin/bash
# run_all.sh - Run all Phase 2 experiment configurations
# Usage: cd <project_root> && bash scripts/run_all.sh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SIM_DIR="$PROJECT_DIR/simulations"
SRC_DIR="$PROJECT_DIR/src"
RESULTS_DIR="$SIM_DIR/results"
BINARY="$SRC_DIR/mpi_bcast_fattree"

# Check binary exists
if [ ! -f "$BINARY" ]; then
    echo "ERROR: Binary not found at $BINARY"
    echo "Please build first: cd $PROJECT_DIR && make makefiles && make"
    exit 1
fi

# Create results directory
mkdir -p "$RESULTS_DIR"

# List of configurations to run
CONFIGS=(
    "Naive_4"
    "Opt_4"
    "Naive_8"
    "Opt_8"
    "Naive_16"
    "Opt_16"
    "Naive_32"
    "Opt_32"
)

# Optional: add payload variants
CONFIGS+=(
    "Naive_8_256B"
    "Naive_8_4096B"
    "Opt_8_256B"
    "Opt_8_4096B"
)

echo "=========================================="
echo "  MPI_Bcast Fat-Tree Comparison - Phase 2"
echo "=========================================="
echo "Running ${#CONFIGS[@]} configurations..."
echo ""

PASS=0
FAIL=0

for cfg in "${CONFIGS[@]}"; do
    echo -n "Running $cfg ... "
    if (cd "$SIM_DIR" && "$BINARY" -u Cmdenv -c "$cfg" -n "../src;." --result-dir="results/$cfg" > /dev/null 2>&1); then
        echo "OK"
        PASS=$((PASS + 1))
    else
        echo "FAILED"
        FAIL=$((FAIL + 1))
    fi
done

echo ""
echo "=========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "=========================================="
echo "  Output in: $RESULTS_DIR/"
echo "=========================================="
