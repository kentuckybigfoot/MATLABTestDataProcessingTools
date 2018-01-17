function [ directoryList,  runRanges] = findRawsInDirectory( directory )
%findRawsInDirectory Find raws in specified directory, return list and run
%ranges.
%   Example:
%    [directoryList, runRanges] = findRawsInDirectory('C:\Users\Christopher\Desktop\Random Raw\')
%    Returns:
%
%    directoryList =
%       48×37 char array
%      'fs testing -st4 - 07-20-16Run2253.raw'
%      'fs testing -st4 - 07-20-16Run2254.raw'
%
%    runRanges =
%       2x2 double
%       2253        2000
%       2254        2000

    directoryList = ls(fullfile(directory,'*.raw'));

    countFilesFound = length(directoryList);

    if countFilesFound == 0
        error('No RAW files found in specified folder');
    end

    runRanges = zeros(countFilesFound,2);

    for r = 1:countFilesFound
        splitFileName = strsplit(directoryList(r,:),{'Run','.raw'},'CollapseDelimiters',true);
        runNumber = splitFileName{1,2};
        roundParameter = -1*(length(runNumber)-1);
        runRanges(r,1) = str2double(runNumber);
        runRanges(r,2) = round(runRanges(r,1),roundParameter);
    end
end

