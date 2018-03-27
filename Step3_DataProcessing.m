%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

%
%   Copyright 2017-2018 Christopher L. Kerner.
%
clc
close all
clear

format long;

%Include functions
addpath(genpath('libCommonFxns'))

%Include external functions
addpath(genpath('libExternalFxns'))

%Include subroutines
addpath(genpath('dataProcessingSubroutines'))

%%

%Post-Process Component Variables
ProcessFilePath              = 'C:\Users\Christopher\Desktop';
ProcessFileName              = '[Filter]FS Testing - ST3 - Test 1 - 08-24-16.mat';
ProcessShearTab              = getShearTab(ProcessFileName);
ProcessConsolidateSGs        = false;
ProcessConsolidateWPs        = false;
ProcessConsolidateLCs        = false;
ProcessConsolidateLPs        = false;
ProcessWPAngles              = false;
ProcessWPProperties          = true;
ProcessWPCoords              = true;
ProcessConfigLPs             = false;
ProcessBeamRotation          = true;
ProcessStrainProfiles        = false;
ProcessCenterOfRotation      = false;
ProcessForces                = false;
ProcessMoments               = false;
ProcessEQM                   = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Basic constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
modulus      = 29000; %Modulus of elasticity (ksi)
gaugeLength  = [0.19685; 0.450]; %(in) which is 5 mm
gaugeWidth   = [0.0590551; 0.180]; %(in) which is 1.5 mm

%Strain gauge instrumented bolt calibration constant
if ProcessShearTab < 3
    %Bolt 1 used in connection 1 & 2
    boltEquation = 0.1073559499; %(uE)/lb
else
    %Bolt 2 used in connection 1 & 2
    boltEquation = 0.1094678767; %(uE)/lb
end

%Shear tab coordinate system and bolt hole location information.
if ProcessShearTab == 2 || ProcessShearTab == 4
    stMidHeight = 5.75;
    yGaugeLocations = [4.5; 1.5; -1.5; -4.5; -10];
    yGaugeLocationsExpanded = [stMidHeight; 4.5; 1.5; -1.5; -4.5; -stMidHeight; -10];
else
    stMidHeight = 4.25;
    yGaugeLocations = [3; 0; -3; -9];
    yGaugeLocationsExpanded = [stMidHeight; 3; 0; -3; -stMidHeight; -9];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ProcessFileName = fullfile(ProcessFilePath,ProcessFileName);
m = matfile(ProcessFileName, 'Writable', true);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load coordinates of wire-pots.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wpPosition;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get distances between wirepot triangle vertices A and B (line c).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
distBetweenWPs = [ ...
    DF(WPPos(7,1), WPPos(1,1), WPPos(7,2), WPPos(1,2)); ...
    DF(WPPos(8,1), WPPos(2,1), WPPos(8,2), WPPos(2,2)); %Bot group 1 ...
    4; %WP for bot. col. global position ...
    3.8925; %WP for top. col. global position ...
    DF(WPPos(3,1), WPPos(13,1), WPPos(3,2), WPPos(13,2)); %Top group 2 ...
    DF(WPPos(4,1), WPPos(14,1), WPPos(4,2), WPPos(14,2)); %Bot group 2 ...
    ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSOLIDATE STRAIN GAUGE VARIABLES INTO SINGLE ARRAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateSGs == true
    disp('Begin consolidation of SG variables.')
    consolidateSGs
    disp('Consolidation of SG variables complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE WIRE POTENTIOMETER VARIABLES INTO SINGLE ARRAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateWPs == true
    disp('Begin consolidation of WP variables.')
    consolidateWPs
    disp('Consolidation of WP variables complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CONSOLIDATE LINEAR POTENTIOMETER VARIABLES INTO SINGLE ARRAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateLPs == true
    disp('Begin consolidation of LP variables.')
    consolidateLPs
    disp('Consolidation of LP variables complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSOLIDATE LOAD CELLS VARIABLES AND LOAD CELL GROUPS INTO SINGLE ARRAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessConsolidateLCs == true
    disp('Begin consolidation of LC variables.')
	consolidateLCs
    disp('Consolidation of LC variables complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE EACH ANGLE OF WIRE POTENTIOMETER TRIANGLES                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessWPAngles == true
    disp('Begin calculating WP Angles')
    calculateWPAngles
    disp('WP angles calculations complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE VARIOUS PROPERTIES OF WIRE POT TRIANGLES                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessWPProperties == true
    disp('Calculating WP properties.')
    WPProperties
    disp('Calculating WP properties complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE COORDINATES OF WIREPOT STRINGS                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessWPCoords == true
    disp('Begin processing WP coordinates.')
    wpCoords
    disp('Processing WP coordinates complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (Untouched) PROCESS LP DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%configLPs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE ROTATION USING WIREPOT DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessBeamRotation == true
    disp('Calculating beam rotation.')
    calculateBeamRotation
    disp('Calculating beam rotation complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(Untouched) PROCESS STRAIN PROFILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%strainProfiles

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(Untouched) PROCESS FORCES FROM STRAIN GAUGES ON TEST SPECIMAN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%strainForces

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE MOMENTS FROM SENSOR DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ProcessMoments == true
    disp('Calculating moments.')
    calculateMoments
    disp('Calculating moments complete.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(Untouched) CALCULATE EQUILIBRIUM EQUATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%calculateEQM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(Untouched) GENERATE RELEVENT DATA PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generatePlots

clearvars ProcessConsolidateSGs ProcessConsolidateWPs ProcessConsolidateLPs ...
	      ProcessConsolidateLCs ProcessWPAngles ProcessWPProperties ProcessWPCoords ...
          ProcessConfigLPs ProcessBeamRotation ProcessStrainProfiles ...
          ProcessCenterOfRotation ProcessForces ProcessMoments ProcessEQM ...
          ProcessOutputPlots modulus boltEquation gaugeLength gaugeWidth stMidHeight ...
          yGaugeLocations yGaugeLocationsExpanded WPPos distBetweenWPs