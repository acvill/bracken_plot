# bracken_plot

![Example output of bracken_plot app](https://user-images.githubusercontent.com/22378512/131150573-25963923-f5e1-4000-ae94-8575353fac6c.png)

The [bracken_plot application](https://acvill.shinyapps.io/bracken_plot/) allows for quick and easy visualization of merged Bracken data with stacked bar plots. This repository contains a how-to guide, example files, and the app.R source code. 

## Getting Bracken data

Bracken is a companion program to Kraken that allows for estimation of relative abundance at any taxonomic level. For information regarding installation of Bracken and Kraken, see their GitHub pages:

https://github.com/jenniferlu717/Bracken  
https://github.com/DerrickWood/kraken2

Here is an example script for running Kraken and Bracken on paired-end reads:

    name=sample_A
    kdb=/home/refdbs/kraken/Standard_DB
    fq=/workdir/fastq
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
            ${fq}/${name}_R1.fastq.gz ${fq}/${name}_R2.fastq.gz

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

Note that [globbing expansion processes files alphanumerically](https://serverfault.com/a/122743), so the sample identifiers supplied in the `--names` option need to be in order or the columns of the merged file will be mislabeled. 

## Using the app

Upload your merged Bracken file and click "Create Plot". To plot an example, you can download Bracken output files from [this repository](https://github.com/acvill/bracken_plot/tree/main/example_data_bracken). The app will automatically detect the taxonomic level and print a stacked bar plot showing the relative abundance of each taxa. Often, there are many taxa with near-zero abundances, and plotting all taxa results in ambiguous labeling. If this is the case, use the "Maximum number of taxa to plot" field to subsample the dataset. Subsampling will reduce the number of taxa plotted to the *n* taxa with the greatest median relative abundances across samples. The relative abundances of all taxa not in the subset are summed and plotted as "other". 

Custom color palettes can be added as a string of comma-separated hexadecimal values without spaces or `#` characters. Colors are recycled in cases where the number of taxa exceeds the number of colors in a palette. If subsampling taxa, make sure that custom palettes do not contain the color used for the "other" label (gray `808080` by default). Some example palettes:

#### Default Palette
    5c2751,ef798a,f7a9a8,00798c,6457a6,9dacff,76e5fc,a30000,ff7700,f5b841
![Default palette](https://user-images.githubusercontent.com/22378512/131156615-e78381f8-7f7a-45c7-adee-ddf1c1d7521f.png)

#### Alternate Palette 1
    05a8aa,b8d5b8,d7b49e,dc602e,bc412b,791e94,2f4858,293f14,386c0b,550527
![Alternate palette 1](https://user-images.githubusercontent.com/22378512/131156667-1ab5952c-34dc-4f17-86d4-6d7d2d51f9c6.png)

#### Alternate Palette 2
    99d5c9,6c969d,645e9d,392b58,2d0320,f9c784,fcaf58,ff8c42,cc2936,ebbab9
![Alternate Palette 2](https://user-images.githubusercontent.com/22378512/131156718-827af008-2466-4cba-afb2-fbf71dd33a0c.png)

[Coolors.co](https://coolors.co/generate) is great for making your own palettes. 
