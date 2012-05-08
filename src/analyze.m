#!/usr/bin/octave -q

clear all
format long

baseFileName = argv(){1}
imin = str2num(argv(){2})
imax = str2num(argv(){3})
indexes = [imin:imax]

if (nargin() > 3)
    opt = argv(){4} #even or odd
endif

for i = indexes
    fileName = strcat(baseFileName, num2str(i, "%02d"))
    data = load(fileName)
    if (i == 1)
        volume = data(:,1)
        distribution = data(:,2)
    else
        if (volume != data(:,1))
            error("The volume indexes of file %s is different", fileName)
            exit(1)
        endif
        distribution(:, end+1) = data(:,2)
    endif
endfor

distribution_mean = mean(distribution, 2);
distribution_std = std(distribution, 0, 2);

if (nargin() > 3)
    #even
    if (strcmp(opt, "even"))
        distribution_std(1:2:end) = 0
    endif

    #odd
    if (strcmp(opt, "odd"))
        distribution_std(2:2:end) = 0
    endif
endif

out = [volume, distribution_mean, distribution_std]
outFileName = strcat("volume_std_", num2str(imin), "-", num2str(imax))
save(outFileName,"out")

