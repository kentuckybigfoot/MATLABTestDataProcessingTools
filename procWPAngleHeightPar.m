function [ wpAngleHeight ] = procWPAngleHeightPar( wp )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

for i = 1:1:4
    parfor j = 1:1:size(wp,1)
        wpABCMap       = [wp(j,2) wp(j,1) 4; wp(j,4) wp(j,3) 4; wp(j,5) wp(j,6) 4; wp(j,7) wp(j,8) 4];   
        
        wpS = (wpABCMap(i,1) + wpABCMap(i,2) + wpABCMap(i,3))/2; %semiperimeter
        
        wpAngleArea(j,i) = sqrt(wpS*(wpS - wpABCMap(i,1))*(wpS - wpABCMap(i,2))*(wpS - wpABCMap(i,3)));
        
        wpAngleHeight(j,i) = 2*(wpAngleArea(j,i)/4);
    end
end

