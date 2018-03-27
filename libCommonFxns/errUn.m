function [ results ] = errUn( experimental1, actual, experimental2 )
%errUn Provides array of percent error and percent difference between vals.
%   Returns array containing percent error between values when given
%experimental (measured) value and actual value, and additionally adds a
%column containing percent difference if experimental1, actual, and 
%experimental2 are provided.
%
%Percent error is difference between measured and accepted data, percent
%difference is between two measured values.
%EXPECTS ONLY REAL INTEGERS AND/OR FLOATING NUMBERS. NO FAIL SAFE FOR
%THIS.
    if nargin == 2
        if isnumeric(experimental1) == 0 || isnumeric(actual) == 0
            error('Inputs are not numbers');
        end
        results = [abs(experimental1-actual)./actual];
    elseif nargin == 3
        if isnumeric(experimental1) == 0 || isnumeric(actual) == 0 || isnumeric(experimental2) == 0
            error('Inputs are not numbers');
        end
        results = [(abs(experimental1-actual)./actual), abs(experimental1-experimental2)./((experimental1+experimental2)./2)];
    else
        error('Either too few or two many arguments passed.');
    end
end

