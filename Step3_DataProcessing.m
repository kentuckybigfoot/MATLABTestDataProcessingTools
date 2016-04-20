clc
%close all
clear

format long;

global ProcessRealName %So we can pick this up in function calls
global ProcessCodeName %So we can pick this up in function calls

%Process Mode Variables
ProcessFileName              = 'FS Testing - ST2 - Test 2 - 04-15-16';
ProcessRealName              = 'Full Scale Test 2 - ST2 Only - 04-15-16';
ProcessCodeName              = 'FST-ST2-Apr15-2';
ProcessShearTab              = '2'; %1, 2, 3, or 4
runParallel                  = true;
localAppend                  = false;
ProcessConsolidateSGs        = true;
ProcessConsolidateWPs        = true;
ProcessConsolidateLCs        = true;
ProcessWPAngles              = true;
ProcessWPCoords              = false;
ProcessWPHeights             = false;
processWPHeighDistances      = false;
processWPCoordinates         = false;
processIMU                   = true;
ProcessBeamRotation          = true;
ProcessStrainProfiles        = true;
ProcessCenterOfRotation      = false;
ProcessForces                = true;
ProcessMoments               = true;
ProcessGarbageCollection     = false;
ProcessOutputPlots           = false;

% The very end where the pivot rests serves as reference for all
% measurements. All measurements are assumed to start at the extreme end of
% the column below the pivot point in the center of the web. Dimensions are
% given in (x,y)and represent the center of the hook at the end of the
% wire. Dimensions for the wire pots can be found in Fig. 2 of page 68
% (WDS-...-P60-CR-P) of http://www.micro-epsilon.com/download/manuals/man--wireSENSOR-P60-P96-P115--de-en.pdf

wp11Pos = [(13+7/8)+0.50+0.39 54.25-(5.07-2.36)];
wp12Pos = [(13+7/8)+0.375+0.39 22+1.5+5.07];
wp21Pos = [0 0];
wp22Pos = [0 0];
wp31Pos = [0 0];
wp32Pos = [0 0];
wp41Pos = [5.07 48.125+0.39];
wp42Pos = [5.07 31.8750+0.39];
D1 = DF(wp41Pos(1,1), wp11Pos(1,1), wp41Pos(1,2), wp11Pos(1,2));
D2 = DF(wp42Pos(1,1), wp12Pos(1,1), wp42Pos(1,2), wp12Pos(1,2));
D3 = 4;
D4 = 0;

%Constants
modulus = 29000; %Modulus of elasticity (ksi)
boltEquation = 0;
gaugeLength = [0.19685; 0.19685]; %(in) which is 5 mm
gaugeWidth  = [0.0590551; 0.19685]; %(in) which is 1.5 mm

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
filename1 = fullfile('..\',sprintf('[ProcRotationData] %s.mat',ProcessFileName));
    
load(sprintf('[Filter]%s.mat',ProcessFileName));

if exist(filename1, 'file') == 2
    load(filename1);
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
    wp(:,12) = MTSLVDT(:,1);
    
    disp('WP variables successfully converted into one. Appending to file and removing garbage.')
    clearvars wp11 wp12 wp21 wp22 wp31 wp32 wp41 wp42 wp51 wp61 wp62 MTSLVDT;
    if localAppend == true
        save(ProcessFileName, 'wp', '-append');
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
        [wpAngles, wpAnglesDeg] = procWPAnglesPar(wp, [D1, D2, D3, D4]);
    else
        [wpAngles, wpAnglesDeg] = procWPAngles(wp);
    end
    
    disp('Processing angles complete. Validating angles.')
    %wpAnglesPass = [];
    
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
        %disp(num2str(i),' failed last')
    else
        disp('Angles using non offset data calculated successfully. Appending to file (if localAppend = true) and removing garbage.')
        clearvars wp1Angles wp2Angles wp3Angles wp4Angles wp1cDist wp2cDist wp3cDist wp4cDist wpAnglesPass
        if localAppend == true
            save(ProcessFileName, 'wpAngles', 'wpAnglesDeg', '-append');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE X & Y COORDINATES FOR C VERTEX OF WIRE POT TRIANGLES           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%See "help lawOfCos" for angle orientation information.

%Determine XY of triangles using both angles and compare them as a fail
%safe. Comparison is only carried out to three decimal places.
%Realistically the wire pots are likely only moderatly accurate to the
%second decimal place but a third helps with round-off error in floating
%math.

%Coded in accordance to wire-pot configuration in place 04/01/16
if ProcessWPCoords == true
    for r = 1:1:size(wp,1)
        %WP Group 1
        wpCoords(r,1:2) = [wp11Pos(1,1)+wp(r,1)*cos(((3/2)*pi)-wpAngles(r,1)) wp11Pos(1,2)-wp(r,1)*sin(((3/2)*pi)-wpAngles(r,1))];
        wpCoords(r,3:4) = [wp41Pos(1,1)+wp(r,7)*cos(wpAngles(r,2)) wp41Pos(1,2)+wp(r,7)*sin(wpAngles(r,2))];
 
        %WP Group 2
        wpCoords(r,5:6) = [wp42Pos(1,1)+wp(r,8)*sin(wpAngles(r,4)) wp42Pos(1,2)+wp(r,8)*sin(-wpAngles(r,4))];
        wpCoords(r,7:8) = [wp12Pos(1,1)+wp(r,2)*cos(pi-wpAngles(r,5)) wp12Pos(1,2)+wp(r,2)*cos(wpAngles(r,5))];
        
        %wpCoords(r,13) = (wpCoords(r,6) - wpCoords(r,2))/(wpCoords(r,5) - wpCoords(r,1));
        %wpCoords(r,14) = (wpCoords(r,8) - wpCoords(r,4))/(wpCoords(r,7) - wpCoords(r,3));
        %WP Group 2
       % wpCoords(r,9:10) = [wp(r,5)*cos(wpAngles(r,7)) wp(r,5)*sin(wpAngles(r,7))];
        %wpCoords(r,11:12) = [wp(r,6)*cos(wpAngles(r,8)) wp(r,6)*sin(wpAngles(r,8))];
        
        %{
        if any(round(wpCoords(r,1:2),3) ~= round(wpCoords(r,3:4),3))
            error('Danger, Will Robinson! Angles #%d for WPG1 do not match (%f,%f,%f,%f)',r,wpCoords(r,1), wpCoords(r,2), wpCoords(r,3), wpCoords(r,4));
        end
        %}
        
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE STRAIN GAUGE VARIABLES INTO SINGLE ARRAY                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Use Heron's Formula to determine the area of the triangle made by the
%wirepots and then backsolve formula for area of triangle to get triangle
%height.
if ProcessWPHeights == true
    if runParallel == true
        [wpAngleHeight] = procWPAngleHeightPar(wp);
    else
        [wpAngleHeight] = procWPAngleHeight(wp);
    end
    
    disp('Wire pot angles calculated. Appending to file and removing garbage.');
    clearvars wpS wpSOffset wpAngleArea wpAngleAreaOffset;
    if localAppend == true
        save(ProcessFileName, 'wpAngleHeight', '-append');
    end
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
    %Yaw (alpha) (CC Z Axis)
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
    beamInitialAngle1 = wpAngles(1,3); %Initial angle top of beam
    beamInitialAngle2 = wpAngles(1,6); %Initial angle bot of beam
    beamInitialAngle3 = wpAngles(1,9); %Initial angle of pivot rod
    
    %For progress updates
    reverseStr = '';
    
    %Determine the initial slope of the triangles' median (midpoint of
    %length c to vertex C). This is done so that later the current slope
    %can be found and relating slope to tangent the change in angle during
    %rotation can be determined.
    
    %Slope for top of the beam
    m11 = (wp(1,7)*sin(wpAngles(1,2)) - 0)/(wp(1,7)*cos(wpAngles(1,2)) - D1/2);
    
    %Slope for bottom of the beam
    m12 = (wp(1,2)*sin(wpAngles(1,5)) - 0)/(wp(1,2)*cos(wpAngles(1,5)) - D2/2);
    
    %Slope for wirepots at the pivot rod.
    m13 = (wp(1,6)*sin(wpAngles(1,8)) - 0)/(wp(1,6)*cos(wpAngles(1,8)) - 2);
    
    for i = 1:1:size(wp,1)
        %Compare current angle between sides a & b (angle gamma) to the
        %initial angle.
        beamRotation(i,1) = wpAngles(i, 3) - beamInitialAngle1;
        beamRotation(i,2) = wpAngles(i, 6) - beamInitialAngle2;
        beamRotation(i,3) = abs(wpAngles(i, 9) - beamInitialAngle3);
        
        %Current slope of the triangle median for the top of the beam,
        %bottom of the beam, and pivot rod, respectively.
        m21 = (wp(i,7)*sin(wpAngles(i,2)) - 0)/(wp(i,7)*cos(wpAngles(i,2)) - D1/2);
        m22 = (wp(i,2)*sin(wpAngles(i,5)) - 0)/(wp(i,2)*cos(wpAngles(i,5)) - D2/2);
        m23 = (wp(i,6)*sin(wpAngles(i,8)) - 0)/(wp(i,6)*cos(wpAngles(i,8)) - 2);
        
        %Calculate the angle between the initial and current median for the
        %top of the beam, bottom of the beam, and pivot rod, respectively.
        beamRotation(i,4) = atan2((m21 - m11),(1 + m11*m21));
        beamRotation(i,5) = atan2((m22 - m12),(1 + m12*m22));
        beamRotation(i,6) = atan2((m23 - m13),(1 + m13*m23));
        
        %As of 04/01/02 there are two wire pots on the top flange of the
        %column and two wire pots on the bottom flange. These wire pots at
        %each level set parallel to one another and by comparing their
        %initial elongation to their current elongation the angle of
        %rotation can be determined. WP4-1 and WP4-2 sit on the top flange
        %while WP2-1 and WP2-2 sit on the bottom.
        
      
        %Progress indicator. atan2 and the other trig functions take 
        %considerable time to execute and this give me a hint of how
        %close to being finished matlab is.
        percentDone = 100 * i / size(wp,1);
        msg = sprintf('Percent done: %3.1f', percentDone);
        fprintf([reverseStr, msg]);
        reverseStr = repmat(sprintf('\b'), 1, length(msg));
    end
    
    clearvars m11 m12 m13 m21 m22 m23 beamInitialAngle1 beamInitialAngle2 beamInitialAngle3 reverseStr percentDone msg;
    disp('Beam rotations calculated.. Appending to data file.');
    if localAppend == true
        save(ProcessFileName, 'beamResultants', 'beamAngles', 'beamAnglesDeg', 'beamAngleDiff', 'beamAngleDiffDeg', 'beamAngleCenterChange', 'beamRotation', 'beamRotationDeg', '-append');
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


if ProcessCenterOfRotation == true
    % Constants for location COR using WP heights. See commentary for COR4.
    CORAverageRange = find(round(NormTime,3) == 7);
    CORWPAverage    = mean(wpAngleHeight(1:CORAverageRange,3));
    
    for i = 1:1:size(strainRegression,1)
        %Center of rotation along vertical width using strain gauges of shear tabs
        %COR(i,1) = -strainRegression(i,1)/strainRegression(i,2); %roots([strainRegression(i,1) strainRegression(i,2)]);
        %COR(i,2) = -strainRegression(i,4)/strainRegression(i,5); %roots([strainRegression(i,4) strainRegression(i,5)]);
        
        %Center of rotation along vertical width using strain gauges of shear tabs and column
        %flange friction component
        
        %Change in center of rotation along vertical width using vertical height
        %change measured by WP G3 at bottom of beam flange.
        %Average WP G3 height from first 7 seconds of data since 10 seconds
        %of flat line normally exists ahead of the start of testing.
        %COR(i,4) = wpAngleHeight(i, 3) - CORWPAverage;
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
        %Middle of shear tab at column flange face
        
        
        moment(:,6) = lc(:,7)*30.5 - lc(:,6)*29.5; 
        %Need to implement. Will require measuring distance from center of
        %LCs to column. Will also have to take into count translation of
        %the beam/column.
    end
    clearvars gaugeLength gaugeWidth stMidHeight x topLength botLength strainTop strainTop1 strainBot strainBot1 elongationTop elongationTop1 elongationBot elongationBot1
    if localAppend == true
        save(ProcessFileName, 'moment', 'moment1', '-append');
    end
    %}
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
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,7)) offset(wp(r1:r2,3)) offset(wp(r1:r2,1))], ...
        'Offset Wirepot Group 1', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP4-1','WP2-1','WP1-1'},  'visible', 'grid', 'save', 'wp-g1-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,8)) offset(wp(r1:r2,4)) offset(wp(r1:r2,2))], ...
        'Offset Wirepot Group 2', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP4-2','WP2-2','WP1-2'}, 'visible', 'grid', 'save', 'wp-g2-offset');
    
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
        offset(wp(r1:r2,8)) offset(wp(r1:r2,4)) offset(wp(r1:r2,2))], ...
        'Offset All Beam Rotation Wirepots', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP4-1','WP2-1','WP1-1','WP4-2','WP2-2','WP1-2'}, ...
        'visible', 'grid', 'save', 'wp-allrot-offset');
    
    smartPlot(NormTime(r1:r2), [offset(wp(r1:r2,10)) offset(wp(r1:r2,11))], ...
        'Offset Wirepots Measuring Twist in Column', 'Time (sec)', 'Length (in)', ...
        'legend', {'WP6-1','WP6-2'}, 'visible', 'grid', 'save', 'wp-twist-offset');
    
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
lc2(:,7) = offset(lc(:,7));
lc2(:,6) = offset(lc(:,6));
lc2(:,5) = offset(lc(:,5));
for s = 1:1:size(lc,1)
    mo(s,1) = lc2(s,7)*27 - lc2(s,6)*27 - lc2(s,5)*48;
    mo(s,2) = lc2(s,7)*27 - lc2(s,6)*27;
end
figure
plot(beamRotation, mo(:,2))
%}
