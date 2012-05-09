#!/usr/bin/octave -q

clear all
format long


if (nargin() < 3)
    error("Usage: $analyze.m baseFileName imin imax [errbar pos...]")
endif

baseFileName = argv(){1}
imin = str2num(argv(){2})
imax = str2num(argv(){3})
indexes = [imin:imax]

if (nargin() > 3)
    errbarVolumes_cell = argv()(4:end)
    for i = [1:length(errbarVolumes_cell)]
        errbarVolumes(i) = str2num(errbarVolumes_cell{i})
    endfor
endif

for i = indexes
    fileName = strcat(baseFileName, num2str(i, "%02d"))
    data = load(fileName)
    if (!exist("volume"))
        volume = data(:,1)
        distribution = data(:,2)
    else
        if (volume != data(:,1))
            error("The volume indexes of file %s is different", fileName)
        endif
        distribution(:, end+1) = data(:,2)
    endif
endfor

distribution_mean = mean(distribution, 2);
distribution_std = std(distribution, 0, 2);

if (nargin() > 3)
    for i = [1:length(errbarVolumes)]
        #find the closest volume, both its value and index
        [m, mi] = min(abs(errbarVolumes(i) - volume))
        errbarIndexes(i) = mi
    endfor

    for i = [1:length(volume)]
        if (all(errbarIndexes != i))
            distribution_std(i) = 0
        endif
    endfor
endif

out = [volume, distribution_mean, distribution_std]
outFileName = strcat("volume_std_", num2str(imin), "-", num2str(imax))
save(outFileName,"out")

