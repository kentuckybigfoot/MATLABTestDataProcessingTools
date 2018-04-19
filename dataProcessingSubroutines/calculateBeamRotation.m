lengthOfWPRecord = size(m, 'wp', 1);
%Use Horn's Method to calculate rotation and also get COR from this. see:
%http://people.csail.mit.edu/bkph/papers/Absolute_Orientation.pdf
%and
%http://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method

%Init posistion
pointsA = [[x3Glo(1,1); y3Glo(1,1)] [x3Glo(1,2); y3Glo(1,2)] [x3Glo(1,3); y3Glo(1,3)] [x3Glo(1,4); y3Glo(1,4)]];

%To prevent broadcast variables and increase speed
x1 = x3Glo(:,1); x2 = x3Glo(:,2); x3 = x3Glo(:,3); x4 = x3Glo(:,4);
y1 = y3Glo(:,1); y2 = y3Glo(:,2); y3 = y3Glo(:,3); y4 = y3Glo(:,4);

rotInfo(lengthOfWPRecord) = struct('R', [], 't', [], 's', [], 'M', [], 'theta', []);

tic
parfor r = 1:1:lengthOfWPRecord(1)
    %Current Position
    pointsB = [[x1(r); y1(r)] [x2(r); y2(r)] [x3(r); y3(r)] [x4(r); y4(r)]];
    
    rotInfo(r) = absor(pointsA, pointsB);
    %rotInfo2(r) = [absor(pointsA2, pointsB2)];
    %rotInfo3(r) = absor(pointsA3, pointsB3);
    
    %With the translation and rotation matrix from absor() we know that
    %COR=R*x + t describes the center of rotation if we find a point on
    %X that does not change. Matrix backsolving gives us x = (eye(2) -
    %R)\t.
    %beamCOR(r,1:2) = (eye(2)-rotInfo(r).R)\rotInfo(r).t;
end
toc

tempVar = [rotInfo(:).theta].';

[row1, col1] = find(tempVar > 25);

tempVar(row1) = tempVar(row1) - 360;

m.beamRotation(1:lengthOfWPRecord,1) = tempVar;

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

%m.beamRotation(:,2) = (dx1 + dx2)./h1WP;

clearvars beamInitialAngle Vi V VDot ViMag VMag ...
    d a x2 y2 x3 y3 pointsA pointsA3 x1 x2 x3 x4 y1 y2 y3 y4 ...
    x13 x23 y13 y23 pointsB pointsB3 rotInfo rotInfo3 tempVar ...
    tempVar3 row1 row3 col1 col3 h1WP h1LP dx11 dx12 dx1 dx21 ...
    dx22 dx2;