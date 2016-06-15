function [ dist ] = DF( x1, x2, y1, y2 )
%DF Distance of a line formula
%   Distance of a line formula. Input X1, X2, Y1, Y2, and out put the
%   distance between those points.

dist = sqrt(((x2-x1).^2)+((y2-y1).^2));

end

