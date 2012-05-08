volumeDir="volume-data"
binvolumeDir="binvolume-data"

function getbin()
{
    binning="$HOME/github/binning/out/binning"
    pressure=$1
    begin=$2
    end=$3
    numBins=1000
    min=0
    max=52000
    for ((i=$begin; i<=$end; i=i+1))
    do 
        ii=$(printf "%02d" $i)
        $binning -n $numBins -r $min $max -f ${volumeDir}/volume-${pressure}_1ns-$ii \
                 -o ${binvolumeDir}/binvolume-${pressure}_1ns-${ii} --normalize
    done
}

function getstd()
{
    stdBaseFilename="volume_std_"
    pressure=$1
    begin=$2
    end=$3
    outFilename=$4
    ./analyze.m ${binvolumeDir}/binvolume-${pressure}_1ns- $begin $end
    mv ${stdBaseFilename}$begin-$end $outFilename
}

pressure="001atm"
#getbin $pressure 1 9
b=2; e=9;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns-${b}_${e}"

pressure="200atm"
##getbin $pressure 1 25
b=16; e=25;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns-${b}_${e}"

pressure="400atm"
#getbin $pressure 1 25
b=16; e=25;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns-${b}_${e}"

pressure="001a200"
#getbin $pressure 1 16
b=7; e=16;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns-${b}_${e}"

pressure="001a400"
#getbin $pressure 1 20
b=11; e=20;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns-${b}_${e}"

