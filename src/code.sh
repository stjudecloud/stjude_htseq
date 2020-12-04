#!/bin/bash
set -e -x -o pipefail

main () {
    sudo apt-get install liblzma-dev -y
    pip install pysam
    pip install HTSeq

    dx-download-all-inputs --parallel 
    
    bam=$bam_file_path
    bamname=$(basename $bam)
    out=$bamname.htseq_counts.txt
    gtf=$gene_model_path
    if [ $(file ${gene_model_path} | grep -c "gzip compressed data") -eq 1 ]
    then
        gzip -dc ${gene_model_path} > annotation.gtf
        gtf="annotation.gtf"
    elif [ $(file ${gene_model_path} | grep -c "bzip2 compressed data") -eq 1 ]
    then
        bzip2 -dc ${gene_model_path} > annotation.gtf
        gtf="annotation.gtf"
    fi

    out_arg=
    if [ ! -z $samout ]
    then
        out_arg="-o $samout"
    fi
    
    additional_arg=
    if [ ! -z $additional_attr ]
    then
        additional_arg="--additional-attr=${additional_attr}"
    fi

    htseq-count -f bam -r ${order} -i ${id_attribute} -s ${strand} -t ${feature_type} -m ${mode} --nonunique=${nonunique} --secondary-alignments=${secondary_alignments} --supplementary-alignments=${supplementary_alignments} $additional_arg $out_arg $bam $gtf > $out

    htseq_counts=$(dx upload "$out" --brief )
    dx-jobutil-add-output htseq_counts "$htseq_counts" --class=file
    
}
