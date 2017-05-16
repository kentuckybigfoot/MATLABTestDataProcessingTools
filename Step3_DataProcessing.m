clc
close all
clear

format long;

%Include functions
addpath('functions\')

%Include subroutines
addpath('subroutines\')

global ProcessRealName %So we can pick this up in function calls
global ProcessCodeName %So we can pick this up in function calls
global ProcessFileName %So we can pick this up in function calls
global ProcessFilePath  %So we can pick this up in function calls

%Process Mode Variables
ProcessFilePath              = 'C:\BFFD Data\Shear Tab 1\FS Testing -ST1 - 06-15-16';
ProcessFileName              = 'FS Testing - ST1 - Test 1 - 06-15-16 - Copy';
ProcessRealName              = 'Full Scale Test 7 - ST1 - 05-24-16';
ProcessCodeName              = 'FST-ST2-May20-2';
ProcessShearTab              = '1'; %1, 2, 3, or 4
localAppend                  = true;
ProcessConsolidateSGs        = true;
ProcessConsolidateWPs        = true;
ProcessConsolidateLPs        = true;
ProcessConsolidateLCs        = true;
ProcessWPAngles              = true;
ProcessWPProperties          = true;
ProcessWPCoords              = true;
ProcessSlip                  = false;%true;
ProcessConfigLPs             = true;
ProcessBeamRotation          = true;
ProcessStrainProfiles        = false;
ProcessCenterOfRotation      = false;
ProcessForces                = false;
ProcessMoments               = true;
ProcessEQM                   = true;
ProcessGarbageCollection     = false;
ProcessOutputPlots           = false;

%Load data
ProcessFileName = fullfile(ProcessFilePath, sprintf('[Filter]%s.mat',ProcessFileName));

load(ProcessFileName);

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
D4 = 3.8925; %WP group measuring top global position
D5 = DF(wp21Pos(1,1), wp71Pos(1,1), wp21Pos(1,2), wp71Pos(1,2)); %Top group 2
D6 = DF(wp22Pos(1,1), wp72Pos(1,1), wp22Pos(1,2), wp72Pos(1,2)); %Bot group 2

%Basic constants
modulus      = 29000; %Modulus of elasticity (ksi)
boltEquation = 0.1073559499; %(uE)/lb
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
consolidateSGs

if ProcessConsolidateSGs == true & localAppend == true
    save(ProcessFileName, 'sg', '-append');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE WIRE POTENTIOMETER VARIABLES INTO SINGLE ARAY                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
consolidateWPs

if ProcessConsolidateWPs == true & localAppend == true
    save(ProcessFileName, 'wp', '-append');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE LINEAR POTENTIOMETER VARIABLES INTO SINGLE ARAY              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
consolidateLPs

if ProcessConsolidateLPs == true & localAppend == true
    save(ProcessFileName, 'lp', '-append');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE LOAD CELLS VARIABLES AND LOAD CELL GROUPS INTO SINGLE ARRAY  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
consolidateLCs

if ProcessConsolidateLCs == true & localAppend == true
    save(ProcessFileName, 'lc', '-append');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE EACH ANGLE OF WIRE POTENTIOMETER TRIANGLES                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
calculateWPAngles

if ProcessWPAngles == true & localAppend == true
    save(ProcessFileName, 'wpAngles', 'wpAnglesDeg', '-append');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE VARIOUS PROPERTIES OF WIRE POT TRIANGLES                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WPProperties


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE COORDINATES OF WIREPOT STRINGS                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wpCoords

if ProcessWPCoords == true & localAppend == true
    save(ProcessFileName, 'x3Loc', 'y3Loc', 'x3Glo', 'y3Glo', 'x4Glo', 'y4Glo', '-append');
    disp('Angles appended successfully.');
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
configLPs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE ROTATION USING WIREPOT DATA                                    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('calculating beam rotation')
calculateBeamRotation

if ProcessBeamRotation == true & localAppend == true
    save(ProcessFileName, 'beamRotation', '-append');
end
disp('end calc')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESS STRAIN PROFILES                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
strainProfiles

if ProcessStrainProfiles == true && localAppend == true
    save(ProcessFileName, 'strainRegression', '-append');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PROCESS FORCES FROM STRAIN GAUGES ON TEST SPECIMAN                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
strainForces

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE MOMENTS FROM SENSOR DATA                                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
calculateMoments

if ProcessMoments == true & localAppend == true
    save(ProcessFileName, 'moment', '-append');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CALCULATE EQUILIBRIUM EQUATIONS                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
calculateEQM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%GENERATE RELEVENT DATA PLOTS                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
generatePlots
