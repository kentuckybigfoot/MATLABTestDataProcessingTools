function [ wpAngles, wpAnglesDeg ] = procWPAngles( wp, dist )
%procWPAngles Determines angles of triangles made by wirepots
%   Input the wirepot aray and a distance array to have an a nx2 array out
%   put containing the angles of the wire pot groups in radians and then
%   degrees, respectively. Order or angles is alpha, beta, gamma and
%   repeats for every triangle (i. e. A, B, G, A, B, G).
%
%   Note that name of wirepot is the grouping followed by the wirepot's
%   number in the group from right to left w/ the cylinder pointed upward.
%   
%   Old note: For ST1, wirepot 3 sat at the bottom of the beam and was
%   turned upside due to clearance requiring an inversion of naming here.

sizeOfWP = size(wp,1);
dist = repmat(dist, sizeOfWP, 1);

%Wirepot Set 1
%[wp1Angles1(:,1), wp1Angles2(:,1), wp1Angles3(:,1)] = lawOfCos([wp(:,7) wp(:,1) dist(:,1)]);
[wp1Angles1(:,1), wp1Angles2(:,1), wp1Angles3(:,1)] = lawOfCos([wp(:,1) wp(:,7) dist(:,1)]);

%Wirepot Set 2
%Change for ST3
%[wp2Angles1(:,1), wp2Angles2(:,1), wp2Angles3(:,1)] = lawOfCos([wp(:,2) wp(:,8) dist(:,2)]);
[wp2Angles1(:,1), wp2Angles2(:,1), wp2Angles3(:,1)] = lawOfCos([wp(:,8) wp(:,2) dist(:,2)]);

%Wirepot Set 3
[wp3Angles1(:,1), wp3Angles2(:,1), wp3Angles3(:,1)] = lawOfCos([wp(:,5) wp(:,6) dist(:,3)]);

%Wirepot Set 4
if dist(:,4) ~= 0
    [wp4Angles1(:,1), wp4Angles2(:,1), wp4Angles3(:,1)] = lawOfCos([wp(:,14) wp(:,9) dist(:,4)]);
else
    wp4Angles1(:,1) = zeros(sizeOfWP,1);
    wp4Angles2(:,1) = wp4Angles1(:,1);
    wp4Angles3(:,1) = wp4Angles1(:,1);
end

%Wirepot Set 5 (Bottom group 1)
%Same concept as wirepot set 1
%[wp5Angles1(:,1), wp5Angles2(:,1), wp5Angles3(:,1)] = lawOfCos([wp(:,3) wp(:,12) dist(:,5)]);
[wp5Angles1(:,1), wp5Angles2(:,1), wp5Angles3(:,1)] = lawOfCos([wp(:,12) wp(:,3) dist(:,5)]);
%Wirepot Set 6 (Bottom group 1)
%Same concept as wirepot set 2
%Changed for ST3
%[wp6Angles1(:,1), wp6Angles2(:,1), wp6Angles3(:,1)] = lawOfCos([wp(:,13) wp(:,4) dist(:,6)]);
[wp6Angles1(:,1), wp6Angles2(:,1), wp6Angles3(:,1)] = lawOfCos([wp(:,4) wp(:,13) dist(:,6)]);

wpAngles(:,:)    = cat(2, wp1Angles1(:,1), wp1Angles2(:,1), wp1Angles3(:,1), wp2Angles1(:,1), wp2Angles2(:,1), wp2Angles3(:,1), wp3Angles1(:,1), wp3Angles2(:,1), wp3Angles3(:,1), wp4Angles1(:,1), wp4Angles2(:,1), wp4Angles3(:,1), wp5Angles1(:,1), wp5Angles2(:,1), wp5Angles3(:,1),  wp6Angles1(:,1), wp6Angles2(:,1), wp6Angles3(:,1));
wpAnglesDeg(:,:) = (180/pi).*wpAngles;
end

