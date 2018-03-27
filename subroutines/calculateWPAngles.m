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

lengthOfWPRecord = size(m, 'wp11');
distBetweenWPsRepmat = repmat(distBetweenWPs.', [lengthOfWPRecord(1), 1]);

%Preallocate WP Angles
m.wpAngles(lengthOfWPRecord(1),1:18) = 0;
m.wpAnglesDeg(lengthOfWPRecord(1),1:18) = 0;

%Wirepot Set 1
%[wp1Angles1(:,1), wp1Angles2(:,1), wp1Angles3(:,1)] = lawOfCos([wp(:,7) wp(:,1) dist(:,1)]);
[m.wpAngles(:,1), m.wpAngles(:,2), m.wpAngles(:,3)] = lawOfCos([m.wp(:,1) m.wp(:,7) distBetweenWPsRepmat(:,1)]);

%Wirepot Set 2
%Change for ST3
%[wp2Angles1(:,1), wp2Angles2(:,1), wp2Angles3(:,1)] = lawOfCos([wp(:,2) wp(:,8) dist(:,2)]);
[m.wpAngles(:,4), m.wpAngles(:,5), w2Angles(:,6)] = lawOfCos([m.wp(:,8) m.wp(:,2) distBetweenWPsRepmat(:,2)]);

%Wirepot Set 3
[m.wpAngles(:,7), m.wpAngles(:,8), m.wpAngles(:,9)] = lawOfCos([m.wp(:,5) m.wp(:,6) distBetweenWPsRepmat(:,3)]);

%Wirepot Set 4
if distBetweenWPsRepmat(4) ~= 0
    [m.wpAngles(:,10), m.wpAngles(:,11), m.wpAngles(:,12)] = lawOfCos([m.wp(:,14) m.wp(:,9) distBetweenWPsRepmat(:,4)]);
else
    m.wpAngles(:,10:12) = zeros(lengthOfWPRecord,3);
end

%Wirepot Set 5 (Bottom group 1)
%Same concept as wirepot set 1
%[wp5Angles1(:,1), wp5Angles2(:,1), wp5Angles3(:,1)] = lawOfCos([wp(:,3) wp(:,12) dist(:,5)]);
[m.wpAngles(:,13), m.wpAngles(:,14), m.wpAngles(:,15)] = lawOfCos([m.wp(:,12) m.wp(:,3) distBetweenWPsRepmat(:,5)]);
%Wirepot Set 6 (Bottom group 1)
%Same concept as wirepot set 2
%Changed for ST3
%[wp6Angles1(:,1), wp6Angles2(:,1), wp6Angles3(:,1)] = lawOfCos([wp(:,13) wp(:,4) dist(:,6)]);
[m.wpAngles(:,16), m.wpAngles(:,17), m.wpAngles(:,18)] = lawOfCos([m.wp(:,4) m.wp(:,13) distBetweenWPsRepmat(:,6)]);

m.wpAnglesDeg(:,:) = (180/pi).*m.wpAngles;

c1 = find(round(m.wpAngles(:,1) + m.wpAngles(:,2) + m.wpAngles(:,3),12) ~= round(pi,12));
c2 = find(round(m.wpAngles(:,4) + m.wpAngles(:,5) + m.wpAngles(:,6),12) ~= round(pi,12));
c3 = find(round(m.wpAngles(:,7) + m.wpAngles(:,8) + m.wpAngles(:,9),12) ~= round(pi,12));
c4 = find(round(m.wpAngles(:,10) + m.wpAngles(:,11) + m.wpAngles(:,12),12) ~= round(pi,12));
c5 = find(round(m.wpAngles(:,13) + m.wpAngles(:,14) + m.wpAngles(:,15),12) ~= round(pi,12));
c6 = find(round(m.wpAngles(:,16) + m.wpAngles(:,17) + m.wpAngles(:,18),12) ~= round(pi,12));

if all([c1, c2, c3, c4, c5, c6]) == 0
    error('Check angles for accuracy. Unable to verify all angles equal pi');
end

clearvars lengthOfWPRecord distBetweenWPsRepmat c1 c2 c3 c4 c5 c6