function [ xnorm ] = normfxn( x,style )
%normalize Summary of this function goes here
%   Detailed explanation goes here
    if nargin == 1
        style = 1; %Normalization between 0 and 1
    end
    
    xMax = max(x(:));
    xMin = min(x(:));
    
    if style == 1
        xnorm = ((x - xMin)/(xMax - xMin));
    elseif style == 2
        xnorm = 2*mat2gray(x)-1;
    else
        disp('Error. Invalid entries.');
    end
end

