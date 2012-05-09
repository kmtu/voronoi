volumeDir="volume-data"
numBins=500
binvolumeDir="binvolume-data/bin${numBins}"

function getbin()
{
    binning="$HOME/github/binning/out/binning"
    pressure=$1
    begin=$2
    end=$3
    min=0
    max=50000
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
    errbars="2000 5000 10000 15000 20000 25000 30000 35000 40000 45000"
    ./analyze.m ${binvolumeDir}/binvolume-${pressure}_1ns- $begin $end $errbars
    mv ${stdBaseFilename}$begin-$end $outFilename
}

runGetbin="false"

pressure="001atm"
[ "$runGetbin" == "true" ] && getbin $pressure 1 10
b=1; e=10;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns_bin${numBins}-${b}_${e}"

pressure="200atm"
[ "$runGetbin" == "true" ] && getbin $pressure 1 25
b=16; e=25;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns_bin${numBins}-${b}_${e}"

pressure="400atm"
[ "$runGetbin" == "true" ] && getbin $pressure 1 25
b=16; e=25;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns_bin${numBins}-${b}_${e}"

pressure="001a200"
[ "$runGetbin" == "true" ] && getbin $pressure 1 16
b=7; e=16;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns_bin${numBins}-${b}_${e}"

pressure="001a400"
[ "$runGetbin" == "true" ] && getbin $pressure 1 20
b=11; e=20;
getstd $pressure $b $e "binvolume_std-${pressure}_1ns_bin${numBins}-${b}_${e}"

