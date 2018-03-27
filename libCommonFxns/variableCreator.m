function [ ] = variableCreator( newVar, variable )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
   assignin ( 'caller', newVar, variable );

end

