function [ area ] = heronsFormula( tL )
%heronsFormula Heron's Formula to find area of triangle
%   Carries out Heron's Formula and finds the area of the triangle given
%   three lengths. Must supply three lengths in any order since function
%   sorts inputs. Many ways exist to do this calc but a more numerically 
%   stable approach is presented. An explenation for this can be found at
%   https://en.wikipedia.org/wiki/Heron%27s_formula#Numerical_stability
%   or http://www.cs.berkeley.edu/~wkahan/Triangle.pdf.

if size(tL,1) ~= 3 && size(tL,2) ~= 3
    error('Requires three sides.');
end

tL = sort(tL,2,'descend');

area = (1/4).*sqrt((tL(:,1) + (tL(:,2) + tL(:,3))) ...
                      .*(tL(:,3) - (tL(:,1) - tL(:,2))) ...
                      .*(tL(:,3) + (tL(:,1) - tL(:,2))) ...
                      .*(tL(:,1) + (tL(:,2) - tL(:,3))) ...
                       );
end

