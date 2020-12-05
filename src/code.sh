#!/bin/bash
# shellcheck disable=SC2154
set -e -x -o pipefail

main() {
    python3 -m pip install --no-cache-dir numpy
    python3 -m pip install --no-cache-dir pysam
    python3 -m pip install --no-cache-dir HTSeq
    dx-download-all-inputs --parallel

    bam=$bam_file_path
    bam_basename=$(basename "$bam" .bam)
    counts=$bam_basename.htseq_counts.txt
    annotated_bam=$bam_basename.counts_annotated.bam
    gtf=$gene_model_path
    if [ "$(file "${gene_model_path}" | grep -c "gzip compressed data")" -eq 1 ]; then
        gzip -dc "${gene_model_path}" > annotation.gtf
        gtf="annotation.gtf"
    elif [ "$(file "${gene_model_path}" | grep -c "bzip2 compressed data")" -eq 1 ]; then
        bzip2 -dc "${gene_model_path}" > annotation.gtf
        gtf="annotation.gtf"
    fi

    out_arg=()
    if [ "$annotate_bam" = "true" ]; then
        out_arg=(-o "$annotated_bam" -p bam)
    fi

    additional_arg=()
    if [ -n "$additional_attr" ]; then
        additional_arg=(--additional-attr="${additional_attr}")
    fi

    htseq-count -f bam -r "${order}" -i "${id_attribute}" -s "${strand}" \
        -t "${feature_type}" -m "${mode}" --nonunique="${nonunique}" \
        --secondary-alignments="${secondary_alignments}" -n "$(nproc)" \
        --supplementary-alignments="${supplementary_alignments}" \
        "${additional_arg[@]}" "${out_arg[@]}" "$bam" "$gtf" \
        > "$counts"

    htseq_counts=$(dx upload "$counts" --brief)
    dx-jobutil-add-output htseq_counts "$htseq_counts" --class=file

    if [ "$annotate_bam" = "true" ]; then
        out_bam=$(dx upload "$annotated_bam" --brief)
        dx-jobutil-add-output annotated_bam "$out_bam"
    fi
}
