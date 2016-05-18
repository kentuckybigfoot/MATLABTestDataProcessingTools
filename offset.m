function [ xOffset ] = offset( x,sensitivity,force)
%normalize Summary of this function goes here
%   Detailed explanation goes here
    if nargin == 1
        sensitivity = 25; %range end for offset
        force = [];
    end
    
    if isempty(force)
        offset = mean(x(1:sensitivity));
    else
        offset = force;
    end
    
    xOffset = x - offset;
end