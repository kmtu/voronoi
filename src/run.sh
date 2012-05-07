#i=0 
#pressure="001atm"
#
#for file in $(ls /save/kmtu/POPC/${pressure}/HISTORY.*)
#do 
#    if [ -e $file ]; then 
#        i=$((i+1))
#        ./voronoi $file -o voronoi-${pressure}_1ns-${i}
#    fi
#done

#i=1 
#pressure="200atm"
#hasPrev="false"
#
#for file in $(ls /save/kmtu/POPC/${pressure}/HISTORY.*)
#do 
#    if [ -e "$file" ]; then 
#        if [ $i -lt 16 ] || [ $i -gt 21 ]; then
#            ./voronoi $file -o voronoi-${pressure}_1ns-${i}
#            i=$((i+1))
#        elif [ "$hasPrev" == "true" ]; then
#            ./voronoi $prevFile $file -o voronoi-${pressure}_1ns-${i}
#            i=$((i+1))
#            hasPrev=false
#        else
#            prevFile="$file"
#            hasPrev="true"
#        fi
#    fi
#done

#i=1 
#pressure="400atm"
#hasPrev="false"
#
#for file in $(ls /save/kmtu/POPC/${pressure}/HISTORY.*)
#do 
#    if [ -e "$file" ]; then 
#        if [ $i -lt 16 ] || [ $i -gt 20 ]; then
#            ./voronoi $file -o voronoi-${pressure}_1ns-${i}
#            i=$((i+1))
#        elif [ "$hasPrev" == "true" ]; then
#            ./voronoi $prevFile $file -o voronoi-${pressure}_1ns-${i}
#            i=$((i+1))
#            hasPrev=false
#        else
#            prevFile="$file"
#            hasPrev="true"
#        fi
#    fi
#done

i=1 
pressure="001a200"

for file in $(ls /save/kmtu/POPC/${pressure}/HISTORY.*)
do 
    if [ -e $file ]; then 
        ./voronoi $file -o voronoi-${pressure}_1ns-${i}
        i=$((i+1))
    fi
done

i=1 
pressure="001a400"
hasPrev="false"

for file in $(ls /save/kmtu/POPC/${pressure}/HISTORY.*)
do 
    if [ -e "$file" ]; then 
        if [ $i -lt 16 ] || [ $i -gt 20 ]; then
            ./voronoi $file -o voronoi-${pressure}_1ns-${i}
            i=$((i+1))
        elif [ "$hasPrev" == "true" ]; then
            ./voronoi $prevFile $file -o voronoi-${pressure}_1ns-${i}
            i=$((i+1))
            hasPrev=false
        else
            prevFile="$file"
            hasPrev="true"
        fi
    fi
done

