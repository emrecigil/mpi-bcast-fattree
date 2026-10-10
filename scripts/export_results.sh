#!/bin/bash
# export_results.sh - Extract scalar results from .sca files into CSV
# Usage: cd <project_root> && bash scripts/export_results.sh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SIM_DIR="$PROJECT_DIR/simulations"
RESULTS_BASE="$SIM_DIR/results"
OUTPUT_FILE="$PROJECT_DIR/results_summary.csv"

echo "Exporting results to $OUTPUT_FILE ..."

# CSV header
echo "config,module,scalar,value" > "$OUTPUT_FILE"

# Process each config's results directory
for cfg_dir in "$RESULTS_BASE"/*/; do
    if [ ! -d "$cfg_dir" ]; then
        continue
    fi
    cfg_name=$(basename "$cfg_dir")

    # Find .sca files
    for sca_file in "$cfg_dir"/*.sca; do
        if [ ! -f "$sca_file" ]; then
            continue
        fi

        # Parse scalar lines from .sca file
        # Format: scalar <module> <name> <value>
        grep "^scalar " "$sca_file" | while read -r _ module name value; do
            echo "$cfg_name,$module,$name,$value" >> "$OUTPUT_FILE"
        done
    done
done

echo "Done. Results written to: $OUTPUT_FILE"
echo ""

# Print summary table
echo "=========================================="
echo "  Quick Summary"
echo "=========================================="

for cfg_name in Naive_4 Opt_4 Naive_8 Opt_8 Naive_16 Opt_16 Naive_32 Opt_32; do
    # Find the max receiveTime for this config
    max_time=$(grep "^${cfg_name}," "$OUTPUT_FILE" | grep ",receiveTime," | awk -F',' '{print $4}' | sort -g | tail -1)
    # Count total messages sent
    total_sent=$(grep "^${cfg_name}," "$OUTPUT_FILE" | grep ",messagesSent," | awk -F',' '{sum += $4} END {print sum+0}')
    # Root transmissions
    root_tx=$(grep "^${cfg_name}," "$OUTPUT_FILE" | grep ",rootTransmissions," | awk -F',' '{print $4}' | head -1)

    if [ -n "$max_time" ]; then
        printf "%-12s  maxReceiveTime=%-12s  totalMsgSent=%-6s  rootTx=%-4s\n" \
            "$cfg_name" "$max_time" "$total_sent" "${root_tx:-N/A}"
    else
        printf "%-12s  (no results)\n" "$cfg_name"
    fi
done

echo ""
echo "Full CSV: $OUTPUT_FILE"
