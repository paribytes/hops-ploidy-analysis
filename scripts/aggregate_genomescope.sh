#!/bin/bash
# Aggregates GenomeScope2 summary.txt files and calculates midpoints
# Usage: ./aggregate_genomescope_v3.sh <genomescope_out_dir> <output_table.tsv>

GENOMESCOPE_DIR="${1:-/sdm/scratch/priyanshi/ploidy_analysis/genomescope_out}"
OUTPUT="${2:-/sdm/scratch/priyanshi/ploidy_analysis/ploidy_summary_table.tsv}"

echo "Scanning: $GENOMESCOPE_DIR"
echo "Found $(ls -d "$GENOMESCOPE_DIR"/*_p2 2>/dev/null | wc -l) sample directories"
echo ""

# header
echo -e "sample\thom_min\thom_max\thom_mid\thet_min\thet_max\thet_mid\thaploid_len_min_mb\thaploid_len_max_mb\thaploid_len_mid_mb\tmodel_fit_min\tmodel_fit_max\terror_rate\tinferred_ploidy" > "$OUTPUT"

for sample_dir in "$GENOMESCOPE_DIR"/*/; do
    sample=$(basename "$sample_dir")
    # skip trial runs at p3/p4 and keep only primary results
    [[ "$sample" =~ _p[34]$ ]] && continue
    [[ "$sample" =~ _p2$ ]] && sample="${sample%_p2}"
    summary="$sample_dir/summary.txt"

    if [[ ! -f "$summary" ]]; then
        echo "  MISSING: $sample"
        echo -e "${sample}\tMISSING" >> "$OUTPUT"
        continue
    fi

    # extract values - use column numbers to skip the label fields (aa), (ab) etc.
    hom_min=$(grep "Homozygous (aa)" "$summary" | awk '{print $3}' | tr -d '%')
    hom_max=$(grep "Homozygous (aa)" "$summary" | awk '{print $4}' | tr -d '%')

    het_min=$(grep "Heterozygous (ab)" "$summary" | awk '{print $3}' | tr -d '%')
    het_max=$(grep "Heterozygous (ab)" "$summary" | awk '{print $4}' | tr -d '%')

    hap_min=$(grep "Genome Haploid Length" "$summary" | awk '{print $4}' | tr -d ',')
    hap_max=$(grep "Genome Haploid Length" "$summary" | awk '{print $6}' | tr -d ',')

    fit_min=$(grep "Model Fit" "$summary" | awk '{print $3}' | tr -d '%')
    fit_max=$(grep "Model Fit" "$summary" | awk '{print $4}' | tr -d '%')

    err=$(grep "Read Error Rate" "$summary" | awk '{print $4}' | tr -d '%')

    # calculate midpoints
    hom_mid=$(awk "BEGIN {printf \"%.2f\", ($hom_min + $hom_max) / 2}")
    het_mid=$(awk "BEGIN {printf \"%.2f\", ($het_min + $het_max) / 2}")
    hap_min_mb=$(awk "BEGIN {printf \"%.1f\", $hap_min / 1000000}")
    hap_max_mb=$(awk "BEGIN {printf \"%.1f\", $hap_max / 1000000}")
    hap_mid_mb=$(awk "BEGIN {printf \"%.1f\", ($hap_min + $hap_max) / 2000000}")

    # flag samples with suspiciously small genome size for follow-up
    ploidy="diploid"
    if (( $(awk "BEGIN {print (($hap_min + $hap_max) / 2 < 400000000)}") )); then
        ploidy="check_p4"
    fi

    echo -e "${sample}\t${hom_min}\t${hom_max}\t${hom_mid}\t${het_min}\t${het_max}\t${het_mid}\t${hap_min_mb}\t${hap_max_mb}\t${hap_mid_mb}\t${fit_min}\t${fit_max}\t${err}\t${ploidy}" >> "$OUTPUT"
done

echo "Done. Table written to: $OUTPUT"
echo ""
echo "Quick preview (first 5 samples):"
column -t "$OUTPUT" | head -6

echo ""
echo "Samples flagged for follow-up (check_p4):"
grep "check_p4" "$OUTPUT" | awk -F'\t' '{print $1}' 
echo ""
echo "Total samples processed: $(grep -v "^sample" "$OUTPUT" | wc -l)"
echo "Missing samples: $(grep "MISSING" "$OUTPUT" | wc -l)"