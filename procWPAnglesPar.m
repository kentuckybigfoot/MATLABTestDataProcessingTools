function [ wpAngles, wpAnglesDeg ] = procWPAnglesPar( wp, dist )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

parfor i = 1:1:size(wp,1)
    %Wirepot Set 1
    [wp1Angles1(i,1) wp1Angles2(i,1) wp1Angles3(i,1)] = lawOfCos([wp(i,7) wp(i,1) dist(1)]);
    
    %Wirepot Set 2
    [wp2Angles1(i,1), wp2Angles2(i,1) wp2Angles3(i,1)] = lawOfCos([wp(i,2) wp(i,8) dist(2)]);
    
    %Wirepot Set 3
    %Note that name of wirepots is the grouping followed by the wirepot's
    %number in the group from right to left with the cylinder pointed upward.
    %For ST1, wirepot 3 sat at the bottom of the beam and was turned upside
    %due to clearance requiring an inversion of naming here.
    [wp3Angles1(i,1) wp3Angles2(i,1) wp3Angles3(i,1)] = lawOfCos([wp(i,6) wp(i,5) dist(3)]);
    
    %Wirepot Set 4
    %Same change as wirepot set 3.
    wp4cDist = sqrt(wp(50,7)^2 + wp(50,1)^2); %Dist b/t WPs CTC.
    %[wp4Angles1(i,1) wp4Angles2(i,1) wp4Angles3(i,1)]  = lawOfCos([wp(i,7) wp(i,8) wp4cDist]);
    [wp4Angles1(i,1) wp4Angles2(i,1) wp4Angles3(i,1)]  = lawOfCos([wp(i,12) wp(i,9) wp4cDist]);
    
    %Wirepot Set 5
    %Same concept as wirepot set 1
    [wp5Angles1(i,1) wp5Angles2(i,1) wp5Angles3(i,1)] = lawOfCos([wp(i,3) wp(i,12) dist(5)]);
    
    %Wirepot Set 6
    %Same concept as wirepot set 2
    [wp6Angles1(i,1) wp6Angles2(i,1) wp6Angles3(i,1)] = lawOfCos([wp(i,13) wp(i,4) dist(6)]);
end

wpAngles(:,:) = [wp1Angles1(:,1) wp1Angles2(:,1) wp1Angles3(:,1) wp2Angles1(:,1) wp2Angles2(:,1) wp2Angles3(:,1) wp3Angles1(:,1) wp3Angles2(:,1) wp3Angles3(:,1) real(wp4Angles1(:,1)) real(wp4Angles2(:,1)) real(wp4Angles3(:,1)) wp5Angles1(:,1) wp5Angles2(:,1) wp5Angles3(:,1)  wp6Angles1(:,1) wp6Angles2(:,1) wp6Angles3(:,1)];
wpAnglesDeg(:,:) = (180/pi)*[wp1Angles1(:,1) wp1Angles2(:,1) wp1Angles3(:,1) wp2Angles1(:,1) wp2Angles2(:,1) wp2Angles3(:,1) wp3Angles1(:,1) wp3Angles2(:,1) wp3Angles3(:,1) real(wp4Angles1(:,1)) real(wp4Angles2(:,1)) real(wp4Angles3(:,1))  wp5Angles1(:,1) wp5Angles2(:,1) wp5Angles3(:,1)  wp6Angles1(:,1) wp6Angles2(:,1) wp6Angles3(:,1)];
end

