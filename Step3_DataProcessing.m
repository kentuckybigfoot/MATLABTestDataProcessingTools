clc
%close all
clear

format long;

%Process Mode Variables
ProcessFileName              = '..\[Filter]FS Testing - ST2 - Test 1 - 04-01-16.mat';
ProcessRealName              = 'Full Scale Test';
ProcessCodeName              = 'FST-ST2-Mar27-1';
ProcessShearTab              = '2'; %1, 2, 3, or 4
runParallel                  = true;
localAppend                  = false;
ProcessConsolidateSGs        = true;
ProcessConsolidateWPs        = true;
ProcessConsolidateLCs        = true;
ProcessWPAngles              = true;
ProcessWPHeights             = true;
processWPHeighDistances      = false;
processWPCoordinates         = false;
ProcessBeamRotation          = true;
ProcessStrainProfiles        = true;
ProcessCenterOfRotation      = false;
ProcessForces                = true;
ProcessMoments               = true;
ProcessGarbageCollection     = false;
ProcessOutputPlots           = false;

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

load(ProcessFileName);



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
    lc(:,6) = LC1(:,1)+LC2(:,1);
    lc(:,7) = LC3(:,1)+LC4(:,1);
    
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
        [wpAngles, wpAnglesDeg] = procWPAnglesPar(wp);
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
    m11 = (wp(1,7)*sin(wpAngles(1,2)) - 0)/(wp(1,7)*cos(wpAngles(1,2)) - 5.625);
    
    %Slope for bottom of the beam
    m12 = (wp(1,2)*sin(wpAngles(1,5)) - 0)/(wp(1,2)*cos(wpAngles(1,5)) - 5.75);
    
    %Slope for wirepots at the pivot rod.
    m13 = (wp(1,6)*sin(wpAngles(1,8)) - 0)/(wp(1,6)*cos(wpAngles(1,8)) - 2);
    
    for i = 1:1:size(wp,1
        %Compare current angle between sides a & b (angle gamma) to the
        %initial angle.
        beamRotation(i,1) = abs(wpAngles(i, 3) - beamInitialAngle1);
        beamRotation(i,2) = abs(wpAngles(i, 6) - beamInitialAngle2);
        beamRotation(i,3) = abs(wpAngles(i, 9) - beamInitialAngle3);
        
        %Current slope of the triangle median for the top of the beam,
        %bottom of the beam, and pivot rod, respectively.
        m21 = (wp(i,7)*sin(wpAngles(i,2)) - 0)/(wp(i,7)*cos(wpAngles(i,2)) - 5.625);
        m22 = (wp(i,2)*sin(wpAngles(i,5)) - 0)/(wp(i,2)*cos(wpAngles(i,5)) - 5.75);
        m23 = (wp(i,6)*sin(wpAngles(i,8)) - 0)/(wp(i,2)*cos(wpAngles(i,8)) - 2);
        
        %Calculate the angle between the initial and current median for the
        %top of the beam, bottom of the beam, and pivot rod, respectively.
        beamRotation(i,4) = atan2((m12 - m22),(1 + m12*m22));
        beamRotation(i,5) = atan2((m12 - m22),(1 + m12*m22));
        beamRotation(i,6) = atan2((m13 - m23),(1 + m13*m23));
        
        %Progress indicator. atan2 take considerable time to execute and
        %this give me a hint of how close to being finished matlab is.
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

for q = 1:1:4
    offsetTemp(:,q) = offset(lc(:,q));
    q
    for r = 1:1:size(lc,1)
        if offsetTemp(r,q) > 0
            lc2(r,q) = 0;
        else
            lc2(r,q) = offsetTemp(r,q);
        end
    end
end

lcMod(:,1) = lc2(:,1) + lc2(:,2);
lcMod(:,2) = lc2(:,3) + lc2(:,4);

lc2(:,6) = offset(lc(:,6));
lc2(:,7) = offset(lc(:,7));

for s = 1:1:size(lcMod,1)
    %mo(s,1) = lc2(s,7)*29.375 - lc2(s,6)*30.1875 - lc2(s,5)*48;
    mo(s,1) = lcMod(s,2)*29.375 - lcMod(s,1)*30.1875;
    mo(s,2) = lc2(s,7)*29.375 - lc2(s,6)*30.1875;
end
figure
plot(offset(beamRotation(:,3)), mo(:,2))
grid on
grid minor
figure
plot(offset(beamRotation), mo(:,2))
grid on
grid minor
%figure
%plot(offset(beamRotation), mo(:,1))
%grid on
%grid minor

%}
%{
plot3(NormTime, repmat(strainIncrement,1,57046),  strainProf)
hold
scatter3(NormTime, repmat(xLocation(1,2),57046,1), (10^-6)*offset(sg(:,1)))
scatter3(NormTime, repmat(xLocation(2,2),57046,1), (10^-6)*offset(sg(:,2)))
scatter3(NormTime, repmat(xLocation(3,2),57046,1), (10^-6)*offset(sg(:,3)))
scatter3(NormTime, repmat(xLocation(4,2),57046,1), (10^-6)*offset(sg(:,4)))
%}
if ProcessOutputPlots == true
    disp('Creating beam rotation plots.');
    count = 0;
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime,beamAngleDiff,'.','MarkerSize',3)
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Departure of Angle b\\t Beam WPs from Initial Angle b\\t Beam WPs'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Rotation (rad)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')

    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime,round(beamAngleDiff,3),'.','MarkerSize',3)
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Departure of Angle b\\t Beam WPs from Initial Angle b\\t Beam WPs (3 Dec. Rounding)'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Rotation (rad)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')

    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime,round(beamAngleDiff,4),'.','MarkerSize',3)
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Departure of Angle b\\t Beam WPs from Initial Angle b\\t Beam WPs (4 Dec. Rounding)'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Rotation (rad)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')

    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime,beamRotation,'.','MarkerSize',3)
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Departure of Angle b\\t Beam WPs Resultant from Initial Angle b\\t Beam WPs Resultant'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Rotation (rad)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')

    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime,round(beamRotation,3),'.','MarkerSize',3)
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Departure of Angle b\\t Beam WPs Resultant from Initial Angle b\\t Beam WPs Resultant (3 Dec. Rounding)'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Rotation (rad)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')

    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime,round(beamRotation,4),'.','MarkerSize',3)
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Departure of Angle b\\t Beam WPs Resultant from Initial Angle b\\t Beam WPs Resultant (4 Dec. Rounding)'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Rotation (rad)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    disp('Creating wirepot plots')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(wp(:,1)), NormTime, offset(wp(:,2)), NormTime, offset(wp(:,3)), NormTime, offset(wp(:,4)), NormTime, offset(wp(:,5)), NormTime, offset(wp(:,6)), NormTime, offset(wp(:,7)), NormTime, offset(wp(:,8)), NormTime, offset(wp(:,9)), NormTime, offset(wp(:,10)), NormTime, offset(wp(:,11)), NormTime, offset(wp(:,12)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Elongation of Wirepots'; ProcessRealName})
    legend('WP1-1', 'WP1-2', 'WP2-1', 'WP2-1', 'WP3-1', 'WP3-2', 'WP4-1', 'WP4-2', 'WP5-1', 'WP6-1', 'WP6-2', 'MTS LVDT', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, wpAngleHeight(:,1), NormTime, wpAngleHeight(:,2), NormTime, wpAngleHeight(:,3), NormTime, wpAngleHeight(:,4))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Elongation of Wirepot Groups Using Angle Height'; ProcessRealName})
    legend('WP Group 1', 'WP Group 2', 'WP Group 3', 'WP Group 4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(wpAngleHeight(:,1)), NormTime, normfxn(wpAngleHeight(:,2)), NormTime, normfxn(wpAngleHeight(:,3)), NormTime, normfxn(wpAngleHeight(:,4)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Normalized Elongation of Wirepot Groups Using Angle Height'; ProcessRealName})
    legend('WP Group 1', 'WP Group 2', 'WP Group 3', 'WP Group 4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(wp(:,10)), NormTime, normfxn(wp(:,11)), NormTime, normfxn(wp(:,12)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Normalized Changes in Distances b\\t RXN Block Ends Against MTS LVDT'; ProcessRealName})
    legend('WP6-2', 'WP 6-1', 'MTS LVDT', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(wpAngleHeight(:,1)), NormTime, offset(wpAngleHeight(:,2)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Vert. and Horiz. Linear Displacements of Column'; ProcessRealName})
    legend('WP G1 (Vert)', 'WP G2 (Horiz)', 'Location', 'Best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, wpAngleHeight(:,3))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Bottom Vertical Linear Displacement of Beam Flange'; ProcessRealName})
    legend('WP G3', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, wpAngleHeight(:,4))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Bottom Horizontal Linear Displacement of Beam Flange'; ProcessRealName})
    legend('WP G4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    plot(NormTime, force(:,1), NormTime, force(:,2), NormTime, force(:,3), NormTime, force(:,4), NormTime, force(:,5))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Force Data From Strain Gauge Readings'; ProcessRealName})
    legend('1', '2', '3', '4', 'BFFD', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (kip)');
    grid on
    grid minor
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, wp(:,9))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Top Horizontal Linear Displacement of Beam Flange'; ProcessRealName})
    legend('WP G4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(wpAngleHeight(:,3)), NormTime, offset(wpAngleHeight(:,4)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Bottom Vert. and Horiz. Linear Displacement of Beam'; ProcessRealName})
    legend('WP G3 (Vert)', 'WP G4 (Horiz)', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(wpAngleHeight(:,3)), NormTime, offset(wpAngleHeight(:,4)), NormTime, offset(wp(:,9)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Top and Bottom Linear Displacements of Beam'; ProcessRealName})
    legend('WP G3 (Vert)', 'WP G4 (Horiz)', 'WP 5-1 (Horiz)', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Length (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    disp('Process Load Cell Graphs')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(lc(:,1)), NormTime, offset(lc(:,2)), NormTime, offset(lc(:,3)), NormTime, offset(lc(:,4)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Reaction Block Load Cells'; ProcessRealName})
    legend('LC 1', 'LC 2', 'LC 3', 'LC 4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (lbf)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    count = count+1;     figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(offset(lc(:,1))), NormTime, normfxn(offset(lc(:,2))), NormTime, normfxn(offset(lc(:,3))), NormTime, normfxn(offset(lc(:,4))))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Normalized Offset Reaction Block Load Cells'; ProcessRealName})
    legend('LC 1', 'LC 2', 'LC 3', 'LC 4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (lbf)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    count = count+1;     figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(lc(:,5)), NormTime, offset(lc(:,1)), NormTime, offset(lc(:,2)), NormTime, offset(lc(:,3)), NormTime, offset(lc(:,4)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Reaction Block Load Cells with MTS LC'; ProcessRealName})
    legend('MTS LC', 'LC 1', 'LC 2', 'LC 3', 'LC 4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (lbf)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(offset(lc(:,5))), NormTime, normfxn(offset(lc(:,1))), NormTime, normfxn(offset(lc(:,2))), NormTime, normfxn(offset(lc(:,3))), NormTime, normfxn(offset(lc(:,4))))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Normalized Offset Reaction Block Load Cells With MTS LC'; ProcessRealName})
    legend('MTS LC', 'LC 1', 'LC 2', 'LC 3', 'LC 4', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (lbf)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(lc(:,5)), NormTime, offset(lc(:,6)), NormTime, offset(lc(:,7)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Reaction Block Groupings With MTS LC'; ProcessRealName})
    legend('MTS LC', 'LC G 1', 'LC G 2', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (lbf)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(offset(lc(:,5))), NormTime, normfxn(offset(lc(:,6))), NormTime, normfxn(offset(lc(:,7))))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Normalized Offset Reaction Block Load Cells With MTS LC'; ProcessRealName})
    legend('MTS LC', 'LC G 1', 'LC G 2', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (lbf)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    %plot(NormTime, normfxn(offset(lc(:,5)), NormTime, normfxn(offset(lc(:,6)), NormTime, normfxn(offset(lc(:,7)), NormTime, normfxn(wpOffset(:,12)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Normalized Offset RXN Block LCS With MTS LC Against LVDT'; ProcessRealName})
    legend('MTS LC', 'LC G 1', 'LC G 2', 'MTS LVDT', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Force (lbf)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    disp('Process Strain Gauge, Force, and Moment Graphs')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(sg(:,4)), NormTime, offset(sg(:,1)), NormTime, offset(sg(:,2)), NormTime, offset(sg(:,3)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Shear Tab 1 Offset Strain Gauge Data'; ProcessRealName})
    legend('SG4', 'SG1', 'SG2', 'SG3', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('strain (uStrain)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(offset(sg(:,4))), NormTime, normfxn(offset(sg(:,1))), NormTime, normfxn(offset(sg(:,2))), NormTime, normfxn(offset(sg(:,3))))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Shear Tab 1 Normalized Offset Strain Gauge Data'; ProcessRealName})
    legend('SG4', 'SG1', 'SG2', 'SG3', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('strain (uStrain)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(offset(sg(:,4))), NormTime, normfxn(offset(sg(:,1))), NormTime, normfxn(offset(sg(:,2))), NormTime, normfxn(offset(sg(:,3))), NormTime, normfxn(wp(:,12)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Shear Tab 1 Normalized Offset Strain Gauge Data Against Normalised MTS LVDT'; ProcessRealName})
    legend('SG4', 'SG1', 'SG2', 'SG3', 'MTS LVDT', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('strain (uStrain)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(sg(:,6)), NormTime, offset(sg(:,7)), NormTime, offset(sg(:,8)), NormTime, offset(sg(:,9)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Column Strain Gauge Data'; ProcessRealName})
    legend('SG19', 'SG20', 'SG21', 'SG22', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('strain (uStrain)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, normfxn(offset(sg(:,6))), NormTime, normfxn(offset(sg(:,7))), NormTime, normfxn(offset(sg(:,8))), NormTime, normfxn(offset(sg(:,9))), NormTime, normfxn(wp(:,12)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Normalized Offset Column Strain Gauge Data Against Normalised MTS LVDT'; ProcessRealName})
    legend('SG19', 'SG20', 'SG21', 'SG22', 'MTS LVDT', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('strain (uStrain)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, sg(:,5))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Bolt Strain Gauge'; ProcessRealName})
    legend('Bolt SG', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('strain (uStrain)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, offset(sg(:,5)))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Offset Bolt Strain Gauge'; ProcessRealName})
    legend('Bolt SG', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('strain (uStrain)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, moment(:,1), NormTime, moment(:,2))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Couple Moment on Shear Tab Using All Strain Gauges'; ProcessRealName})
    legend('Top Component', 'Bottom Component', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Moment (kip-in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, moment1(:,1), NormTime, moment1(:,2))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Couple Moment on Shear Tab Using Top & Center SGs'; ProcessRealName})
    legend('Top Component', 'Bottom Component', 'Location', 'best');
    xlabel('Time (sec)')
    ylabel('Moment (kip-in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, moment(:,3))
    %[hAx,hLine1,hLine2] = plotyy(NormTime, moment(:,3), NormTime, wp(:,12))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    %axis([-inf inf -1*max([abs(min(moment(:,3))) abs(min(wp(:,12)))]) max([max(moment(:,3)) max(wp(:,12))])])
    title({'Moment on Shear Tab Using All Strain Gauges'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Moment (kip-in)');
    %ylabel(hAx(2),'Displacement (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, moment1(:,3))
    %[hAx,hLine1,hLine2] = plotyy(NormTime, moment(:,3), NormTime, wp(:,12))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    %axis([-inf inf -1*max([abs(min(moment(:,3))) abs(min(wp(:,12)))]) max([max(moment(:,3)) max(wp(:,12))])])
    title({'Moment on Shear Tab Using Top and Center SGs'; ProcessRealName})
    xlabel('Time (sec)')
    ylabel('Moment (kip-in)');
    %ylabel(hAx(2),'Displacement (in)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    
    %{
    count = count+1;
    figure('Visible','off','Renderer','painters')
    plot(NormTime, forceAxial(:,1), NormTime, forceAxial(:,2), NormTime, forceBending(:,1), NormTime, forceBending(:,2), NormTime, forceBending(:,3), NormTime, forceBending(:,4), forceTotal(:,1), NormTime, forceTotal(:,2), NormTime, forceTotal(:,3), NormTime, forceTotal(:,4))
    set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
    set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
    title({'Actual & Maximum Axial Forces'; ProcessRealName})
    legend('Act. A', 'Max. A', 'Act. B1', 'Act. B2', 'Max. B1', 'Max. B2', 'Act. T1', 'Act. T2', 'Max. T1', 'Max. T2');
    xlabel('Time (sec)')
    ylabel('Force (kip)');
    grid on
    grid minor
    saveAsFileName = sprintf('%sFig %d',ProcessCodeName,count);
    saveas(gcf, saveAsFileName, 'png')
    %saveas(gcf, saveAsFileName, 'svg')
    %saveas(gcf, saveAsFileName, 'fig')
    %}
    figure('Visible','on')
end


%{
figure
plot(NormTime, offset(sg(:,1), 'b', NormTime, offset(sg(:,2), 'r', NormTime, offset(sg(:,3), 'g'); 
legend('Bolt 1', 'Bolt 2', 'Bolt 3');
grid on
grid minor

figure
plot(NormTime, offset(LCNormal(:,5), 'b', NormTime, offset(LCNormal(:,6), 'r', NormTime, offset(LCNormal(:,7),'g', NormTime,wpNormal(:,12))
legend('MTS LC', 'RXN Block 1', 'RXN Block 2', 'MTS LVDT')
title('Normalized Offset Load Cells Over Normalised LVDT All Against Time');
grid on
grid minor

figure
plot(NormTime, offset(lc(:,5), 'b', NormTime, offset(lc(:,6), 'r', NormTime, offset(lc(:,7),'g')
legend('MTS LC', 'RXN Block 1', 'RXN Block 2')
title('Offset Load Cells Against Time');
grid on
grid minor

%figure
%plot(NormTime, offset(lc(:,1), NormTime, offset(lc(:,2), NormTime, offset(lc(:,3), NormTime, offset(lc(:,4))

%figure
%}


%{
if ProcessCartRotation == true
    beamInitialResultant = sqrt(wpAngleHeight(1,1)^2 + wpAngleHeight(1,2)^2);
    beamInitialAngle     = atan(wpAngleHeight(1,2)/wpAngleHeight(1,1));
    beamInitialAngleDeg  = atand(wpAngleHeight(1,2)/wpAngleHeight(1,1));
    beamInitialAngleDiff  = (pi/2)-((pi-(wpAngles(1,7)+(pi/2)))+(pi-(wpAngles(1,11)+(pi/2))));
    beamInitialAngleDiffDeg  = 90-((180-(wpAnglesDeg(1,7)+90))+(180-(wpAnglesDeg(1,11)+90)));
    
    disp('begin loop')
    for i = 1:1:length(wp11)
        beamResultants(i,1) = sqrt(wpAngleHeight(i,3)^2 + wpAngleHeight(i,4)^2);
        beamAngles(i,1)     = atan(wpAngleHeight(i,4)/wpAngleHeight(i,3));
        beamAnglesDeg(i,1)  = atand(wpAngleHeight(i,4)/wpAngleHeight(i,3));
        beamAngleDiff(i,1)  = (pi/2)-((pi-(wpAngles(i,7)+(pi/2)))+(pi-(wpAngles(i,11)+(pi/2))));
        beamAngleDiffDeg(i,1)  = 90-((180-(wpAnglesDeg(i,7)+90))+(180-(wpAnglesDeg(i,11)+90)));
        beamAngleCenterChange(i,1) = round(wp41(i,1)*sind((180-(wpAnglesDeg(i,11)+90))),3);
  
        beamRotation(i,1) = beamAngles(i,1) - beamInitialAngle;
        
    end 
%}
%{        

for i = 2:1:length(wp11)
    wp3Change(i,1) = wp3Angles(i,2) - wp3Angles(i-1,2);
end
for i = 1:1:length(wp11)
    s = (wp31(i,1) + wp32(i,1) + 4)/2;
    A = sqrt(s*(s-wp31(i,1))*(s-wp32(i,1))*(s-4));
    height(i,1) = 2*(A/4);
end

for i = 1:1:length(wp11)
    s = (wp41(i,1) + wp42(i,1) + 4)/2;
    A = sqrt(s*(s-wp41(i,1))*(s-wp42(i,1))*(s-4));
    height1(i,1) = 2*(A/4);
end

min1 = min(height);
max1 = max(height);

min2 = min(-1*MTSLVDT);
max2 = max(-1*MTSLVDT);

min3 = min(height1);
max3 = max(height1);

for i = 1:1:length(wp11)
    heightNorm(i,1) = (height(i,1) - min1)/(max1-min1);
    heightNorm1(i,1) = (height1(i,1) - min3)/(max3-min3);
    dispNorm(i,1)   = (-1*MTSLVDT(i,1) - min2)/(max2-min2);
end

plot(NormTime,heightNorm1,'r',NormTime,dispNorm,'b',NormTime,sgolayfilt(heightNorm1,1,21),'g')


range = 97000:103000;

t = NormTime(range,1);
f(:,1) = sg1(range,1);
f(:,2) = sgolayfilt(sg1(range,1),1,3);
f(:,3) = sgolayfilt(sg1(range,1),2,5);
f(:,4) = sgolayfilt(sg1(range,1),1,7);
f(:,5) = sgolayfilt(sg1(range,1),1,9);
f(:,6) = sgolayfilt(sg1(range,1),1,11);
f(:,7) = sgolayfilt(sg1(range,1),1,13);
f(:,8) = sgolayfilt(sg1(range,1),3,15);
f(:,9) = sgolayfilt(sg1(range,1),3,17);
%}
%{
figure;
hold on

subplot(6,1,1);
hold on
plot(t,f31)
plot(t,sg1(range,1),'Color',[1, 0, 0, 0.1])

subplot(6,1,2);
hold on
plot(t,f31);
plot(t,sg1(range,1),'Color',[1, 0, 0, 0.1])

subplot(6,1,3);
hold on
plot(t,f51);
plot(t,sg1(range,1),'Color',[1, 0, 0, 0.1])

subplot(6,1,4);
hold on
plot(t,f71);
plot(t,sg1(range,1),'Color',[1, 0, 0, 0.1])

subplot(6,1,5);
hold on
plot(t,f91);
plot(t,sg1(range,1),'Color',[1, 0, 0, 0.1])

subplot(6,1,6);
hold on
plot(t,f111);
plot(t,sg1(range,1),'Color',[1, 0, 0, 0.05])

%plot(t,f3,t,f5,t,f7,t,f9,t,f11)
%legend('3','5','7','9','11')

%}
%{
filters = [0 3 5 7 9 11 13 15 17];
i= 1;
for i = 2:1:8
    figure
    hold on
    p1 = plot(t,LC1(range,1),'Color',[1, 0, 0, 1]);
    p2 = plot(t,sgolayfilt(LC1(range,1),1,filters(1,i)),'b');
    title(sprintf('LC1 1 vs. Normalized Time, %f SGF Frame Size',filters(1,i)));
    ylabel('Strain (uStrain)');
    xlabel('Time (sec)');
    grid on;
    grid minor; 
end
 %}
%figure
%hold on
%p1 = plot(t,sg1(range,1),'Color',[1, 0, 0, 0.1]);
%p2 = plot(t,f113,'b');
%grid on

%{ 
wrong moment code
dA = [(((offset(sg(i,1)*10^-6)/gaugeLength)+gaugeLength)*gaugeWidth; (((offset(sg(i,3)*10^-6)/gaugeLength)+gaugeLength)*gaugeWidth];
        
        %Stress at particular points
        stressDistOrig(i,:)               = stressRegression(i,1) + stressRegression(i,2)*points;
        stressDistAxial(i,1:size(points)) = (10^-6)*modulus*offset(sg(i,2);
        stressDistBend(i,:)               = stressRegression(i,4) + stressRegression(i,5)*points;
        
        %Forces given the area of bending as edge to center of ST divided
        %by thickness
        areaTrue   = 3*0.25; %in^2
        areaMax    = (1.25+1.5+1.5)*0.25; %in^2
        
        %below we have a variable that gives the force determined by the
        %known stresses from the strain gauge and then another that details
        %the forces using the highest calculated from interpolation. The
        %latter is to account for potential stress concentrations and for
        %the fact that bending will force the beam to rotate to a position
        %where it is acting on less clear space.

        %For the actual forces:
        forceAxial(i, 1)    = areaTrue*stressDistAxial(i,1);
        forceBending(i, 1:2) = [areaTrue*stressDistBend(i,4) areaTrue*stressDistBend(i,16)];
        forceTotal(i, 1:2)   = [(forceAxial(i, 1)+forceBending(i, 1)) (forceAxial(i, 1)+areaTrue*stressDistBend(i,16))];
        
        %For the maximised forces:
        forceAxial(i, 2)    = areaMax*stressDistAxial(i,1);
        forceBending(i, 3:4) = [areaMax*stressDistBend(i,4) areaMax*stressDistBend(i,16)];
        forceTotal(i, 3:4)   = [(forceAxial(i, 2)+forceBending(i, 3)) (forceAxial(i, 2)+areaMax*stressDistBend(i,16))];
        
        %Calculate Moments
        %Centroid
        cActual = (2/3)*3; %in
        cMax    = (2/3)*(4.25); %in
        
        %For actual forces:
        momentBending(i, 1) = forceBending(i,1)*cActual + forceBending(i,2)*cActual;
        
        %For maximum moment
        momentBending(i, 2) = forceBending(i,3)*cMax + forceBending(i,4)*cMax;
        %}
%{
myVideo = VideoWriter('myfile.avi')

open(myVideo);

uncompressedVideo = VideoWriter('myfile.avi', 'Uncompressed AVI');

for i = 1:1:size(moment, 1)
    plot(NormTime(i,1), moment(i,1));
    currFrame = getframe;
    writeVideo(myVideo,currFrame);
end

close(myVideo);
%}

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
