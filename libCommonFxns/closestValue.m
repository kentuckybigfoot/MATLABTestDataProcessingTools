function [ index, foundValue ] = closestValue( value, inputArray )
%closestValue Summary of this function goes here
%   Detailed explanation goes here

tmp = abs(inputArray-value);

[~, index] = min(tmp);

foundValue = inputArray(index);

end

