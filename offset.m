function [ xOffset ] = offset( x,sensitivity )
%normalize Summary of this function goes here
%   Detailed explanation goes here
    if nargin == 1
        sensitivity = 25; %range end for offset
    end
    
    offset = mean(x(1:sensitivity));
    
    xOffset = x - offset;
end