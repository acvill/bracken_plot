# bracken_plot
The [bracken_plot application](https://acvill.shinyapps.io/bracken_plot/) allows for quick and easy visualization of merged Bracken data with stacked bar plots. This repository contains a how-to guide, example files, and the app.R source code. 

## Getting Bracken data

Bracken is a companion program to Kraken that allows for estimation of relative abundance at any taxonomic level. For information regarding installation of Bracken and Kraken, see their GitHub pages:

https://github.com/jenniferlu717/Bracken  
https://github.com/DerrickWood/kraken2

Here is an example script for running Kraken and Bracken on paired-end reads:

    name=sample_A
    kdb=home/refdbs/kraken/Standard_DB
    source /home/miniconda3/bin/activate
    conda activate kraken2

    mkdir -p ${name}
    cd ${name}

    kraken2 \
            --gzip-compressed \
            --paired \
            --report ${name}.report.txt \
            --db $kdb \
            --threads $OMP_NUM_THREADS \
            --output ${name}.out.txt \
            ${name}_R1.fastq.gz ${name}_R2.fastq.gz

    conda activate bracken

    levels=P,C,O,F,G,S,S1
    for level in $(echo $levels | sed "s/,/ /g"); do

        bracken \
                -d $kdb \
                -i ${name}.report.txt \
                -o ${name}.bracken_${level}.txt \
                -r 75 \
                -l ${level}

    done

Once you have Bracken reports for each sample at the desired taxonomic levels, reports can be combined by level using `combine_bracken_outputs.py`:

    source /home/miniconda3/bin/activate
    conda activate bracken

    levels=P,C,O,F,G,S,S1
    for level in $(echo $levels | sed "s/,/ /g"); do

        combine_bracken_outputs.py \
        --files ./*/*.bracken_${level}.txt \
        --names sample_A,sample_B,sample_C \
        --output ./merged_bracken_${level}.txt

    done

Note that [globbing expansion processes files alphabetically](https://serverfault.com/a/122743), so the sample identifiers supplied in the `--names` option need to be in alphabetical order. 

## Using the app
