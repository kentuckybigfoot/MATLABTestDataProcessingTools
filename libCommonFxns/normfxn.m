function [ xNorm ] = normfxn(x,normRange)
%normfxn Normalizes data between 0 and 1 (default) or a specified range.
%   x = data. Can be a column matrix or multi-column matrix.
%   normRange = range of numbers to normalise to. Blank by default which
%   results in [0, 1]. Specify 2x1 or 1x2 matrix with ranges for custom
%   range.
%
%   Example: normfxn(data)
%   Example: normfxn(data, [-1, 1])

    if nargin == 1
        normRange = [0, 1];
    elseif nargin == 2
        if isa(normRange, 'double') && ~isvector(normRange)
            normRange = [0, 1]; %Uneccessary range set, trapping.
        elseif isa(normRange, 'double') && isvector(normRange)
            normRangeLength = length(normRange);
            
            if normRangeLength == 1
                 normRange = [0, 1];
            end
            
            if normRangeLength > 2
                error("Invalid range");
            end
            
            if iscolumn(normRange)
                normRange = normRange';
            end
        end
    end
    
    xMax = max(x(:));
    xMin = min(x(:));
    
    xNorm = (normRange(2) - normRange(1))*((x - xMin)/(xMax - xMin)) + normRange(1);
end