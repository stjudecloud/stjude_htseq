#!/bin/bash
set -e -x -o pipefail

main() {
    
    sudo apt-get install liblzma-dev -y
    pip install pysam
    pip install HTSeq

    dx-download-all-inputs --parallel 
    
    bam=$bam_file_path
    bamname=$(basename $bam)
    out=$bamname.htseq_counts.txt
    gtf=$gene_model_path
    
    htseq-count -f bam -r pos -i gene_name -s reverse $bam $gtf > $out

    htseq_counts=$(dx upload "$out" --brief )
    dx-jobutil-add-output htseq_counts "$htseq_counts" --class=file
    
}
