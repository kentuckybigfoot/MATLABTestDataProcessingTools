function [ fileList, runNumbers ] = getRawsInRange( rangeSpecified, directoryList,  runRanges )
%getRawsInRange Returns filenames and corresponding run numbers of RAW
%files in given range using findRawsInDirectory output.
%   

if isstring(rangeSpecified)
    rangeSpecified = str2double(rangeSpecified);
end

[rows, ~] = find(runRanges(:,2) == rangeSpecified);
fileList = directoryList(rows,:);
runNumbers = runRanges(rows,1);

end

