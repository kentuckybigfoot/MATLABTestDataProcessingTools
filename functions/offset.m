function [ xOffset ] = offset( x,sensitivity,force)
%normalize Summary of this function goes here
%   Detailed explanation goes here
    
    switch nargin
        case 1
            offset = mean(x(1:25));
        case 2
            offset = mean(x(1:sensitivity));
        case 3
            offset = force;
        otherwise
            error('Danger, Will Robinson');
    end
    
    xOffset = x - offset;
end