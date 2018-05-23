function [ minMaxRanges, LVDTMinMax ] = getActuatorRanges( wp, increment )
%getActuatorRanges Returns the indexes of minima and maxima of MTS LVDT data record
%   Returns the indexes of minima and maxima of MTS LVDT data record. Default increment used to determine minima/maxima is
%   0.1 inches since displacement in cyclic tests typically incremented by 1/8 inch.
%   Ouputs minMaxRanges(:,1:5) where:
%       minMaxRanges(:,1) -> Beginning range of minima/maxima
%       minMaxRanges(:,2) -> Ending range of minima/maxima
%       minMaxRanges(:,5) -> minima/maxima indication (1 or 0, respectively)
%       minMaxRanges(:,3) -> Beginning range of minima/maxima using actuator at 0 in. as reference
%       minMaxRanges(:,4) -> Ending range of minima/maxima using actuator at 0 in. as reference
%
%	Copyright 2017-2018 Christopher L. Kerner.
%

    if nargin == 1
        % Get local minima/maxima of the recorded MTS actuator LVDT. Increment of 0.1 inch used since we know that the
        % typical increment of displacement in cyclic tests is 1/8th inch.
        increment = 0.1;
    end

    % Use PEAKDET to find minima/maxima
    [maxtab, mintab] = peakdet(wp, increment);

    % Label maxima as 1 and minima as 0
    maxtab(:,3) = 1;
    mintab(:,3) = 0;

    % Concatenate maxima and minima 
    tempLVDTMinMax = [maxtab; mintab];

    % Asscending sort by index of minima/maxima of concatenated minima/maxima
    % LVDTMinMax    -> Sorted indices of minima/maxima
    % idxLVDTMinMax -> Original index of minima/maxima in tempLVDTMinMax. i. e. tempLVDTMinMax(idxLVDTMinMax) = LVDTMinMax
    [LVDTMinMax, idxLVDTMinMax] = sort(tempLVDTMinMax(:,1));

    % Concatenate index of minima/maxima, the MTS LVDT extension measure at that index (inches), and whether row represents a
    % maxima or minima (1 and 0, respectively)
    LVDTMinMax = [LVDTMinMax tempLVDTMinMax(idxLVDTMinMax,2) tempLVDTMinMax(idxLVDTMinMax,3)];

    % Get size of sirted minima/maxima, and pre-allocate record for further processing
    sizeLVDTMinMax = size(LVDTMinMax,1);
    minMaxRanges = zeros(sizeLVDTMinMax, 5);

    % Remap LVDTMinMax into minMaxRanges([1:2,5],:) where
    % minMaxRanges(:,1) -> Beginning range of minima/maxima
    % minMaxRanges(:,2) -> Ending range of minima/maxima
    % minMaxRanges(:,5) -> minima/maxima indication (1 or 0, respectively)
    minMaxRanges(1,1) = 1;
    minMaxRanges(1,2) = LVDTMinMax(1,1);

    for r = 2:sizeLVDTMinMax
        minMaxRanges(r,1:2) = [LVDTMinMax(r-1,1), LVDTMinMax(r,1)];
        minMaxRanges(r,5) = LVDTMinMax(r,3);
    end

    % Present minima/maxima ranges based on where MTS LVDT reads actuator extension is 0 inches. Record as:
    % minMaxRanges(:,3) -> Beginning range of minima/maxima using actuator at 0 in. as reference
    % minMaxRanges(:,4) -> Ending range of minima/maxima using actuator at 0 in. as reference
    minMaxRanges(1,3) = knnsearch(wp(minMaxRanges(1,1):minMaxRanges(1,2),1),0);

    for r = 2:sizeLVDTMinMax
        rangeFromZero = minMaxRanges(r,1) + knnsearch(wp(minMaxRanges(r,1):minMaxRanges(r,2),1),0);
        minMaxRanges(r,3) = rangeFromZero;
        minMaxRanges(r-1,4) = rangeFromZero;
    end

    % Include final range as the length of the WP record
    minMaxRanges(sizeLVDTMinMax,4) = size(wp,1);

end