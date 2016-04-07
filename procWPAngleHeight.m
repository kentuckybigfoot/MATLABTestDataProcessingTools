function [ wpAngleHeight ] = procWPAngleHeight( wp )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

for i = 1:1:4
    for j = 1:1:size(wp,1)
        wpABCMap       = {wp(j,2) wp(j,1) 4; wp(j,4) wp(j,3) 4; wp(j,5) wp(j,6) 4; wp(j,7) wp(j,8) 4};
        
        wpS = (wpABCMap{i,1} + wpABCMap{i,2} + wpABCMap{i,3})/2;
        
        wpAngleArea(j,i) = sqrt(wpS*(wpS - wpABCMap{i,1})*(wpS - wpABCMap{i,2})*(wpS - wpABCMap{i,3}));
        
        wpAngleHeight(j,i) = 2*(wpAngleArea(j,i)/4);
        
        percentage = round((j/size(wp,1))*100,3);
        if mod(percentage,2) == 0
            disp([num2str(percentage),'% Complete Calculating WPHeights'])
        end
    end
end

