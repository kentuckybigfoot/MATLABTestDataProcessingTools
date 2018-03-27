function varargout = range2range( originalNumber, originalRange, newRange )
%range2range Convert number from an original range to its equivilent value in a new range.
%   x = range2range(originalNumber, originalRange, newRange) takes originalValue from the range originalRange and returns the
%   equivilent value of originalValue in terms of newRange. originalRange and newRange are 1-by-2 row vectors where the first
%   value, (1,1), is smaller than the second value, (1,2).
%
%   [x, rangeOfX] = range2range(originalNumber, originalRange, newRange) provides the same output and functionality as
%   before, but with the addition of providing a 1-by-2 row vector containing the range in which originalNumber (x) is now
%   in terms of.
%
%   Example 1:
%   Take the value 4 from within the range of 0 to 100 and obtain its equivilent value in terms of range 0 to 200:
%       x = range2range(4, [0 100], [0 200]);
%   Output:
%       x = 8
%
%   Example 2:
%   Take the value 4 from within the range of 0 to 100 and obtain its equivilent value in terms of range 0 to 200, and also 
%   return the range in which it is in:
%       [x, rangeOfX] = range2range(4, [0 100], [0 200]);
%   Output:
%       x = 8
%       rangeOfX = [0 200]

%
%   Copyright 2017-2018 Christopher L. Kerner.
%

if(nargin ~= 3)
    error('Incorrect number of input arguments')
end

%Check that input arguments do not contain NaN
if any(isnan(originalNumber)) || any(isnan(originalRange)) || any(isnan(newRange))
    error('Input arguments may not contain NaN')
end

%Check that originalNumber is not empty and a real numeric scalar
if isempty(originalNumber) || ~isscalar(originalNumber) || ~isnumeric(originalNumber) || ~isreal(originalNumber)
    error('Must specify a real scalar number to be adapted to new range. Example: 26.')
end

%Check that originalRange and newRange are 1-by-2 or 2-by-1 populated vectors.
if isempty(originalRange) || ~isnumeric(originalRange) || ~(length(originalRange) == 2) || ~isvector(originalRange)
    error('Original range must be a real 1-by-2 vector range. Example: [-20, 140].')
elseif isempty(newRange) || ~isnumeric(newRange) ||  ~(length(newRange) == 2) || ~isvector(newRange)
    error('New range must be a real 1-by-2 vector range. Example: [-20, 140].')
end

%check that specified original range is a row vector, and convert to row vector if not
if ~isrow(originalRange)
	warning('Original range was specified as a 2-by-1 column vector when anticipated is a 1-by-2 row vector. Adjusting.')
	originalRange = originalRange.';
elseif ~isrow(newRange)
	warning('new range was specified as a 2-by-1 column vector when anticipated is a 1-by-2 row vector. Adjusting.')
	newRange = newRange.';
end

%Assure that originalRange is formated so as originalRange(1) < originalRange(2).
if originalRange(1) >= originalRange(2)
    error('First value of original range must be larger than second. Example: [-20, 140]')
elseif newRange(1) >= newRange(2)
    error('First value of new range must be larger than second. Example: [-20, 140]')
end

%Check that the original range and new range are not identical.
if all(originalRange == newRange)
    error('Original range and new range must not be equal.')
end

%Lastly, check that the original number is within the original range.
if ~(originalNumber >= originalRange(1) && originalNumber <= originalRange(2))
    error('Number specified is not within provided original range.')
end

%If no errors, perform linear interpolation.
newNumber =  newRange(1) + ((originalNumber - originalRange(1))/(originalRange(2) - originalRange(1))) * (newRange(2) - newRange(1));

%Allow output to be either the new number within the range, or the number and the new range
varargout{1} = newNumber;
varargout{2} = newRange;
end

