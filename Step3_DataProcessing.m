clc
close all
clear

format long;
s
global ProcessRealName %So we can pick this up in function calls
global ProcessCodeName %So we can pick this up in function calls
global ProcessFileName %So we can pick this up in function calls
global ProcessFilePath  %So we can pick this up in function calls

%Process Mode Variables
ProcessFilePath              = 'C:\Users\clk0032\Dropbox\Friction Connection Research\Full Scale Test Data\FS Testing -ST1 - 06-27-16\';
ProcessFileName              = 'FS Testing - ST1 - Test 6 - 06-27-16';
ProcessRealName              = 'Full Scale Test 3 - ST1 - 05-24-16';
ProcessCodeName              = 'FST-ST2-May20-2';
ProcessShearTab              = '1'; %1, 2, 3, or 4
runParallel                  = true;
localAppend                  = true;
ProcessConsolidateSGs        = true;
ProcessConsolidateWPs        = true;
ProcessConsolidateLPs        = true;
ProcessConsolidateLCs        = true;
ProcessWPAngles              = true;
ProcessWPPropeties           = true;
ProcessWPCoords              = true;
ProcessSlip                  = false;%true;
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

%Load coordinates of wire-pots. See "help wpPosition" for more information
%on wirepot coordinates/scheme. The following lines essentially take the
%output of that function and assign it to easily read variable names.
wpPos = wpPosition(ProcessFileName);

wp11Pos = wpPos(1,:);
wp12Pos = wpPos(2,:);
wp21Pos = wpPos(3,:);
wp22Pos = wpPos(4,:);
wp31Pos = wpPos(5,:);
wp32Pos = wpPos(6,:);
wp41Pos = wpPos(7,:);
wp42Pos = wpPos(8,:);
wp51Pos = wpPos(9,:);
wp52Pos = wpPos(10,:);
wp61Pos = wpPos(11,:);
wp62Pos = wpPos(12,:);
wp71Pos = wpPos(13,:);
wp72Pos = wpPos(14,:);

%Get distances between wirepot triangle vertices A and B (line c).
D1 = DF(wp41Pos(1,1), wp11Pos(1,1), wp41Pos(1,2), wp11Pos(1,2)); %Top group 1
D2 = DF(wp42Pos(1,1), wp12Pos(1,1), wp42Pos(1,2), wp12Pos(1,2)); %Bot group 1
D3 = 4; %WP group measuring bottom global position
D4 = (3 + (7/8)); %WP group measuring top global position
D5 = DF(wp21Pos(1,1), wp71Pos(1,1), wp21Pos(1,2), wp71Pos(1,2)); %Top group 2
D6 = DF(wp22Pos(1,1), wp72Pos(1,1), wp22Pos(1,2), wp72Pos(1,2)); %Bot group 2

%Basic constants
modulus      = 29000; %Modulus of elasticity (ksi)
boltEquation = 0.1073559499;
gaugeLength  = [0.19685; 0.450]; %(in) which is 5 mm
gaugeWidth   = [0.0590551; 0.180]; %(in) which is 1.5 mm

%Shear tab coordinate system and bolt hole location information.
if ProcessShearTab == '2' || ProcessShearTab == '4'
    stMidHeight = 5.75;
    yGaugeLocations = [4.5; 1.5; -1.5; -4.5; -10];
    yGaugeLocationsExpanded = [stMidHeight; 4.5; 1.5; -1.5; -4.5; -stMidHeight; -10];
else
    stMidHeight = 4.25;
    yGaugeLocations = [3; 0; -3; -9];
    yGaugeLocationsExpanded = [stMidHeight; 3; 0; -3; -stMidHeight; -9];
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
%Slightly faster to use cat() but this provides us with a name chart.
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
    wp(:,14) = wp52(:,1);
    wp       = wp + 2.71654;
    wp(:,15) = MTSLVDT(:,1);
    
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
    
    %If beam is in contact with LC at the beginning of the test a
    %compressive force is occuring that can sway data if not handled
    %properly. To account for this we find the peak of the LC data (which
    %occurs when the beam is not in contact with the the LC) and offset
    %data
    [maxtab1 mintab1] = peakdet(lc(:,1), 25);
    [maxtab2 mintab2] = peakdet(lc(:,2), 25);
    [maxtab3 mintab3] = peakdet(lc(:,3), 25);
    [maxtab4 mintab4] = peakdet(lc(:,4), 25);
    
    lc(:,6) = (LC1(:,1)-LC1(maxtab1(1,1)))+(LC2(:,1)-LC2(maxtab2(1,1)));
    lc(:,7) = (LC3(:,1)-LC3(maxtab3(1,1)))+(LC4(:,1)-LC4(maxtab4(1,1)));
    
    disp('Load cell variables successfully converted into one. Appending to file and removing garbage.')
    clearvars LC1 LC2 LC3 LC4 MTSLC maxtab1 mintab1  maxtab2 mintab2  maxtab3 mintab3  maxtab4 mintab4;
    if localAppend == true
        save(ProcessFileName, 'lc', '-append');
    end
    disp('File successfully appended.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE EACH ANGLE OF WIRE POTENTIOMETER TRIANGLES                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessWPAngles == true
    
    [wpAngles, wpAnglesDeg] = procWPAngles(wp(:,:), [D1, D2, D3, D4, D5, D6]);
    
    c1 = find(round(wpAngles(:,1) + wpAngles(:,2) + wpAngles(:,3),12) ~= round(pi,12));
    c2 = find(round(wpAngles(:,4) + wpAngles(:,5) + wpAngles(:,6),12) ~= round(pi,12));
    c3 = find(round(wpAngles(:,7) + wpAngles(:,8) + wpAngles(:,9),12) ~= round(pi,12));
    c4 = find(round(wpAngles(:,10) + wpAngles(:,11) + wpAngles(:,12),12) ~= round(pi,12));
    c5 = find(round(wpAngles(:,13) + wpAngles(:,14) + wpAngles(:,15),12) ~= round(pi,12));
    c6 = find(round(wpAngles(:,16) + wpAngles(:,17) + wpAngles(:,18),12) ~= round(pi,12));
    
    if all([c1, c2, c3, c4, c5, c6]) == 0
        error('Check angles for accuracy. Unable to verify all angles equal pi');
    end

    disp('Angles using non offset data calculated successfully. Appending to file (if localAppend = true) and removing garbage.')
    clearvars c1 c2 c3 c4 c5 c6
    
    if localAppend == true
        save(ProcessFileName, 'wpAngles', 'wpAnglesDeg', '-append');
        disp('Angles appended successfully.');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE VARIOUS PROPERTIES OF WIRE POT TRIANGLES                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessWPPropeties == true
    %Array to hold repmap'd length of line c on the triangles
    sizeOfWP = size(wp,1);
    dist = cat(2, repmat(D1, sizeOfWP, 1), repmat(D2, sizeOfWP, 1), ...
                  repmat(D3, sizeOfWP, 1), repmat(D4, sizeOfWP, 1), ...
                  repmat(D5, sizeOfWP, 1), repmat(D6, sizeOfWP, 1));
              
    %Define WP Groups in a, b, and c order
    g1 = [wp(:,7) wp(:,1) dist(:,1)];
    g2 = [wp(:,2) wp(:,8) dist(:,2)];
    g3 = [wp(:,5) wp(:,6) dist(:,3)];
    g4 = [wp(:,9) wp(:,14) dist(:,4)];
    g5 = [wp(:,3) wp(:,12) dist(:,5)];
    g6 = [wp(:,13) wp(:,4) dist(:,6)];
    
    %Calculate WP triangle areas
    wpArea = cat(2, heronsFormula(g1), heronsFormula(g2), heronsFormula(g3), heronsFormula(g4), heronsFormula(g5), heronsFormula(g6));
    
    %Calc distance from vertex A to point of the perpendicular base to apex
    d1 = (-1.*(g1(:,1).^2) +  g1(:,2).^2 + g1(:,3).^2)./(2.*g1(:,3));
    d2 = (-1.*(g2(:,1).^2) +  g2(:,2).^2 + g2(:,3).^2)./(2.*g2(:,3));
    d3 = (-1.*(g3(:,1).^2) +  g3(:,2).^2 + g3(:,3).^2)./(2.*g3(:,3));
    d4 = (-1.*(g4(:,1).^2) +  g4(:,2).^2 + g4(:,3).^2)./(2.*g4(:,3));
    d5 = (-1.*(g5(:,1).^2) +  g5(:,2).^2 + g5(:,3).^2)./(2.*g5(:,3));
    d6 = (-1.*(g6(:,1).^2) +  g6(:,2).^2 + g6(:,3).^2)./(2.*g6(:,3));
    
    wpd = cat(2, d1, d2, d3, d4, d5, d6);
    
    %Calculate WP triangle heights using area
    wpHeight = cat(2, (2.*(wpArea(:,1)./dist(:,1))),  (2.*(wpArea(:,2)./dist(:,2))),  (2.*(wpArea(:,3)./dist(:,3))),  (2.*(wpArea(:,4)./dist(:,4))),  (2.*(wpArea(:,5)./dist(:,5))),  (2.*(wpArea(:,6)./dist(:,6))));
    
    %Calculate WP triangle heights using the Pythagorean theorem since we
    %know the length of the perpendicular from the base to the apex (d).
    wpHeight2 = cat(2, sqrt(g1(:,2).^2 - wpd(:,1).^2), sqrt(g2(:,2).^2 - wpd(:,2).^2), ...
                       sqrt(g3(:,2).^2 - wpd(:,3).^2), sqrt(g4(:,2).^2 - wpd(:,4).^2), ...
                       sqrt(g5(:,2).^2 - wpd(:,5).^2), sqrt(g6(:,2).^2 - wpd(:,6).^2));
                   
    %Calculate Altitudes
    %Median
    %Angle bisector
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE COORDINATES OF WIREPOT STRINGS                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    
    %WP G5 at Top of Column (Global Positioning)
    %Using WP5-1
    x3Loc(:,5) = wp(:,9).*sin((pi/2) - wpAngles(:,10));
    x3Glo(:,5) = wp51Pos(1) + x3Loc(:,5);
    
    y3Loc(:,5) = wp(:,9).*cos((pi/2) - wpAngles(:,10));
    y3Glo(:,5) = wp51Pos(2) + y3Loc(:,5);
    
    %Using WP5-2
    x3Loc(:,6) = wp(:,14).*sin((pi/2) - wpAngles(:,11));
    x3Glo(:,6) = wp52Pos(1) + x3Loc(:,6);
    
    y3Loc(:,6) = wp(:,14).*cos((pi/2) - wpAngles(:,11));
    y3Glo(:,6) = wp52Pos(2) + y3Loc(:,6);
    
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
    
    if localAppend == true
        save(ProcessFileName, 'x3Loc', 'y3Loc', 'x3Glo', 'y3Glo', 'x4Glo', 'y4Glo', '-append');
        disp('Angles appended successfully.');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CHECK FOR INDICATION OF CONNECTION SLIP                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Murky concept at this point. find peaks of MTS LVDT, find zeroes between 
%peaks, compare zero to zero at each height of the ramp inbetween to see if
%overall coordinates of connection have changed. quantify change between
%them.
%May also want to look for sudden shift in force graph or overall rotation.
%Will also eventually look for sudden jump in strain gauges.

if ProcessSlip == true
    [maxtab1 mintab1] = peakdet(wp(:,15), 0.1);
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
    lpValues1(:,end+1) = mean(lpValues1,2);
    lpValues2(:,end+1) = mean(lpValues2,2);
    lpValues3(:,end+1) = mean(lpValues3,2);
    lpValues4(:,end+1) = mean(lpValues4,2);
    
    lp(:,1) = lpValues1(:,end);
    lp(:,2) = lpValues2(:,end);
    lp(:,3) = lpValues3(:,end);
    lp(:,4) = lpValues4(:,end);
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
    beamInitialAngle1 = mean(wpAngles(:,3)); %Initial angle top of beam
    beamInitialAngle2 = mean(wpAngles(:,6)); %Initial angle bot of beam
    beamInitialAngle3 = mean(wpAngles(:,9)); %Initial angle of pivot rod
    beamInitialAngle4 = mean(wpAngles(:,12)); %Initial angle of column top %%%REMAP
    beamInitialAngle5 = mean(wpAngles(:,14)); %Initial angle top of beam
    beamInitialAngle6 = mean(wpAngles(:,17)); %Initial angle of bot rod
    
    %Compare current angle between sides a & b (angle gamma) to the
    %initial angle.
    beamRotation(:,1) = wpAngles(:, 3) - beamInitialAngle1;
    beamRotation(:,2) = wpAngles(:, 6) - beamInitialAngle2;
    beamRotation(:,3) = wpAngles(:, 9) - beamInitialAngle3;
    beamRotation(:,4) = wpAngles(:, 14) - beamInitialAngle5;
    beamRotation(:,5) = wpAngles(:, 17) - beamInitialAngle6;
    beamRotation(:,6) = wpAngles(:, 12) - beamInitialAngle4; %%%REMAP
    
    %Use vectors to determine total rotation of beam
    %For top wirepot groups
    Vi = [mean(x3Glo(:,1))-mean(x3Glo(:,2)) mean(y3Glo(:,1))-mean(y3Glo(:,2))];
    V = [x3Glo(:,1)-x3Glo(:,2) y3Glo(:,1)-y3Glo(:,2)];
    
    VDot(:,1) = dot(repmat(Vi,size(V,1),1), V, 2);
    ViMag = sqrt(Vi(1)^2 + Vi(2)^2);
    VMag(:,1) = sqrt(V(:,1).^2 + V(:,2).^2);
    beamRotation(:,11) = acos(VDot./(ViMag .* VMag));
    
    %For bottom wirepot groups
    clearvars Vi V VDot ViMag VMag;
    Vi = [mean(x3Glo(:,3))-mean(x3Glo(:,4)) mean(y3Glo(:,3))-mean(y3Glo(:,4))];
    V = [x3Glo(:,3)-x3Glo(:,4) y3Glo(:,3)-y3Glo(:,4)];
    
    VDot(:,1) = dot(repmat(Vi,size(V,1),1), V, 2);
    ViMag = sqrt(Vi(1)^2 + Vi(2)^2);
    VMag(:,1) = sqrt(V(:,1).^2 + V(:,2).^2);
    beamRotation(:,12) = acos(VDot./(ViMag .* VMag));
    
    %Use Horn's Method to calculate rotation and also get COR from this.
    %See 
    %http://people.csail.mit.edu/bkph/papers/Absolute_Orientation.pdf
    %and
    %http://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method
    
    %Init posistion
    pointsA = [[mean(x3Glo(:,1)); mean(y3Glo(:,1))] [mean(x3Glo(:,2)); mean(y3Glo(:,2))] [mean(x3Glo(:,3)); mean(y3Glo(:,3))] [mean(x3Glo(:,4)); mean(y3Glo(:,4))]]; 
    %pointsA2 = [[mean(x3Glo(:,3)); mean(y3Glo(:,3))] [mean(x3Glo(:,4)); mean(y3Glo(:,4))]];
    pointsA3 = [[mean(x3Glo(:,5)); mean(y3Glo(:,5))] [mean(x3Glo(:,6)); mean(y3Glo(:,6))] [wp51Pos(1); wp51Pos(2)] [wp52Pos(1); wp52Pos(2)]]; 
    
    
    %To prevent broadcast variables and increase speed
    x1 = x3Glo(:,1); x2 = x3Glo(:,2); x3 = x3Glo(:,3); x4 = x3Glo(:,4);
    y1 = y3Glo(:,1); y2 = y3Glo(:,2); y3 = y3Glo(:,3); y4 = y3Glo(:,4);
    
    x13 = x3Glo(:,5); x23 = x3Glo(:,6);
    y13 = y3Glo(:,5); y23 = y3Glo(:,6);
    tic
    parfor r = 1:1:size(wp,1);
        %Current Position
        pointsB = [[x1(r); y1(r)] [x2(r); y2(r)] [x3(r); y3(r)] [x4(r); y4(r)]];
        %pointsB2 = [[x3Glo(r,3); y3Glo(r,3)] [x3Glo(r,4); y3Glo(r,4)]];
        pointsB3 = [[x13(r); y13(r)] [x23(r); y23(r)] [wp51Pos(1); wp51Pos(2)] [wp52Pos(1); wp52Pos(2)]];
        
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
    
    beamRotation(:,13) = tempVar;
    %beamRotation(:,14) = tempVar2;
    beamRotation(:,15) = tempVar3;
    
    beamRotation(row1,13) = beamRotation(row1,13) - 360;
    %beamRotation(row2,14) = beamRotation(row2,14) - 360;
    beamRotation(row3,15) = beamRotation(row3,15) - 360;
    
    
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
    
    beamRotation(:,17) = (dx1 + dx2)./h1WP;
    %{
    lpdx11 = lp(:,1) - mean(lp(:,1));
    lpdx21 = lp(:,3) - mean(lp(:,3));
    lpdx1 = (lpdx11 + lpdx21)./2;
    
    lpdx12 = lp(:,2) - mean(lp(:,2));
    lpdx22 = lp(:,4) - mean(lp(:,4));
    lpdx2 = (lpdx12 + lpdx22)./2;
    
    beamRotation(:,18) = (lpdx1 + lpdx2)./h1LP;
    %}
    clearvars beamInitialAngle1 beamInitialAngle2 beamInitialAngle3 beamInitialAngle5 beamInitialAngle6 Vi V VDot ViMag VMag pointsA pointsB tempVar pointsA2 pointsB2 tempVar2;
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
        distG1 = 29.0625;%(29+(11/16)); %Dist from center of LC G1 to column face
        distG2 = 28.75;  %(29+(7/16)); %Dist from center of LC G2 to column face
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
    r1 = 1;
    r2 = length(sg);
    %Check if folder to save these in exists and create folder if it doesnt
    fullPathName = fullfile(ProcessFilePath,ProcessCodeName);
    if exist(fullPathName,'dir') == 0
        mkdir(ProcessFilePath,ProcessCodeName);
    end
    
    %Put SVG and PNG files into seperate folders to help with clutter
    if exist(fullfile(fullPathName,'SVG'),'dir') == 0
        mkdir(fullPathName,'SVG');
    end
    
    if exist(fullfile(fullPathName,'PNG'),'dir') == 0
        mkdir(fullPathName,'PNG');
    end
    
    %Confirm that all of the folders exist
    if any([exist(fullPathName,'dir'), ...
       exist(fullfile(fullPathName,'SVG'),'dir'), ...
       exist(fullfile(fullPathName,'PNG'),'dir')]) == 0 ...
       
       error('Can not create plots due inability to create directories.');
    end
        
    %Strain gauge array positions change depending on shear tab. this
    %assures that the correct column strain gauges are plotted as desired.
    if ProcessShearTab == '2' || ProcessShearTab == '4'
        plotArrayCol = [offset(sg(r1:r2,7)) offset(sg(r1:r2,8)) offset(sg(r1:r2,9)) offset(sg(r1:r2,10))];
        strainBolt   = sg(r1:r2,5);
    else
        plotArrayCol = [offset(sg(r1:r2,6)) offset(sg(r1:r2,7)) offset(sg(r1:r2,8)) offset(sg(r1:r2,9))];
        strainBolt   = sg(r1:r2,4);
    end

    %%%% Strain Gauges %%%%
    disp('Plotting strain gauge data');
    smartPlot(NormTime(r1:r2), [sg(r1:r2,1) sg(r1:r2,2) sg(r1:r2,3) sg(r1:r2,4)], ...
        'Strain Gauge Data on Shear Tab', 'Time (sec)', 'Strain (uStrain)', ...
        'legend', {'SG1','SG2','SG3','SG4'}, 'visible', 'grid', 'save', 'sg-st');
    
    smartPlot(NormTime(r1:r2), strainBolt, ...
        'Strain Gauge Instrumented Bolt', 'Time (sec)', 'Strain (uStrain)', ...
        'visible', 'grid', 'save', 'sg-bolt');
    
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
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,1), 'WP Group 1 Top Rotation (Init. Angles)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-1g11-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,5), 'WP Group 1 Bot Rotation (Init. Angles)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-1g12-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,2), 'WP Group 2 Top Rotation (Init. Angles)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-1g21-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,6), 'WP Group 2 Bot Rotation (Init. Angles)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-1g22-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,1), beamRotation(r1:r2,2)], ...
        'WP Group 1&2 Top Rotation (Init. Angles)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPG1T','WPG2T'}, 'grid', 'visible', 'save', ...
        'rotation-1g121-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,5), beamRotation(r1:r2,6)], ...
        'WP Group 1&2 Bot Rotation (Init. Angles)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPG1B','WPG2B'},  'grid', 'visible', 'save', ...
        'rotation-1g122-offset')
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,1), beamRotation(r1:r2,5), ...
        beamRotation(r1:r2,2), beamRotation(r1:r2,6)], ...
        'All WP Groups (Init. Angles)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPG1T', 'WPG1B', 'WPG2T', 'WPG2B'}, 'grid', 'visible', 'save', ...
        'rotation-1gA-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,6), 'WP Group 1 Top Rotation (Median)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-2g11-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,9), 'WP Group 1 Bot Rotation (Median)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-2g12-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,7), 'WP Group 2 Top Rotation (Median)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-2g21-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,10), 'WP Group 2 Bot Rotation (Median)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-2g22-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,6), beamRotation(r1:r2,7)], ...
        'WP Group 1&2 Top Rotation (Median)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPG1T','WPG2T'}, 'grid', 'visible', 'save', ...
        'rotation-2g121-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,9), beamRotation(r1:r2,10)], ...
        'WP Group 1&2 Bot Rotation (Median)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPG1B','WPG2B'}, 'grid', 'visible', 'save', ...
        'rotation-2g122-offset')
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,6), beamRotation(r1:r2,9), ...
        beamRotation(r1:r2,7), beamRotation(r1:r2,10)], ...
        'All WP Groups (Median)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPG1T', 'WPG1B', 'WPG2T', 'WPG2B'}, 'grid', 'visible', ...
        'save', 'rotation-2gA-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,11), 'WP Group 1&2 Top Rotation (Vector)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-3g1-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,12), 'WP Group 1&2 Bot Rotation (Vector)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-3g2-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,11), beamRotation(r1:r2,12)], ...
        'All WP Groups (Vector)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPT', 'WPB'}, 'grid', 'visible', ...
        'save', 'rotation-3gA-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,13), 'WP Group 1&2 Top Rotation (Horn)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-4g1-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,14), 'WP Group 1&2 Bot Rotation (Horn)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-3g2-offset');
    
    smartPlot(NormTime(r1:r2), [beamRotation(r1:r2,13), beamRotation(r1:r2,14)], ...
        'All WP Groups (Horn)', 'Time (sec)', 'Rotation (rad)', ...
        'legend', {'WPT', 'WPB'}, 'grid', 'visible', ...
        'save', 'rotation-4gA-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,3), 'WP Group 3 Rotation (Init. Angle)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-1g3-offset');
    
    smartPlot(NormTime(r1:r2), beamRotation(r1:r2,8), 'WP Group 3 Rotation (Median)', ...
        'Time (sec)', 'Rotation (rad)', 'grid', 'visible', 'save', ...
        'rotation-2g3-offset');
    
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
    smartPlot(NormTime(r1:r2), offset(lpValues1(r1:r2,end)), ...
        'Offset Linear Potentiometer 1', 'Distance (in.)', ...
        'Time (Sec.)', 'visible', 'grid', 'save', 'lp-1-offset');
    
    smartPlot(NormTime(r1:r2), offset(lpValues2(r1:r2,end)), ...
        'Offset Linear Potentiometer 2', 'Distance (in.)', ...
        'Time (Sec.)', 'visible', 'grid', 'save', 'lp-2-offset');
    
    smartPlot(NormTime(r1:r2), offset(lpValues3(r1:r2,end)), ...
        'Offset Linear Potentiometer 3', 'Distance (in.)', ...
        'Time (Sec.)', 'visible', 'grid', 'save', 'lp-3-offset');
    
    smartPlot(NormTime(r1:r2), offset(lpValues4(r1:r2,end)), ...
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
    
    %%%% Hysteresis Using Modified Moment %%%%
    disp('Plotting modified moment hysteresis data');
    smartPlot(beamRotation(r1:r2,1), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1 (Top) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-1g11-offset');
    
    smartPlot(beamRotation(r1:r2,4), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1 (Bot) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-1g12-offset');
    
    smartPlot(beamRotation(r1:r2,2), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 2 (Top) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-1g21-offset');
    
    smartPlot(beamRotation(r1:r2,5), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 2 (Bot) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-1g22-offset');
    
    smartPlot(beamRotation(r1:r2,6), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1 (Top) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-2g11-offset');
    
    smartPlot(beamRotation(r1:r2,9), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1 (Bot) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-2g12-offset');
    
    smartPlot(beamRotation(r1:r2,7), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 2 (Top) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-2g21-offset');
    
    smartPlot(beamRotation(r1:r2,10), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 2 (Bot) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-2g22-offset');
    
    smartPlot(beamRotation(r1:r2,11), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1&2 (Top) (Vector)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-3g1-offset');
    
    smartPlot(beamRotation(r1:r2,12), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1&2 (Bot) (Vector)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-3g2-offset');
    
    smartPlot(beamRotation(r1:r2,13), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1&2 (Top) (Horn)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-4g1-offset');
    
    smartPlot(beamRotation(r1:r2,14), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 1&2 (Bot) (Horn)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-4g2-offset');
    
    smartPlot(beamRotation(r1:r2,3), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 3 (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-1g3-offset');
    
    smartPlot(beamRotation(r1:r2,8), moment(r1:r2,7), ...
        'Offset Hysteresis - WP Group 3 (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-2g3-offset');
    
    %%%% Hysteresis Using Un-Modified Moment %%%%
    disp('Plotting unmodified moment hysteresis data');
    smartPlot(beamRotation(r1:r2,1), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1 (Top) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u1g11-offset');
    
    smartPlot(beamRotation(r1:r2,4), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1 (Bot) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u1g12-offset');
    
    smartPlot(beamRotation(r1:r2,2), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 2 (Top) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u1g21-offset');
    
    smartPlot(beamRotation(r1:r2,5), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 2 (Bot) (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u1g22-offset');
    
    smartPlot(beamRotation(r1:r2,6), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1 (Top) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u2g11-offset');
    
    smartPlot(beamRotation(r1:r2,9), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1 (Bot) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u2g12-offset');
    
    smartPlot(beamRotation(r1:r2,7), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 2 (Top) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u2g21-offset');
    
    smartPlot(beamRotation(r1:r2,10), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 2 (Bot) (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u2g22-offset');
    
    smartPlot(beamRotation(r1:r2,11), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1&2 (Top) (Vector)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u3g1-offset');
    
    smartPlot(beamRotation(r1:r2,12), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1&2 (Bot) (Vector)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u3g2-offset');
    
    smartPlot(beamRotation(r1:r2,13), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1&2 (Top) (Horn)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u4g1-offset');
    
    smartPlot(beamRotation(r1:r2,14), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 1&2 (Bot) (Horn)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u4g2-offset');
    
    smartPlot(beamRotation(r1:r2,3), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 3 (Init. Angle)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u1g3-offset');
    
    smartPlot(beamRotation(r1:r2,8), moment(r1:r2,6), ...
        'Offset Hysteresis - Unmod - WP Group 3 (Median)', 'Rotation (rad)', ...
        'Moment (lbf-in)', 'visible', 'grid', 'save', 'hyst-u2g3-offset');

end
