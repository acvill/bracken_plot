# bracken_plot
The [bracken_plot application](https://acvill.shinyapps.io/bracken_plot/) allows for quick and easy visualization of merged Bracken data with stacked bar plots. This repository contains a how-to guide, example files, and the app.R source code. 

## Getting Bracken data

Bracken is a companion program to Kraken that allows for estimation of relative abundance at any taxonomic level. For information regarding installation of Bracken and Kraken, see their GitHub pages:

https://github.com/jenniferlu717/Bracken  
https://github.com/DerrickWood/kraken2

    DB=HumGut_DB

    WRK=/workdir/users/acv46/ben_May2021/vamb/small_NN
    export OMP_NUM_THREADS=10
    IN=$WRK/bins_merged_samples
    kdb=/workdir/refdbs/kraken/${DB}
    kout=$WRK/kraken2/${DB}

    source /home/acv46/miniconda3/bin/activate
    conda activate kraken2

    DESIGN_FILE=$WRK/samples.txt
            DESIGN=$(sed -n "${SGE_TASK_ID}p" $DESIGN_FILE)
            NAME=`basename ${DESIGN}`

    mkdir -p $kout/${NAME}
    cd $kout/${NAME}

    echo "${NAME} -- starting kraken2"

    kraken2 \
            --report ${NAME}.report.txt \
            --db $kdb \
            --threads $OMP_NUM_THREADS \
            --output ${NAME}.out.txt \
            $IN/${NAME}_merged.fna

    echo "${NAME} -- finished kraken2"

    conda activate bracken

    echo "${NAME} -- starting bracken"

    levels=P,C,O,F,G,S,S1

    for level in $(echo $levels | sed "s/,/ /g"); do

            echo "--> ${NAME} -- running bracken for taxonomic level ${level}"

            bracken \
                    -d $kdb \
                    -i ${NAME}.report.txt \
                    -o ${NAME}.bracken_${level}.txt \
                    -r 75 \
                    -l ${level}

    done

    conda deactivate

    echo "${NAME} -- finished bracken, script done"

## Using the app
