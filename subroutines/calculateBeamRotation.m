lengthOfWPRecord = size(m, 'wp11');
m.beamRotation(lengthOfWPRecord(1),11) = 0;

%Define initial gamma angle to compare again.
beamInitialAngle1 = mean(m.wpAngles(:,3)); %Initial angle top of beam
beamInitialAngle2 = mean(m.wpAngles(:,6)); %Initial angle bot of beam
beamInitialAngle3 = mean(m.wpAngles(:,9)); %Initial angle of pivot rod
beamInitialAngle4 = mean(m.wpAngles(:,12)); %Initial angle of column top %%%REMAP
beamInitialAngle5 = mean(m.wpAngles(:,14)); %Initial angle top of beam
beamInitialAngle6 = mean(m.wpAngles(:,17)); %Initial angle of bot rod

%Compare current angle between sides a & b (angle gamma) to the
%initial angle.
m.beamRotation(:,1) = m.wpAngles(:, 3) - beamInitialAngle1;
m.beamRotation(:,2) = m.wpAngles(:, 6) - beamInitialAngle2;
m.beamRotation(:,3) = m.wpAngles(:, 9) - beamInitialAngle3;
m.beamRotation(:,4) = m.wpAngles(:, 14) - beamInitialAngle5;
m.beamRotation(:,5) = m.wpAngles(:, 17) - beamInitialAngle6;
m.beamRotation(:,6) = m.wpAngles(:, 12) - beamInitialAngle4; %%%REMAP

%Use vectors to determine total rotation of beam
%For top wirepot groups
Vi = [mean(x3Glo(:,1))-mean(x3Glo(:,2)) mean(y3Glo(:,1))-mean(y3Glo(:,2))];
V = [x3Glo(:,1)-x3Glo(:,2) y3Glo(:,1)-y3Glo(:,2)];

VDot(:,1) = dot(repmat(Vi,size(V,1),1), V, 2);
ViMag = sqrt(Vi(1)^2 + Vi(2)^2);
VMag(:,1) = sqrt(V(:,1).^2 + V(:,2).^2);
m.beamRotation(:,7) = acos(VDot./(ViMag .* VMag));

%For bottom wirepot groups
clearvars Vi V VDot ViMag VMag;
Vi = [mean(x3Glo(:,3))-mean(x3Glo(:,4)) mean(y3Glo(:,3))-mean(y3Glo(:,4))];
V = [x3Glo(:,3)-x3Glo(:,4) y3Glo(:,3)-y3Glo(:,4)];

VDot(:,1) = dot(repmat(Vi,size(V,1),1), V, 2);
ViMag = sqrt(Vi(1)^2 + Vi(2)^2);
VMag(:,1) = sqrt(V(:,1).^2 + V(:,2).^2);
m.beamRotation(:,8) = real(acos(VDot./(ViMag .* VMag)));

%Use Horn's Method to calculate rotation and also get COR from this.
%See
%http://people.csail.mit.edu/bkph/papers/Absolute_Orientation.pdf
%and
%http://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method

d = sqrt((WPPos(9,1)-WPPos(10,1))^2 + (WPPos(9,2)-WPPos(10,2))^2);
a = (m.wp(:,9).^2 - m.wp(:,14).^2 + d^2)/(2*d);
x2 = WPPos(9,1) + a*(WPPos(10,1)-WPPos(9,1))/d;
y2 = WPPos(9,2) + a*(WPPos(10,2)-WPPos(9,2))/d;
x3 = [x2 + wpHeight(:,4).*(WPPos(10,2)-WPPos(9,2))/d, x2 - wpHeight(:,4).*(WPPos(10,2)-WPPos(9,2))/d];
y3 = [y2 + wpHeight(:,4).*(WPPos(10,1)-WPPos(9,1))/d, y2 - wpHeight(:,4).*(WPPos(10,1)-WPPos(9,1))/d];

%Init posistion
pointsA = [[x3Glo(1,1); y3Glo(1,1)] [x3Glo(1,2); y3Glo(1,2)] [x3Glo(1,3); y3Glo(1,3)] [x3Glo(1,4); y3Glo(1,4)]];
%pointsA2 = [[mean(x3Glo(:,3)); mean(y3Glo(:,3))] [mean(x3Glo(:,4)); mean(y3Glo(:,4))]];
%pointsA3 = [[x3Glo(1,5); y3Glo(1,5)] [x3Glo(1,6); y3Glo(1,6)] [wp51Pos(1); wp51Pos(2)] [wp52Pos(1); wp52Pos(2)]];
pointsA3 = [[WPPos(9,1); WPPos(9,2)] [WPPos(10,1); WPPos(10,2)] [x2(1); y2(1)] [x3(1,1); y3(1,1)]];

%To prevent broadcast variables and increase speed
x1 = x3Glo(:,1); x2 = x3Glo(:,2); x3 = x3Glo(:,3); x4 = x3Glo(:,4);
y1 = y3Glo(:,1); y2 = y3Glo(:,2); y3 = y3Glo(:,3); y4 = y3Glo(:,4);

x13 = x2; x23 = x3(:,1);
y13 = y2; y23 = y3(:,1);
tic

parfor r = 1:1:lengthOfWPRecord(1)
    %Current Position
    pointsB = [[x1(r); y1(r)] [x2(r); y2(r)] [x3(r); y3(r)] [x4(r); y4(r)]];
    %pointsB2 = [[x3Glo(r,3); y3Glo(r,3)] [x3Glo(r,4); y3Glo(r,4)]];
    pointsB3 = [[WPPos(9,1); WPPos(9,2)] [WPPos(10,1); WPPos(10,2)] [x13(r); y13(r)] [x23(r); y23(r)] ];
    
    rotInfo(r) = [absor(pointsA, pointsB)];
    %rotInfo2(r) = [absor(pointsA2, pointsB2)];
    rotInfo3(r) = [absor(pointsA3, pointsB3)];
    
    %With the translation and rotation matrix from absor() we know that
    %COR=R*x + t describes the center of rotation if we find a point on
    %X that does not change. Matrix backsolving gives us x = (eye(2) -
    %R)\t.
    %beamCOR(r,1:2) = (eye(2)-rotInfo(r).R)\rotInfo(r).t;
    %beamCOR(r,2:4) = (eye(2)-rotInfo2(r).R)\rotInfo2(r).t;
end
toc

tempVar = [rotInfo(:).theta].';
%tempVar2 = [rotInfo2(:).theta].';
tempVar3 = [rotInfo3(:).theta].';

[row1, col1] = find(tempVar > 25);
%[row2, col2] = find(tempVar2 > 1);
[row3, col3] = find(tempVar3 > 25);

m.beamRotation(:,9) = tempVar;
%beamRotation(:,14) = tempVar2;
m.beamRotation(:,10) = tempVar3;

m.beamRotation(row1,9) = m.beamRotation(row1,9) - 360;
%beamRotation(row2,14) = beamRotation(row2,14) - 360;
m.beamRotation(row3,10) = m.beamRotation(row3,10) - 360;


if ProcessShearTab == 2 || ProcessShearTab == 4
    %h1WP = 5.525; %Width of flange in inches
    h1WP = 15 + (5/8); %Distance between wirepot strings
    h1LP = 14.5;
else
    h1WP = 5.025; %Width of flange in inches
    h1LP = 0;
end

dx11 = x3Glo(:,1) - mean(x3Glo(:,1));
dx12 = x3Glo(:,3) - mean(x3Glo(:,3));
dx1  = (dx11 + dx12)./2;

dx21 = x3Glo(:,2) - mean(x3Glo(:,2));
dx22 = x3Glo(:,4) - mean(x3Glo(:,4));
dx2  = (dx21 + dx22)./2;

m.beamRotation(:,11) = (dx1 + dx2)./h1WP;
%{
    lpdx11 = lp(:,1) - mean(lp(:,1));
    lpdx21 = lp(:,3) - mean(lp(:,3));
    lpdx1 = (lpdx11 + lpdx21)./2;
    
    lpdx12 = lp(:,2) - mean(lp(:,2));
    lpdx22 = lp(:,4) - mean(lp(:,4));
    lpdx2 = (lpdx12 + lpdx22)./2;
    
    beamRotation(:,18) = (lpdx1 + lpdx2)./h1LP;
%}
clearvars beamInitialAngle1 beamInitialAngle2 beamInitialAngle3 ...
    beamInitialAngle5 beamInitialAngle6 Vi V VDot ViMag VMag ...
    d a x2 y2 x3 y3 pointsA pointsA3 x1 x2 x3 x4 y1 y2 y3 y4 ...
    x13 x23 y13 y23 pointsB pointsB3 rotInfo rotInfo3 tempVar ...
    tempVar3 row1 row3 col1 col3 h1WP h1LP dx11 dx12 dx1 dx21 ...
    dx22 dx2;