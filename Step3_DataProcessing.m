clc
%close all
clear

format long;

global ProcessRealName %So we can pick this up in function calls
global ProcessCodeName %So we can pick this up in function calls
global ProcessFileName %So we can pick this up in function calls
global ProcessFilePath  %So we can pick this up in function calls

%Process Mode Variables
ProcessFilePath              = 'C:\Users\clk0032\Dropbox\Friction Connection Research\Full Scale Test Data\FS Testing -ST2 - 05-09-16';
ProcessFileName              = 'FS Testing - ST2 - Test 1 - 05-09-16';
ProcessRealName              = 'Full Scale Test 4 - ST2 Only - 05-09-16';
ProcessCodeName              = 'FST-ST2-May09-4';
ProcessShearTab              = '2'; %1, 2, 3, or 4
runParallel                  = true;
localAppend                  = true;
ProcessConsolidateSGs        = true;
ProcessConsolidateWPs        = true;
ProcessConsolidateLPs        = true;
ProcessConsolidateLCs        = true;
ProcessWPAngles              = true;
ProcessWPCoords              = false;
ProcessWPHeights             = true;
processWPHeighDistances      = false;
processWPCoordinates         = false;
ProcessLPs                   = true;
processIMU                   = false;
ProcessBeamRotation          = true;
ProcessStrainProfiles        = true;
ProcessCenterOfRotation      = false;
ProcessForces                = true;
ProcessMoments               = true;
ProcessEQM                   = true;
ProcessGarbageCollection     = false;
ProcessOutputPlots           = false;

% The very end where the pivot rests serves as reference for all
% measurements. All measurements are assumed to start at the extreme end of
% the column below the pivot point in the center of the web. Dimensions are
% given in (x,y)and represent the center of the hook at the end of the
% wire. Dimensions for the wire pots can be found in Fig. 2 of page 68
% (WDS-...-P60-CR-P) of http://www.micro-epsilon.com/download/manuals/man--wireSENSOR-P60-P96-P115--de-en.pdf

wp11Pos = [(13+7/8)+0.50+0.39 (8*12)-(38 + 2+ 5/16 + (5.07-2.71654))];
wp12Pos = [(13+7/8)+0.39 (22.9375+0.1875+0.1250+(5.07-2.71654))];
wp21Pos = [((5.07-2.71654)+0.125) (48.125+0.39)];  %Same as WP4-1 in theory
wp22Pos = [((5.07-2.71654)+0.125) (32.1875+0.39)]; %Same as WP4-2 in theory
wp31Pos = [0 0];
wp32Pos = [0 0];
wp41Pos = [((5.07-2.71654)+0.125) (48.125+0.39)];
wp42Pos = [((5.07-2.71654)+0.125) (32.1875+0.39)];
wp71Pos = [(13+7/8)+0.50+0.39 (8*12)-(37.75 + 5/16 + (5.07-2.71654))]; %Same as WP1-1 in theory
wp72Pos = [(13+7/8)+0.39 (23.1875+0.1250+(5.07-2.71654))];             %Same as WP1-2 in theory
D1 = DF(wp41Pos(1,1), wp11Pos(1,1), wp41Pos(1,2), wp11Pos(1,2)); %Top group 1
D2 = DF(wp42Pos(1,1), wp12Pos(1,1), wp42Pos(1,2), wp12Pos(1,2)); %Bot group 1
D3 = 4; %WP group measuring bottom global position
D4 = 0;
D5 = DF(wp21Pos(1,1), wp71Pos(1,1), wp21Pos(1,2), wp71Pos(1,2)); %Top group 2
D6 = DF(wp22Pos(1,1), wp72Pos(1,1), wp22Pos(1,2), wp72Pos(1,2)); %Bot group 2

%Constants
modulus      = 29000; %Modulus of elasticity (ksi)
boltEquation = 0.1073559499;
gaugeLength  = [0.19685; 0.19685]; %(in) which is 5 mm
gaugeWidth   = [0.0590551; 0.19685]; %(in) which is 1.5 mm

if ProcessShearTab == '2' || ProcessShearTab == '4'
    stMidHeight = 5.75;
    yGaugeLocations = [4.5; 1.5; -1.5; -4.5; -10];
    yGaugeLocationsExpanded = [stMidHeight; 4.5; 1.5; -1.5; -4.5; -stMidHeight; -10];
else
    stMidHeight = 4.25;
    yGaugeLocations = [3; 0; -3; -9];
    yGaugeLocationsExpanded = [stMidHeight; 3; 0; -3; -stMidHeight; -9];
end

%Load data. Checks if IMU data exists and processes it if so. This is more
%of a legacy feature since IMU was not added until months after testing
%began.
IMUDataFileName = fullfile(ProcessFilePath,sprintf('[ProcRotationData]%s.mat',ProcessFileName));
ProcessFileName = fullfile(ProcessFilePath, sprintf('[Filter]%s.mat',ProcessFileName));

load(ProcessFileName);

if exist(IMUDataFileName, 'file') == 2
    load(IMUDataFileName);
else
    processIMU = false; %Failsafe incase trying to proccess non-exist. file
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE STRAIN GAUGE VARIABLES INTO SINGLE ARRAY                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateSGs == true
    sg = ConsolidateSGs(ProcessShearTab, ProcessFileName);
    disp('Strain gauge variables successfully consolidated. Appending to file and removing garbage.');
    clearvars sg1 sg2 sg3 sg4 sg5 sg6 sg7 sg8 sg9 sg10 sg11 sg12 sg13 sg14 sg15 sg16 sg17 sg18 sg19 sg20 sg21 sg22 sgBolt;
    if localAppend == true
        save(ProcessFileName, 'sg', '-append');
    end
    disp('File successfully appended.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE WIRE POTENTIOMETER VARIABLES INTO SINGLE ARAY                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateWPs == true
    wp(:,1)  = wp11(:,1);
    wp(:,2)  = wp12(:,1);
    wp(:,3)  = wp21(:,1);
    wp(:,4)  = wp22(:,1);
    wp(:,5)  = wp31(:,1);
    wp(:,6)  = wp32(:,1);
    wp(:,7)  = wp41(:,1);
    wp(:,8)  = wp42(:,1);
    wp(:,9)  = wp51(:,1);
    wp(:,10) = wp61(:,1);
    wp(:,11) = wp62(:,1);
    wp(:,12) = wp71(:,1);
    wp(:,13) = wp72(:,1);
    wp       = wp + 2.71654;
    wp(:,14) = MTSLVDT(:,1);
    
    disp('WP variables successfully converted into one. Appending to file and removing garbage.')
    clearvars wp11 wp12 wp21 wp22 wp31 wp32 wp41 wp42 wp51 wp61 wp62 wp71 wp72 MTSLVDT;
    if localAppend == true
        save(ProcessFileName, 'wp', '-append');
    end
    disp('File successfully appended.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE LINEAR POTENTIOMETER VARIABLES INTO SINGLE ARAY              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateLPs == true
    lp(:,1)  = LP1(:,1);
    lp(:,2)  = LP2(:,1);
    lp(:,3)  = LP3(:,1);
    lp(:,4)  = LP4(:,1);
    lp(:,5)  = (offset(LP1(:,1)) + offset(LP3(:,1)))/2;
    lp(:,6)  = (offset(LP2(:,1)) + offset(LP4(:,1)))/2;
    
    disp('LP variables successfully converted into one. Appending to file and removing garbage.')
    clearvars LP1 LP2 LP3 LP4;
    if localAppend == true
        save(ProcessFileName, 'lp', '-append');
    end
    disp('File successfully appended.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE LOAD CELLS VARIABLES AND LOAD CELL GROUPS INTO SINGLE ARRAY  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateLCs == true
    lc(:,1) = LC1(:,1);
    lc(:,2) = LC2(:,1);
    lc(:,3) = LC3(:,1);
    lc(:,4) = LC4(:,1);
    lc(:,5) = MTSLC(:,1);
    lc(:,6) = offset(LC1(:,1))+offset(LC2(:,1));
    lc(:,7) = offset(LC3(:,1))+offset(LC4(:,1));
    
    disp('Load cell variables successfully converted into one. Appending to file and removing garbage.')
    clearvars LC1 LC2 LC3 LC4 MTSLC;
    if localAppend == true
        save(ProcessFileName, 'lc', '-append');
    end
    disp('File successfully appended.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE EACH ANGLE OF WIRE POTENTIOMETER TRIANGLES                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessWPAngles == true
    wpAnglesPass = [true true true true];
    
    disp('Processing angles');
    if runParallel == true
        [wpAngles, wpAnglesDeg] = procWPAnglesPar(wp(:,:), [D1, D2, D3, D4, D5, D6]);
    else
        [wpAngles, wpAnglesDeg] = procWPAngles(wp);
    end
    
    disp('Processing angles complete. Validating angles.')
    
    for i = 1:1:length(wp)
        if round(wpAngles(i,1) + wpAngles(i,2) + wpAngles(i,3),4) ~= round(pi,4)
            wpAnglesPass(1,1) = false;
            break;
        end
        if round(wpAngles(i,4) + wpAngles(i,5) + wpAngles(i,6),4) ~= round(pi,4)
            wpAnglesPass(1,2) = false;
            break;
        end
        if round(wpAngles(i,7) + wpAngles(i,8) + wpAngles(i,9),4) ~= round(pi,4)
            wpAnglesPass(1,3) = false;
            break;
        end
        if round(wpAngles(i,10) + wpAngles(i,11) + wpAngles(i,12),4) ~= round(pi,4)
            wpAnglesPass(1,4) = false;
            break;
        end
    end

    if any(wpAnglesPass == 0)
        disp('Error determining WP Angles with non offset data.')
    else
        disp('Angles using non offset data calculated successfully. Appending to file (if localAppend = true) and removing garbage.')
        clearvars wp1Angles wp2Angles wp3Angles wp4Angles wp1cDist wp2cDist wp3cDist wp4cDist wpAnglesPass
        if localAppend == true
            save(ProcessFileName, 'wpAngles', 'wpAnglesDeg', '-append');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE HEIGHT OF WIRE POT TRIANGLES                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Use Heron's Formula to determine the area of the triangle made by the
%wirepots and then backsolve formula for area of triangle to get triangle
%height. This can be backsolved
%to calculate d which is the distance from vertex A to line h with line h
%being the line perpendicular to line c and extending to vertex C. See
%derivation sheet.
if ProcessWPCoords == true
    %Get (x3,y3) coords of vertex C of wire pot triangles
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %WP G1 Top
    coordAngles(:,1) = atan2((wp11Pos(2)-wp41Pos(2)),(wp11Pos(1)-wp41Pos(1))) - wpAngles(:,2);
    x3Loc(:,1) = wp(:,7).*cos(coordAngles(:,1));
    x3Glo(:,1) = wp41Pos(1) + x3Loc(:,1);
    
    y3Loc(:,1) = (wp11Pos(2)-wp41Pos(2)) + (wp(:,7).*sin(coordAngles(:,1)));
    y3Glo(:,1) = (wp11Pos(2) - (wp11Pos(2)-wp41Pos(2))) + y3Loc(:,1);
    
    %WP G2 Top
    coordAngles(:,2) = atan2((wp42Pos(2)-wp12Pos(2)),(wp12Pos(1)-wp42Pos(1))) - wpAngles(:,4);
    x3Loc(:,2) = wp(:,8).*cos(coordAngles(:,2));
    x3Glo(:,2) = wp42Pos(1) + x3Loc(:,2);
    
    y3Loc(:,2) = (wp42Pos(2)-wp12Pos(2)) + (wp(:,8).*sin(coordAngles(:,2)));
    y3Glo(:,2) = wp12Pos(2) + y3Loc(:,2);
    
    %WP G1 Bottom
    coordAngles(:,3) = atan2((wp71Pos(2)-wp21Pos(2)),(wp71Pos(1)-wp21Pos(1))) - wpAngles(:,14);
    x3Loc(:,3) = wp(:,3).*cos(coordAngles(:,3));
    x3Glo(:,3) = wp21Pos(1) + x3Loc(:,3);
    
    y3Loc(:,3) = (wp71Pos(2)-wp21Pos(2)) + (wp(:,3).*sin(coordAngles(:,3)));
    y3Glo(:,3) = (wp71Pos(2) - (wp71Pos(2)-wp21Pos(2))) + y3Loc(:,3);
    
    %WP G2 Bottom
    coordAngles(:,4) = atan2((wp22Pos(2)-wp72Pos(2)),(wp72Pos(1)-wp22Pos(1))) - wpAngles(:,16);
    x3Loc(:,4) = wp(:,4).*cos(coordAngles(:,4));
    x3Glo(:,4) = wp22Pos(1) + x3Loc(:,4);
    
    y3Loc(:,4) = (wp22Pos(2)-wp72Pos(2)) + (wp(:,4).*sin(coordAngles(:,4)));
    y3Glo(:,4) = wp22Pos(2) + y3Loc(:,4);
    
    %Get (x4,y4) coords middle of line c
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Don't need a local since it would just be half the length of the line
    %C which we calculate in the D* variables.
    
    %WP G1 Top
    x4Glo(:,1) = (wp41Pos(1) + wp11Pos(1))/2; 
    y4Glo(:,1) = (wp41Pos(2) + wp11Pos(2))/2;
    
    %WP G1 Bottom
    x4Glo(:,2) = (wp21Pos(1) + wp71Pos(1))/2; 
    y4Glo(:,2) = (wp21Pos(2) + wp71Pos(2))/2;
    
    %WP G2 Top
    x4Glo(:,3) = (wp42Pos(1) + wp12Pos(1))/2; 
    y4Glo(:,3) = (wp42Pos(2) + wp12Pos(2))/2;
    
    %WP G2 Bottom
    x4Glo(:,4) = (wp22Pos(1) + wp72Pos(1))/2; 
    y4Glo(:,4) = (wp22Pos(2) + wp72Pos(2))/2;    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESS LP DATA                                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessLPs == true
    load('C:\Users\clk0032\Dropbox\Friction Connection Research\Linear Spring Potentiometer Calibration\LPCal.mat');
    
    for r = 1:1:size(p1,2)
        lpValues1(:,r) = offset(polyval(p1(:,r), lp(:,1)));
        lpValues2(:,r) = offset(polyval(p2(:,r), lp(:,2)));
        lpValues3(:,r) = offset(polyval(p3(:,r), lp(:,3)));
        if r < 4 && r ~= 2
            lpValues4(:,r) = offset(polyval(p4(:,r), lp(:,4)));
        end
    end
    
    lpValues4(:,2) = [];
    %mu = [4819.07121967553;82.6511269503711];
    %p4 = [-0.00271303197038322,-0.0265050717127049,-0.0860876554573797,-0.0693793958492654,0.162275673684280,0.324824621310463,0.204426859405091,0.347725190280539,5.34467391561030];
    p4 = [-8.14898838897599e-20;2.31385242074387e-15;-2.53901613238266e-11;1.16383850495194e-07;5.34327273544657e-05;-3.04408237969401;14004.5257169421;-28235882.0040511;22265113361.3903];
    lpValues4(:,end+1) = abs(offset(polyval(p4, lp(:,4))));
    lpValues1(:,end+1) = mean(abs(lpValues1),2);
    lpValues2(:,end+1) = mean(abs(lpValues2),2);
    lpValues3(:,end+1) = mean(abs(lpValues3),2);
    lpValues4(:,end+1) = mean(abs(lpValues4),2);
    
    lp(:,1) = lpValues1(:,end);
    lp(:,2) = lpValues1(:,end);
    lp(:,3) = lpValues1(:,end);
    lp(:,4) = lpValues1(:,end);
    lp(:,5) = (offset(lpValues1(:, end)) + offset(lpValues3(:,end)))/2;
    lp(:,6) = (offset(lpValues2(:, end)) + offset(lpValues4(:,end)))/2;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESS IMU DATA                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if processIMU == true
    %Convert all DAQ recorded ADC voltages to time in units of milliseconds
    disp('Converting DAC output into time data...');
    for r = 1:1:length(A)
        DACTime(r,1) = convertDACToTime([A(r) B(r) C(r) D(r) E(r) F(r) G(r) H(r)]);
    end
    disp('Process complete.');

    %Associate timestamp data outputted from DAC with DAQ time data. This is
    %done by taking DACTime, cleaning it up, and then outputting what row of
    %IMU data variables correspondes with each row of NormTime data from the
    %DAQ.
    disp('Obtaining indexes of data to relate IMU time to DAQ time...');
    DACTimeIndex = associateDACTime(DACTime, MilliTime);
    disp('Process complete.');

    %Produce IMU data with time in sync with DAQ time. This outputs yaw,
    %pitch, and roll, respectively, for both IMUs in units of radians.
    %Yaw (aLPha) (CC Z Axis)
    %Pitch (beta) (CC Y Axis)
    %Roll (gamma) (CC X Axis)
    IMUA = [anglesA(DACTimeIndex,1) anglesA(DACTimeIndex,2) anglesA(DACTimeIndex,3)];
    IMUB = [anglesB(DACTimeIndex,1) anglesB(DACTimeIndex,2) anglesB(DACTimeIndex,3)];    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE ROTATION USING WIREPOT DATA                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessBeamRotation == true
    %Define initial gamma angle to compare again.
    beamInitialAngle1 = mean(wpAngles(1:50,3)); %Initial angle top of beam
    beamInitialAngle2 = mean(wpAngles(1:50,6)); %Initial angle bot of beam
    beamInitialAngle3 = mean(wpAngles(1:50,9)); %Initial angle of pivot rod
    beamInitialAngle5 = mean(wpAngles(1:50,14)); %Initial angle top of beam
    beamInitialAngle6 = mean(wpAngles(1:50,17)); %Initial angle of bot rod
    
    %Determine the initial slope of the triangles' median (midpoint of
    %length c to vertex C). This is done so that later the current slope
    %can be found and relating slope to tangent the change in angle during
    %rotation can be determined.
    
    %Slope beam instrument grouping 1 (closest to ceiling)
    m11 = (wp(1,7)*sin(mean(wpAngles(1:50,2))) - 0)/(wp(1,7)*cos(mean(wpAngles(1:50,2))) - D1/2);
    
    %Slope beam instrument grouping 2 (closest to ceiling)
    m12 = (wp(1,2)*sin(mean(wpAngles(1:50,5))) - 0)/(wp(1,2)*cos(mean(wpAngles(1:50,5))) - D2/2);
    
    %Slope beam instrument grouping 3 (for wirepots at the pivot rod.)
    m13 = (wp(1,6)*sin(mean(wpAngles(1:50,8))) - 0)/(wp(1,6)*cos(mean(wpAngles(1:50,8))) - 2);
    
    %Slope beam instrument grouping 2 (closest to floor)
    m15 = (wp(1,3)*sin(mean(wpAngles(1:50,14))) - 0)/(wp(1,3)*cos(mean(wpAngles(1:50,14))) - D5/2);
    
    %Slope beam instrument grouping 2 (closest to floor)
    m16 = (wp(1,13)*sin(mean(wpAngles(1:50,17))) - 0)/(wp(1,13)*cos(mean(wpAngles(1:50,17))) - D6/2);
    
    %Compare current angle between sides a & b (angle gamma) to the
    %initial angle.
    beamRotation(:,1) = wpAngles(:, 3) - beamInitialAngle1;
    beamRotation(:,2) = wpAngles(:, 6) - beamInitialAngle2;
    beamRotation(:,3) = wpAngles(:, 9) - beamInitialAngle3;
    beamRotation(:,4) = wpAngles(:, 14) - beamInitialAngle5;
    beamRotation(:,5) = wpAngles(:, 17) - beamInitialAngle6;
    
    %Current slope of the triangle median for the top of the beam,
    %bottom of the beam, and pivot rod, bottom group 1 and bottom
    %group 2, respectively.
    m21 = (wp(:,7).*sin(wpAngles(:,2)) - 0)./(wp(:,7).*cos(wpAngles(:,2)) - D1/2);
    m22 = (wp(:,2).*sin(wpAngles(:,5)) - 0)./(wp(:,2).*cos(wpAngles(:,5)) - D2/2);
    m23 = (wp(:,6).*sin(wpAngles(:,8)) - 0)./(wp(:,6).*cos(wpAngles(:,8)) - 2);
    m25 = (wp(:,3).*sin(wpAngles(:,14)) - 0)./(wp(:,3).*cos(wpAngles(:,14)) - D5/2);
    m26 = (wp(:,13).*sin(wpAngles(:,17)) - 0)./(wp(:,13).*cos(wpAngles(:,17)) - D6/2);
    
    %Calculate the angle between the initial and current median for the
    %top of the beam, bottom of the beam, and pivot rod, bottom group 1
    %and bottom group 2, respectively.
    beamRotation(:,6)  = atan2((m21 - m11),(1 + m11*m21));
    beamRotation(:,7)  = atan2((m22 - m12),(1 + m12*m22));
    beamRotation(:,8)  = atan2((m23 - m13),(1 + m13*m23));
    beamRotation(:,9)  = atan2((m25 - m15),(1 + m15*m25));
    beamRotation(:,10) = atan2((m26 - m16),(1 + m16*m26));
    
    %Use vectors to determine total rotation of beam
    %For top wirepot groups
    Vi = [x3Glo(1,1)-x3Glo(1,2) y3Glo(1,1)-y3Glo(1,2)];
    V = [x3Glo(:,1)-x3Glo(:,2) y3Glo(:,1)-y3Glo(:,2)];
    
    VDot(:,1) = dot(repmat(Vi,size(V,1),1), V, 2);
    ViMag = sqrt(Vi(1)^2 + Vi(2)^2);
    VMag(:,1) = sqrt(V(:,1).^2 + V(:,2).^2);
    beamRotation(:,11) = acos(VDot./(ViMag * VMag));
    
    %For bottom wirepot groups
    clearvars Vi V VDot ViMag VMag;
    Vi = [x3Glo(1,3)-x3Glo(1,4) y3Glo(1,3)-y3Glo(1,4)];
    V = [x3Glo(:,3)-x3Glo(:,4) y3Glo(:,3)-y3Glo(:,4)];
    
    VDot(:,1) = dot(repmat(Vi,size(V,1),1), V, 2);
    ViMag = sqrt(Vi(1)^2 + Vi(2)^2);
    VMag(:,1) = sqrt(V(:,1).^2 + V(:,2).^2);
    beamRotation(:,12) = acos(VDot./(ViMag * VMag));
    
    %Use Horn's Method to calculate rotation and also get COR from this.
    %See 
    %http://people.csail.mit.edu/bkph/papers/Absolute_Orientation.pdf
    %and
    %http://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method
    
    %Init posistion
    pointsA = [[x3Glo(1,1); y3Glo(1,1)] [x3Glo(1,2); y3Glo(1,2)]]; 
    pointsA2 = [[x3Glo(1,3); y3Glo(1,3)] [x3Glo(1,4); y3Glo(1,4)]];
    
    for r = 1:1:size(wp,1);
        %Current Position
        pointsB = [[x3Glo(r,1); y3Glo(r,1)] [x3Glo(r,2); y3Glo(r,2)]];
        pointsB2 = [[x3Glo(r,3); y3Glo(r,3)] [x3Glo(r,4); y3Glo(r,4)]];
        
        rotInfo(r) = absor(pointsA, pointsB);
        rotInfo2(r) = absor(pointsA2, pointsB2);
        
        %With the translation and rotation matrix from absor() we know that
        %COR=R*x + t describes the center of rotation if we find a point on
        %X that does not change. Matrix backsolving gives us x = (eye(2) -
        %R)\t.
        %beamCOR(r,1:2) = (eye(2)-rotInfo(r).R)\rotInfo(r).t;
        %beamCOR(r,2:4) = (eye(2)-rotInfo2(r).R)\rotInfo2(r).t;
    end 
    
    tempVar = [rotInfo(:).theta].';
    tempVar2 = [rotInfo2(:).theta].';
    
    [row1, col1] = find(tempVar > 1);
    [row2, col2] = find(tempVar2 > 1);
    
    beamRotation(:,13) = tempVar;
    beamRotation(:,14) = tempVar2;
    
    beamRotation(row1,13) = beamRotation(row1,13) - 360;
    beamRotation(row2,14) = beamRotation(row2,14) - 360;

    
    clearvars m11 m12 m13 m15 m16 m21 m22 m23 m25 m26 beamInitialAngle1 beamInitialAngle2 beamInitialAngle3 beamInitialAngle5 beamInitialAngle6 Vi V VDot ViMag VMag pointsA pointsB tempVar pointsA2 pointsB2 tempVar2;
    disp('Beam rotations calculated.. Appending to data file.');
    if localAppend == true
        save(ProcessFileName, 'beamRotation', '-append');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESS STRAIN PROFILES                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessStrainProfiles == true
    %Calculate lines using linear regression.
    if ProcessShearTab == '2' || ProcessShearTab == '4'
        yLocation   = [[1; 1; 1; 1] yGaugeLocations(1:4)];
        yLocation2  = [[1; 1; 1; 1; 1] yGaugeLocations(1:5)];
        gauges      = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3)), offset(sg(:,4))];
        gauges2     = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3)), offset(sg(:,4)), offset(sg(:,5))];
    else
        yLocation   = [[1; 1; 1] yGaugeLocations(1:3)];
        yLocation2  = [[1; 1; 1; 1] yGaugeLocations(1:4)];
        gauges      = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3))];
        gauges2     = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3)), offset(sg(:,4))];
    end

    %Total strain profile w/o BFFD
    strainRegression = procStrainProfiles(yLocation,gauges);
    
    %Total strain profile w/ BFFD
    strainRegression = [strainRegression procStrainProfiles(yLocation2,gauges2)];
    
    disp('Strain profiles calculated. Appending data to file and removing garbage');
    clearvars yLocation yLocation2 gauges gauges2;
    if localAppend == true
        save(ProcessFileName, 'strainRegression', '-append');
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESS FORCES FROM STRAIN GAUGES ON TEST SPECIMAN                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessForces == true
    %Force prefix values for shear tabs 1 & 2. See derivation below.
    forcePrefix1 = modulus*gaugeWidth(1)*gaugeLength(1);
    
    %Force prefix values for shear tabs 3 & 4. See derivation below.
    forcePrefix2 = modulus*gaugeWidth(2)*gaugeLength(2);
    
    for i = 1:1:size(sg,2)
        %Shear tab forces and column flange friction device
        
        %Pull strain from regression data w/o BFFD (sgReg) and w/ BFFD
        %(sgRegBFFD)
        
        %In the consolidation process for strain gauges the first 3 or 4
        %strain values are for the gauges at the bolt holes while the last
        %is the bolt hole for the BFFD/CFFC. Checking that we are less than
        %or equal to  yGaugeLocations assures that we are not improperly
        %processing column flange or intrumented bolt forces since
        %yGaugeLocations changes depending on the shear tab number.
        if i <= size(yGaugeLocations,1)
            %Looks at each strain gauge & also interpolate edges.
            for s = 1:1:size(yGaugeLocationsExpanded,1)
                %Determines strain at each strain gauge location using
                %linear regression.
                for t = 1:1:size(strainRegression,1)
                    %Strain value for shear tab only
                    sgReg(t,s)     = strainRegression(t,1) + strainRegression(t,2)*yGaugeLocationsExpanded(s);
                    %Bending strain value for shear tab only
                    sgRegBend(t,s)     = strainRegression(t,4) + strainRegression(t,5)*yGaugeLocationsExpanded(s);
                    %Strain value for shear tab and BFFD/CFFD together.
                    sgRegBFFD(t,s) = strainRegression(t,8) + strainRegression(t,9)*yGaugeLocationsExpanded(s);
                end
            end
        end
        
        %F/A = Ee
        %A = W*L
        %L = e*L1 + L1
        %F = AEe
        %F = W*(e*L1 + L1)*E*e
        %F = W*(e^2 + e)L1*E
        %- force calculates force using raw strain gauge data
        %- forceReg calcs force using linear regression of shear tab only
        %- forceBFFD calcs force using linear regression of shear tab and
        %  BFFD/CFFD
        if (ProcessShearTab == '1' && i <= 4) || (ProcessShearTab == '2' && i <= 5)
            force(:,i)        =  forcePrefix1*((sg(:,i)*10^-6).^2 + (sg(:,i)*10^-6));
            forceReg(:,i)     =  forcePrefix1*(sgReg(:,i).^2 + sgReg(:,i));
            forceRegBend(:,i) =  forcePrefix1*(sgRegBend(:,i).^2 + sgRegBend(:,i));
            forceRegBFFD(:,i) =  forcePrefix1*(sgRegBFFD(:,i).^2 + sgRegBFFD(:,i));
        end
        if (ProcessShearTab == '3' && i <= 4) || (ProcessShearTab == '4' && i <= 5)
            force(:,i)        =  forcePrefix2*((sg(:,i)*10^-6).^2 + (sg(:,i)*10^-6));
            forceReg(:,i)     =  forcePrefix2*(sgReg(:,i).^2 + sgReg(:,i));
            forceRegBend(:,i) =  forcePrefix2*(sgRegBend(:,i).^2 + sgRegBend(:,i));
            forceRegBFFD(:,i) =  forcePrefix2*(sgRegBFFD(:,i).^2 + sgRegBFFD(:,i));
        end
        
        %Force in strain instrumented bolt using equation relating strain
        %to force. Bolt equation defined as a system variable at beginning
        %of the script.
        if ((ProcessShearTab == '2' || ProcessShearTab == '4') && i == 6) || ((ProcessShearTab == '1' || ProcessShearTab == '2') && i == 5);
            force(:,i)        = boltEquation*sg(:,i);
        end
        
        %Calculate force at strain gauges on inner column flanges. Note
        %that the derivation for this equation is the same for the force
        %equation used on the shear tabs and BFFD/CFFD. These gauges are
        %the same type as those used on ST3 & ST4 which allows the re-use
        %of prefix
        if ((ProcessShearTab == '2' || ProcessShearTab == '4') && i > 6) || ((ProcessShearTab == '1' || ProcessShearTab == '2') && i > 5)
            force(:,i)        =  forcePrefix2*((sg(:,i)*10^-6).^2 + (sg(:,i)*10^-6));
        elseif ((ProcessShearTab == '1' || ProcessShearTab == '2') && i > 5)
            force(:,i)        =  forcePrefix2*((sg(:,i)*10^-6).^2 + (sg(:,i)*10^-6));
        end
        
    end
end

%{
if ProcessShearTab == '2' || ProcessShearTab == '4'
    gaugeRange = 2:5;
    gaugeRangeExt = 1:6;
else
    gaugeRange = 2:4;
    gaugeRangeExt = 1:5;
end

variableList = {'sgReg(:,gaugeRange)', 'sgRegBend(:,gaugeRange)', 'sgRegBFFD(:,gaugeRange)', 'sgReg(:,gaugeRangeExt)', 'sgRegBend(:,gaugeRangeExt)', 'sgRegBFFD(:,gaugeRangeExt)'};

for q = 1:1:length(variableList)
    
    variableTemp = eval(variableList{q});
    
    for r = 1:1:size(variableTemp,1)

        A = variableTemp(r, :);

        if all(A > 0)
            %Axial tension force
            parity(r,q) = 1;
        elseif all(A < 0)
            %Axial compression force
            parity(r,q) = -1;
        else
            %Should be a moment
            parity(r,q) = 0;
        end
    end
end
%}

if ProcessMoments == true
    %Generate strain gauge width increments
    strainIncrement            = (stMidHeight:-gaugeWidth:0).';
    strainIncrement(end+1,1)   = 0;
    strainIncrement(end:end+(length(strainIncrement)-1),1) = -flipud(strainIncrement).';
    
    %Sign convention followed is standard counter-clockwise positive,
    %clockwise negative. If this were a beam, positive on the right side
    %would be counter-clockwise with shear force up while negative on the
    %left being clockwise with shear force down.
    
    if ProcessShearTab == '2' || ProcessShearTab == '4'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Moments calculated using SG data %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%% Moment at center of the shear tab %%%
        
        %Not including BFFD
        moment(:,1) = force(:,1)*yGaugeLocations(1) + force(:,2)*yGaugeLocations(2);
        moment(:,2) = force(:,3)*abs(yGaugeLocations(3)) + force(:,4)*abs(yGaugeLocations(4));
        moment(:,3) = moment(:,1) + moment(:,2);
        
        %Including BFFD
        moment(:,4) = force(:,5)*abs(yGaugeLocations(5));
        moment(:,5) = moment(:,3) + moment(:,4);
        
        %%% Moment at COR (COR calculated using strain gauges) %%%
        
        %Not Implented yet. May not be needed due to small change in COR.
        %An alternative would be to do moment at center of force
        %distribution.
        
        %Moment at center of ST calculated using SG regression data and
        %intergrating over area.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        
        
        
        %Moment integrating strain linear regression across shear table only
        momentReg(:,1) = -(2/3)*stMidHeight*modulus*(sgReg(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,2) = (2/3)*stMidHeight*modulus*(sgReg(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,3) = momentReg(:,1) + momentReg(:,2);
        
        %Bending moment integrating strain linear regression across ST only
        momentRegBend(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBend(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,2) = (2/3)*stMidHeight*modulus*(sgRegBend(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,3) = momentRegBend(:,1) + momentRegBend(:,2);
        
        %Moment integrating strain linear regression across ST and BFFD/CFFD
        momentRegBFFD(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBFFD(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,2) = (2/3)*stMidHeight*modulus*(sgRegBFFD(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,3) = momentRegBFFD(:,1) + momentRegBFFD(:,2);
        
        % Moment at centroid of strain calculated using SG regression data
        % and integrating over area. INCOMPLETE
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Moment integrating strain linear regression across shear tab only
        momentReg(:,1) = -(2/3)*stMidHeight*modulus*(sgReg(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,2) = (2/3)*stMidHeight*modulus*(sgReg(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,3) = momentReg(:,1) + momentReg(:,2);
        
        %Bending moment integrating strain linear regression across ST only
        momentRegBend(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBend(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,2) = (2/3)*stMidHeight*modulus*(sgRegBend(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,3) = momentRegBend(:,1) + momentRegBend(:,2);
        
        %Moment integrating strain linear regression across ST and BFFD/CFFD
        momentRegBFFD(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBFFD(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,2) = (2/3)*stMidHeight*modulus*(sgRegBFFD(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,3) = momentRegBFFD(:,1) + momentRegBFFD(:,2);
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Moments calculated using LC Data %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        distG1 = (29+(11/16)); %Dist from center of LC G1 to column face
        distG2 = (29+(7/16)); %Dist from center of LC G2 to column face
        %Middle of shear tab at column flange face
        
        %Unadjusted due to rotation. From roller to column flange
        moment(:,6) = lc(:,7)*distG2 - lc(:,6)*distG1;
        
        %Adjust due to rotation changing distance from roller to col. face
        %Method 1: Using average from linear potentiometers.
        %moment(:,7) = lc(:,7)*distG2 - lc(:,6)*distG1;
        %Method 2: Using beam rotation from wire-pot group 3.
        x1 = mean([2*wp41Pos(2).*sin((beamRotation(:,3)/10)/2) 2*wp21Pos(2).*sin((beamRotation(:,3)/10)/2)],2);
        x2 = mean([2*wp42Pos(2).*sin((beamRotation(:,3)/10)/2) 2*wp22Pos(2).*sin((beamRotation(:,3)/10)/2)],2);
        moment(:,7) = lc(:,7).*(distG2-x2) - lc(:,6).*(distG1-x1);
         
        %Need to implement. Will require measuring distance from center of
        %LCs to column. Will also have to take into count translation of
        %the beam/column.
    end
    clearvars gaugeLength gaugeWidth stMidHeight x topLength botLength strainTop strainTop1 strainBot strainBot1 elongationTop elongationTop1 elongationBot elongationBot1 x1 x2
    if localAppend == true
        save(ProcessFileName, 'moment', '-append');
    end
    %}
end

if ProcessEQM == true
    x1 = 48;
    x2 = 36;
    x3 = (29+(11/16));
    x4 = (29+(7/16));
    
    eqm(:,1) = (lc(:,6)*x3 - lc(:,7)*x4)/(x1 + x2);
    eqm(:,2) = lc(:,6) - lc(:,7);
    eqm(:,3) = -lc(:,5);
    eqm(:,4) = lc(:,5)*x1 - lc(:,6)*x3 + lc(:,7)*x4 - eqm(:,3)*x2;
    eqm(:,5) = -lc(:,5)*x1 + lc(:,6)*x3 - lc(:,7)*x4 + eqm(:,3)*x2;
end

%{
plot3(NormTime, repmat(strainIncrement,1,57046),  strainProf)
hold
scatter3(NormTime, repmat(xLocation(1,2),57046,1), (10^-6)*offset(sg(:,1)))
scatter3(NormTime, repmat(xLocation(2,2),57046,1), (10^-6)*offset(sg(:,2)))
scatter3(NormTime, repmat(xLocation(3,2),57046,1), (10^-6)*offset(sg(:,3)))
scatter3(NormTime, repmat(xLocation(4,2),57046,1), (10^-6)*offset(sg(:,4)))
%}
if ProcessOutputPlots == true
    r1 = 2000;
    r2 = length(sg);
    %Check if folder to save these in exists and create folder if it doesnt
    if exist(fullfile('..\',ProcessCodeName)) == 0
        mkdir('..\',ProcessCodeName);
    end
    
    %Strain gauge array positions change depending on shear tab. this
    %assures that the correct column strain gauges are plotted as desired.
    if ProcessShearTab == '2' || ProcessShearTab == '4'
        plotArrayCol = [offset(sg(r1:r2,7)) offset(sg(r1:r2,8)) offset(sg(r1:r2,9)) offset(sg(r1:r2,10))];
    else
        plotArrayCol = [offset(sg(r1:r2,6)) offset(sg(r1:r2,7)) offset(sg(r1:r2,8)) offset(sg(r1:r2,9))];
    end

    %%%% Strain Gauges %%%%
    disp('Plotting strain gauge data');
    smartPlot(NormTime(r1:r2), [sg(r1:r2,1) sg(r1:r2,2) sg(r1:r2,3) sg(r1:r2,4)], ...
        'Strain Gauge Data on Shear Tab', 'Time (sec)', 'Strain (uStrain)', ...
        'legend', {'SG1','SG2','SG3','SG4'}, 'visible', 'grid', 'save', 'sg-st');
    
    smartPlot(NormTime(r1:r2), [offset(sg(r1:r2,1)) offset(sg(r1:r2,2)) offset(sg(r1:r2,3)) offset(sg(r1:r2,4))], ...
        'Offset Strain Gauge Data on Shear Tab', 'Time (sec)', 'Strain (uStrain)', ...
        'legend', {'SG1','SG2','SG3','SG4'}, 'visible', 'grid', 'save', 'sg-st-offset');
    
    smartPlot(NormTime(r1:r2), plotArrayCol, ...
        'Offset Column Strain Gauges', 'Time (sec)', 'Strain (uStrain)', ...
        'legend', {'SG19','SG20','SG21','SG22'}, 'visible', 'grid', 'save', 'sg-col-offset');
    
    %%%% Load Cells %%%%
    disp('Plotting load cell data');
    smartPlot(NormTime(r1:r2), [lc(r1:r2,1) lc(r1:r2,2) lc(r1:r2,3) lc(r1:r2,4)], ...
        'Reaction Block Load Cells', 'Time (sec)', 'Force (lbf)', ...
        'legend', {'LC1','LC2','LC3','LC4'}, 'grid', 'visible', 'save', 'lc');
    
    smartPlot(NormTime(r1:r2), [offset(lc(r1:r2,1)) offset(lc(r1:r2,2)) offset(lc(r1:r2,3)) offset(lc(r1:r2,4))], ...
        'Offset Reaction Block Load Cells', 'Time (sec)', 'Force (lbf)', ...
        'legend', {'LC1','LC2','LC3','LC4'}, 'visible', 'grid', 'save' ,'lc-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lc(r1:r2,1)) offset(lc(r1:r2,2)) offset(lc(r1:r2,3)) offset(lc(r1:r2,4)), offset(lc(r1:r2,5))], ...
        'Offset All Load Cells', 'Time (sec)', 'Force (lbf)', ...
        'legend', {'LC1','LC2','LC3','LC4','MTSLC'}, 'visible', 'grid', 'save', 'lc-all-offset');
    
    smartPlot(NormTime(r1:r2), offset(lc(r1:r2,5)), ...
        'Offset Actuator LC', 'Time (sec)', 'Force (lbf)', 'visible', ...
        'grid', 'save', 'lc-actuator-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lc(r1:r2,6)) offset(lc(r1:r2,7))], ...
        'Offset Rxn Block Load Cell Groups', 'Time (sec)', 'Force (lbf)', ...
        'legend', {'LC G1','LC G2'}, 'visible', 'grid', 'save', 'lc-groups-offset');
    
    %%%% Angles %%%%
    disp('Plotting rotation data');
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,1), 'WP Group 1 Rotation (Method 1)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-g1-method1-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,2), 'WP Group 2 Rotation (Method 1)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-g2-method1-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,1) beamRotation(r1:r2,2)], ...
        'WP Group 1 & 2 Rotation (Method 1)', 'Time (sec)', ...
        'Rotation (rad)', 'grid', 'legend', {'G1 (Top)', 'G2 (Bottom)'}, ...
        'visible', 'save', 'rotation-g12-method1-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,4), 'WP Group 1 Rotation (Method 2)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-g1-method2-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,2), 'WP Group 2 Rotation (Method 2)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-g2-method2-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,4) beamRotation(r1:r2,5)], ...
        'WP Group 1 & 2 Rotation (Method 2)', 'Time (sec)', ...
        'Rotation (rad)', 'grid', 'legend', {'G1 (Top)', 'G2 (Bottom)'}, ...
        'visible', 'save', 'rotation-g12-method2-offset');
    
    %%%% Wire-pots %%%%
    disp('Plotting wire-pot data');
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,7)) offset(wp(r1:r2,3)) offset(wp(r1:r2,1)) offset(wp(r1:r2,12))], ...
        'Offset Wirepot Group 1', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP4-1','WP2-1','WP1-1','WP7-1'},  'visible', 'grid', 'save', 'wp-g1-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,8)) offset(wp(r1:r2,4)) offset(wp(r1:r2,2)) offset(wp(r1:r2,13))], ...
        'Offset Wirepot Group 2', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP4-2','WP2-2','WP1-2','WP7-2'}, 'visible', 'grid', 'save', 'wp-g2-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,1)) offset(wp(r1:r2,2))], ...
        'Offset Vertical Wirepots', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP1-1','WP1-2'}, 'visible', 'grid', 'save', 'wp-vert-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,7)) offset(wp(r1:r2,8))], ...
        'Offset Horizontal Wirepots (Top Flange)', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP4-1','WP4-2'}, 'visible', 'grid', 'save', 'wp-horztop-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,3)) offset(wp(r1:r2,4))], ...
        'Offset Horizontal Wirepots (Bottom Flange)', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP2-1','WP2-2'}, 'visible', 'grid', 'save', 'wp-horzbot-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,7)) offset(wp(r1:r2,3)) offset(wp(r1:r2,1)) ...
        offset(wp(r1:r2,8)) offset(wp(r1:r2,4)) offset(wp(r1:r2,2)) offset(wp(r1:r2,12)) offset(wp(r1:r2,13))], ...
        'Offset All Beam Rotation Wirepots', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP4-1','WP2-1','WP1-1','WP4-2','WP2-2','WP1-2','WP7-1','WP7-2'}, ...
        'visible', 'grid', 'save', 'wp-allrot-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,10)) offset(wp(r1:r2,11))], ...
        'Offset Wirepots Measuring Twist in Column', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP6-1','WP6-2'}, 'visible', 'grid', 'save', 'wp-twist-offset');
    
    %%%% Linear Potentiometers %%%%
    disp('Plotting linear potentiometer data');
    smartPlot(NormTime(r1:r2), [offset(lpValues1(r1:r2,end))], ...
        'Offset Linear Potentiometer 1', 'Distance (in.)', ...
        'Time (Sec.)', 'visible', 'grid', 'save', 'lp-1-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues2(r1:r2,end))], ...
        'Offset Linear Potentiometer 2', 'Distance (in.)', ...
        'Time (Sec.)', 'visible', 'grid', 'save', 'lp-2-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues3(r1:r2,end))], ...
        'Offset Linear Potentiometer 3', 'Distance (in.)', ...
        'Time (Sec.)', 'visible', 'grid', 'save', 'lp-3-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues4(r1:r2,end))], ...
        'Offset Linear Potentiometer 4', 'Distance (in.)', ...
        'Time (Sec.)', 'visible', 'grid', 'save', 'lp-4-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues1(r1:r2,end)) offset(lpValues2(r1:r2,end))], ...
        'Offset Linear Potentiometer 1 & 2', 'Time (sec)', 'Length (in)', ...
        'legend', {'LP1','LP2'}, 'visible', 'grid', 'save', 'lp-12-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues3(r1:r2,end)) offset(lpValues4(r1:r2,end))], ...
        'Offset Linear Potentiometer 3 & 4', 'Time (sec)', 'Length (in)', ...
        'legend', {'LP3','LP4'}, 'visible', 'grid', 'save', 'lp-34-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues1(r1:r2,end)) offset(lpValues3(r1:r2,end))], ...
        'Offset Linear Potentiometer 1 & 3', 'Time (sec)', 'Length (in)', ...
        'legend', {'LP1','LP3'}, 'visible', 'grid', 'save', 'lp-13-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues2(r1:r2,end)) offset(lpValues4(r1:r2,end))], ...
        'Offset Linear Potentiometer 2 & 4', 'Time (sec)', 'Length (in)', ...
        'legend', {'LP2','LP4'}, 'visible', 'grid', 'save', 'lp-24-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lp(r1:r2,5)) offset(lp(r1:r2,6))], ...
        'Offset Linear Potentiometer Averages', 'Time (sec)', 'Length (in)', ...
        'legend', {'LP1&2','LP3&4'}, 'visible', 'grid', 'save', 'lp-avg-offset');
    
    smartPlot(NormTime(r1:r2), [offset(lpValues1(r1:r2,end)) offset(lpValues2(r1:r2,end)) offset(lpValues1(r1:r2,end)) offset(lpValues2(r1:r2,end))], ...
        'Offset Linear Potentiometer 2 & 4', 'Time (sec)', 'Length (in)', ...
        'legend', {'LP1','LP2','LP3','LP4'}, 'visible', 'grid', 'save', 'lp-all-offset');
    
    %%%% Hysteresis %%%%
    disp('Plotting hysteresis data');
    smartPlot(beamRotation(r1:r2,1), moment(r1:r2,6), ...
        'Offset Hysteresis Using WP Group 1 (Method 1)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-g11-offset');
    
    smartPlot(beamRotation(r1:r2,4), moment(r1:r2,6), ...
        'Offset Hysteresis Using WP Group 1 (Method 2)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-g12-offset');
    
    smartPlot(beamRotation(r1:r2,2), moment(r1:r2,6), ...
        'Offset Hysteresis Using WP Group 2 (Method 1)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-g21-offset');
    
    smartPlot(beamRotation(r1:r2,5), moment(r1:r2,6), ...
        'Offset Hysteresis Using WP Group 2 (Method 2)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-g22-offset');
    
    smartPlot(beamRotation(r1:r2,3), moment(r1:r2,6), ...
        'Offset Hysteresis Using WP Group 3 (Method 1)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-g31-offset');
    
    smartPlot(beamRotation(r1:r2,6), moment(r1:r2,6), ...
        'Offset Hysteresis Using WP Group 3 (Method 2)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-g32-offset');
end

%{
%Numerically stable Heron's Formula to get area and from there height.
    %requires sorting so that a >= b >= c.
    lengthOfWPArray = size(wp,1);
    
    %WP Set 1
    wp1Set      = [wp(:,1) wp(:,7) repmat(D1, [lengthOfWPArray, 1])];
    wpArea(:,1) = heronsFormula(wp1Set);
    %WP Set 2
    wp2Set      = [wp(:,2) wp(:,8) repmat(D2, [lengthOfWPArray, 1])];
    wpArea(:,2) = heronsFormula(wp2Set);
    %WP Set 3
    wp3Set      = [wp(:,6) wp(:,5) repmat(D3, [lengthOfWPArray, 1])];
    wpArea(:,3) = heronsFormula(wp3Set);
    %WP Set 4
    % wp4cDist = sqrt(wp(50,7)^2 + wp(50,1)^2);
    %wpArea(:,4) = heronsFormula([wp(:,12) wp(:,9) repmat(wp4cDist, [lengthOfWPArray, 1])]);
    %WP Set 5
    wp5Set      = [wp(:,3) wp(:,12) repmat(D5, [lengthOfWPArray, 1])];
    wpArea(:,5) = heronsFormula(wp5Set);
    %WP Set 6
    %Not implemented yet
    
    %Calculate heigh of triangle (line perp to line c extending to vertext
    %c)
    wpHeight = 2.*[wpArea(:,1)./wp1Set(:,3) ...
                   wpArea(:,2)./wp2Set(:,3) ...
                   wpArea(:,3)./wp3Set(:,3) ...
                   repmat(0, [lengthOfWPArray, 1]) ...
                   wpArea(:,5)./wp5Set(:,3) ...
                  ]; 
    
    %Get d, the distance from A to line segment h along line c (A on left
    %hand side)
    wpd2 = [(-wp1Set(:,1).^2 + wp1Set(:,2).^2 + wp1Set(:,3).^2)./(2.*wp1Set(:,3))];
    wpd = [sqrt(wp1Set(:,2).^2 - wpHeight(:,1).^2) ...
           sqrt(wp2Set(:,2).^2 - wpHeight(:,2).^2) ...
           sqrt(wp3Set(:,2).^2 - wpHeight(:,3).^2) ...
           repmat(0, [lengthOfWPArray, 1]) ...
           sqrt(wp5Set(:,2).^2 - wpHeight(:,5).^2) ...
          ];
   
    %Get coordinates of vertex C on wire pot triangles. Method used as
    %detailed at http://paulbourke.net/geometry/circlesphere/ under
    %"Intersection of two circles" written by Paul Bourke, 1997
    
    xd31 = (D1 - wpd(:,1)).*sin(wpAngles(:,2));
    yd31 = (D1 - wpd(:,1)).*cos(wpAngles(:,2));
    
    x311 = yd31 + wpHeight(:,1).*((wp41Pos(2) - wp11Pos(2))./D1);
    x312 = yd31 - wpHeight(:,1).*((wp41Pos(2) - wp11Pos(2))./D1);
    
    y311 = wpHeight(:,1) + wpHeight(:,1).*((wp41Pos(2) - wp11Pos(2))./D1);
    y312 = wpHeight(:,1) - wpHeight(:,1).*((wp41Pos(2) - wp11Pos(2))./D1);
    wpx = [];
    wpy = [];
%}