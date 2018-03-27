function [ estLength, estRanges ] = estimateVariableLengths( p )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

    if ~isobject(p)
        error('Input must be object')
    end

    estLength = 0;
    estRanges = zeros(length(p), 2);

    for r = 1:length(p)
        initLength = p(r).scanlistblocks * p(r).NumberOfDataFramesInFile;
        initDecLength = ceil(initLength/p(r).DecimateBy);

        if p(r).DecimateBy == 0
            initLengthUsed = initLength;
        else
            initLengthUsed = initDecLength;
        end

        estLength = estLength + initLengthUsed;

        if r == 1
            estRanges(1,1) = 1;
            estRanges(1,2) = initLengthUsed;
        else
            estRanges(r,1) = estRanges(r-1,2) + 1;
            estRanges(r,2) = estRanges(r-1,2) + initLengthUsed;
        end
    end
end