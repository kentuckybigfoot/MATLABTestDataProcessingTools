function [  wpAngles,  wpAnglesDeg ] = procWPAngles( wp )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

for i = 1:1:size(wp,1)
    %Wirepot Set 1
    wp1cDist = 4;                                                                            %Dist b/t WPs CTC.
    wp1Angles(i,1) = acos((wp(i,2)^2 - wp(i,1)^2 - wp1cDist^2)/(-2*wp(i,1)*wp1cDist));       %Alpha
    wp1Angles(i,2) = acos((wp(i,1)^2 - wp(i,2)^2 - wp1cDist^2)/(-2*wp(i,2)*wp1cDist));       %Beta
    wp1Angles(i,3) = acos((wp1cDist^2 - wp(i,2)^2 - wp(i,1)^2)/(-2*wp(i,2)*wp(i,1)));        %Gamma
    
    %Wirepot Set 2
    wp2cDist = 4;                                                                            %Dist b/t WPs CTC.
    wp2Angles(i,1) = acos((wp(i,4)^2 - wp(i,3)^2 - wp2cDist^2)/(-2*wp(i,3)*wp2cDist));       %Alpha
    wp2Angles(i,2) = acos((wp(i,3)^2 - wp(i,4)^2 - wp2cDist^2)/(-2*wp(i,4)*wp2cDist));       %Beta
    wp2Angles(i,3) = acos((wp2cDist^2 - wp(i,4)^2 - wp(i,3)^2)/(-2*wp(i,4)*wp(i,3)));        %Gamma
    
    %Wirepot Set 3
    %Note that name of wirepots is the grouping followed by the wirepot's
    %number in the group from right to left with the cylinder pointed upward.
    %For ST1, wirepot 3 sat at the bottom of the beam and was turned upside
    %due to clearance requiring an inversion of naming here.
    wp3cDist = 4;                                                                            %Dist b/t WPs CTC.
    wp3Angles(i,1) = acos((wp(i,5)^2 - wp(i,6)^2 - wp3cDist^2)/(-2*wp(i,6)*wp3cDist));       %Alpha
    wp3Angles(i,2) = acos((wp(i,6)^2 - wp(i,5)^2 - wp3cDist^2)/(-2*wp(i,5)*wp3cDist));       %Beta
    wp3Angles(i,3) = acos((wp3cDist^2 - wp(i,5)^2 - wp(i,6)^2)/(-2*wp(i,5)*wp(i,6)));        %Gamma
    
    %Wirepot Set 4
    %Same change as wirepot set 3.
    wp4cDist = 4;                                                                            %Dist b/t WPs CTC.
    wp4Angles(i,1) = acos((wp(i,7)^2 - wp(i,8)^2 - wp4cDist^2)/(-2*wp(i,8)*wp4cDist));       %Alpha
    wp4Angles(i,2) = acos((wp(i,8)^2 - wp(i,7)^2 - wp4cDist^2)/(-2*wp(i,7)*wp4cDist));       %Beta
    wp4Angles(i,3) = acos((wp4cDist^2 - wp(i,7)^2 - wp(i,8)^2)/(-2*wp(i,7)*wp(i,8)));        %Gamma
    
end

    wpAngles(:,:) = [wp1Angles(:,1) wp1Angles(:,2) wp1Angles(:,3) wp2Angles(:,1) wp2Angles(:,2) wp2Angles(:,3) wp3Angles(:,1) wp3Angles(:,2) wp3Angles(:,3) wp4Angles(:,1) wp4Angles(:,2) wp4Angles(:,3)];
    wpAnglesDeg(:,:) = (180/pi)*[wp1Angles(:,1) wp1Angles(:,2) wp1Angles(:,3) wp2Angles(:,1) wp2Angles(:,2) wp2Angles(:,3) wp3Angles(:,1) wp3Angles(:,2) wp3Angles(:,3) wp4Angles(:,1) wp4Angles(:,2) wp4Angles(:,3)];