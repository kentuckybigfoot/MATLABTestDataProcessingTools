%% Step3_DataProcessing.m Performs post-processing of MAT-files containing experimental data (EXPAND FOR DOCUMENTATION)
%   Detailed explanation goes here
% Setup Perimeters
%   - ProcessFilePath       - Required. Character-array-type. Contains the directory path in which located is the file to be
%                             post-processed. Optional is inclusion of a concluding slash in the directory path name.
%
%   - ProcessFileName       - Required. Character-arrau-type. The MAT-file containing signal data from experimental
%                             evaluation to be processed.
%
%   - ProcessShearTab       - Required. Double-type. Specifies the shear-tab/LSFF recorded during experimental experimental
%                             evaluation and whose signal data is contained within ProcessFileName. Automatically establishes
%                             this value if the data records are formated as detailed within expanded documentation.
%
%   - ProcessSuperSet       - Recommended. String-type. Specifies the post-processing tasks to be performed upon execution.
%                             The options for selecting tasks to be performed are listed below, and are subsequently provided
%                             alongside the processes' output. Additional information may be found in primary documentation.
%       - ProcessSuperSet Options:
%       - 'all' -
%       - 'consolidation' -
%       - 'Rotation'
%       - 'momRotHyst'
%       - 'forces'
%       - 'XXXX-noConsolidation' - 
%       - 'disabled'
%       - 'allDiag'
%       MENTION Process.Force!!!
%        
%                             
%
%   Copyright 2017-2018 Christopher L. Kerner.
%

clc
close all
clear

% Initialize suite
initializeSuite(mfilename('fullpath'))

%% Post-Processing Script Setup Parameters
ProcessFilePath              = '';
ProcessFileName              = 'FS Testing - ST3 - Test 1 - 08-24-16.mat';
ProcessShearTab              = getShearTab(ProcessFileName);
enableParallelComputing      = true;
ProcessSuperSet              = '';

%% General setup using user-specified parameters
%----------------------------------------------------------------------------------------------------------------------------
% 1) validate and execute processes related to user-specified parameters(load data, get shear tab, superset, etc)
% 2) Light verification of loaded data's integrity
% 3) Perform tasks related to establishing needed constants and parameters
%       - Please see expanded documentation for more information regarding the meaning these tasks..

disp('Initializing Step3_DataProcessing.m'); tic

% Load data if valid filepath is given/exists
ProcessFileName = fullfile(ProcessFilePath,ProcessFileName);
[status,values] = fileattrib(ProcessFileName);

if status == 1
    m = matfile(ProcessFileName, 'Writable', true);
    ProcessListOfVariables = who(m);
else
    error('Unable to load file: %s',ProcessFileName)
end

if ~checkDataRecordIntegrity(m)
    warning('Step3_DataProcessing.m will now pause for 30 seconds. Press CTRL+C if you do not wish to proceed.')
    pause(30);
end

% Ensure that a shear tab is set. If not, attempt to detect shear tab using filename.
if any([isnan(ProcessShearTab), isempty(ProcessShearTab), ~isnumeric(ProcessShearTab), ~isscalar(ProcessShearTab), ...
        ~isreal(ProcessShearTab), ~ismember(ProcessShearTab,[1 2 3 4])])
    % Attempt to detect from filename
    ProcessShearTab = getShearTab(ProcessFileName);
    
    % Can safely warn and proceed due to getShearTab() erroring otherwise.
    warning(['The shear tab was either unspecified or invalid. ST%d was detected and will be used.\nThe script will now', ...
        'pause for 30 seconds so you may cancel execution using CTRL-C if this values appears incorrect.'], ProcessShearTab);   
    pause(30)
end

% Process superset veriable
if exist('Process', 'var') == 0
    Process.Force = false;
end

Process = processSuperSetRules(Process, ProcessSuperSet);

%% Define constants and variables
%----------------------------------------------------------------------------------------------------------------------------
% Basic constants and component attributes
modulus      = 29000;               %Modulus of elasticity (ksi)
gaugeLength  = [0.19685; 0.450];    %(in) which is 5 mm
gaugeWidth   = [0.0590551; 0.180];  %(in) which is 1.5 mm

% Strain gauge instrumented bolt calibration constant. Bolt constant dependent on instrumented bolt used in shear tab.
%   Shear Tab 1 & 2 -> Bolt 1
%   Shear Tab 3 & 4 -> Bolt 2
if ProcessShearTab < 3
    boltEquation = 0.1073559499; %(uE)/lb (Bolt 1)
else
    boltEquation = 0.1094678767; %(uE)/lb (Bolt 2)
end

% Shear tab coordinate system and bolt hole location information.
%   - stMidHeight:              Center distance of the longitudinal height
%   - yGaugeLocations           Estimated locations of the shear tab strain gauges. stMidHeight (center) considered zero
%   - yGaugeLocationsExpanded   Estimated locations of the shear tab & BFFD strain gauges, in addition to edges of shear tab.
%                               stMidHeight (center) considered zero
if ProcessShearTab == 2 || ProcessShearTab == 4
    stMidHeight = 5.75;
    yGaugeLocations = [4.5; 1.5; -1.5; -4.5; -10];
    yGaugeLocationsExpanded = [stMidHeight; 4.5; 1.5; -1.5; -4.5; -stMidHeight; -10];
else
    stMidHeight = 4.25;
    yGaugeLocations = [3; 0; -3; -9];
    yGaugeLocationsExpanded = [stMidHeight; 3; 0; -3; -stMidHeight; -9];
end

% Load coordinates of wirepots
% See full documentation for full explenation
WPPositionX = {[14.2025;14.2025;2.47846;2.47846;0;02.47846;2.47846;4.9375;8.875;0;0;14.2025;14.2025], ...
    [14.265;14.2025;2.47846;2.47846;0;0;2.47846;2.47846;0;0;0;0;14.265;14.2025], ...
    [-0.39;-0.39;11.39654;11.39654;0;0;11.39654;11.39654;4.9375;8.875;0;0;-0.39;-0.39], ...
    [0.39;0.39;16.35346;16.35346;0;0;16.35346;16.35346;4.9375;8.875;0;0;0.39;0.39]};

WPPositionY = {[76.75904,53.02846,71.35875,58.14,0,0,71.35875,58.14,97.59096,97.59096,0,0,76.75904,53.02846], ...
    [53.40904;25.71596;48.5775;32.7025;0;0;48.5775;32.7025;0;0;0;0;55.40904;25.71596], ...
    [77.57154;52.77846;72.265;57.39;0;0;72.265;57.39;97.59096;97.59096;0;0;77.57154;52.77846], ...
    [55.82154;25.77846;48.89;32.515;0;0;48.89;32.515;97.59096;97.59096;0;0;55.82154;25.77846]};

WPPos = [WPPositionX{ProcessShearTab}, WPPositionY{ProcessShearTab}];

% Get distances between wirepot triangle vertices A and B (meaning line c).
% See full documentation for full explenation
distBTWPs = [ ...
    DF(WPPos(7,1), WPPos(1,1), WPPos(7,2), WPPos(1,2)); ...
    DF(WPPos(8,1), WPPos(2,1), WPPos(8,2), WPPos(2,2)); %Bot group 1 ...
    4; %WP for bot. col. global position ...
    3.8925; %WP for top. col. global position ...
    DF(WPPos(3,1), WPPos(13,1), WPPos(3,2), WPPos(13,2)); %Top group 2 ...
    DF(WPPos(4,1), WPPos(14,1), WPPos(4,2), WPPos(14,2)); %Bot group 2 ...
    ];

% Tidy-up workspace
clearvars status values NormTime WPPositionX WPPositionY

fprintf('Initialization of Step3_DataProcessing.m complete. Time taken: %.2f seconds.\n',toc)

%% Concatenate strain gauge variables into single array
%----------------------------------------------------------------------------------------------------------------------------
if Process.ConsolidateSGs == true
    % Concatenates the individual variables containing strain gauge signals (sg1, sg2, etc) into a single variable array (sg)
    % with each each column of sg corresponding to strain gauge signals in the following manner:
    %       ST1 -> sg(:,1:3) = ST1, sg(:,4) = BFFD, sg(:,5) = Bolt SG, sg(:,6:9)  = Column Flanges
    %       ST2 -> sg(:,1:4) = ST2, sg(:,5) = BFFD, sg(:,6) = Bolt SG, sg(:,7:10) = Column Flanges
    %       ST3 -> sg(:,1:3) = ST3, sg(:,4) = BFFD, sg(:,5) = Bolt SG, sg(:,6:9)  = Column Flanges
    %       ST4 -> sg(:,1:4) = ST4, sg(:,5) = BFFD, sg(:,6) = Bolt SG, sg(:,7:10) = Column Flanges
    
    disp('Begin concatenation of SG variables.'); tic
    
    %Pre-allocate sg variable
    sizeOfSGRecord = size(m, 'sg1');
    
    %Concatenate SGs 
    switch ProcessShearTab
        case 1
            m.sg(sizeOfSGRecord(1),1:9) = 0;
            m.sg(:,1:9) = cat(2, m.sg1(:,1), m.sg2(:,1), m.sg3(:,1), m.sg4(:,1), m.sgBolt(:,1), m.sg19(:,1), m.sg20(:,1), ... 
                           m.sg21(:,1), m.sg22(:,1));
        case 2
            m.sg(sizeOfSGRecord(1),1:10) = 0;
            m.sg(:,1:10) = cat(2, m.sg5(:,1), m.sg6(:,1), m.sg7(:,1), m.sg8(:,1), m.sg9(:,1), m.sgBolt(:,1), m.sg19(:,1), ...
                            m.sg20(:,1), m.sg21(:,1), m.sg22(:,1));
        case 3
            m.sg(sizeOfSGRecord(1),1:9) = 0;
            m.sg(:,1:9) = cat(2, m.sg10(:,1), m.sg11(:,1), m.sg12(:,1), m.sg13(:,1), m.sgBolt(:,1), m.sg19(:,1), m.sg20(:,1), ...
                           m.sg21(:,1), m.sg22(:,1));
        case 4
            m.sg(sizeOfSGRecord(1),1:10) = 0;
            m.sg(:,1:10) = cat(2, m.sg14(:,1), m.sg15(:,1), m.sg16(:,1), m.sg17(:,1), m.sg18(:,1), m.sgBolt(:,1), m.sg19(:,1), ...
                            m.sg20(:,1), m.sg21(:,1), m.sg22(:,1));
        otherwise
            error('Unable to determine connection in data record.')
    end
    
    clearvars sizeOfSGRecord;
    
    fprintf('Concatenation of SG variables complete. Time taken: %.2f seconds.\n',toc)
end

%% Concatenate wire-potentiometer variables into single array
%----------------------------------------------------------------------------------------------------------------------------
if Process.ConsolidateWPs == true
    disp('Begin concatenating of WP variables.'); tic
    
    %Pre-allocate WP variable
    m.wp(size(m, 'wp11', 1),1:15) = 0; %#ok<GTARG>
    
    %Concatenate variables into WP and add length of wirepot hooks to signal readings.
    m.wp(:,1:11) = cat(2, m.wp11(:,1), m.wp12(:,1), m.wp21(:,1), m.wp22(:,1), m.wp31(:,1), m.wp32(:,1), m.wp41(:,1), ...
                    m.wp42(:,1), m.wp51(:,1), m.wp61(:,1), m.wp62(:,1)) + 2.71654;
    
    %ST2 did not include WP5-2, WP7-1, or WP7-2
    if ProcessShearTab ~= 2
        m.wp(:,12:14) = cat(2, m.wp71(:,1), m.wp72(:,1),  m.wp52(:,1)) + 2.71654;
    end
    
    %Include length of actuator's extension measured using its internal LVDT.
    m.wp(:,15) = m.MTSLVDT(:,1);
    
    fprintf('Concatenation of WP variables complete. Time taken: %.2f seconds.\n',toc)
end

%% Concatenate linear-potentiometer variables into signle array
%----------------------------------------------------------------------------------------------------------------------------
if Process.ConsolidateLPs == true
    disp('Begin consolidation of LP variables.')
    consolidateLPs
    disp('Consolidation of LP variables complete.')
end

%% Concatenate load cell variables into single array
%----------------------------------------------------------------------------------------------------------------------------
if Process.ConsolidateLCs == true
    disp('Begin concatenating LC variables.');tic
    
    m.lc(size(m, 'LC1', 1),1:9) = 0; %#ok<GTARG>
    
    % Concatenate LCS
    %   lc(:,1:4) -> Reaction frame LCs
    %       lc(:,1:2) -> Reaction frame LCs Group 1
    %       lc(:,3:4) -> Reaction frame LCs Group 2
    %   lc(:,5) -> LC built into actuator measuring its force 
    m.lc(:,1:6) = cat(2, m.LC1(:,1), m.LC1(:,1), m.LC2(:,1), m.LC3(:,1), m.LC4(:,1), m.MTSLC(:,1));
    
    % Take mean of LCs to remove initial offset present within transducers, then group LCs whereas appropriate. NOTE that
    % if by rare chance the beam was even slightly in contact with a reaction frame LC group, offsetting will likely cancel
    % out this value.
    %   lc(:,6:7) -> Offset and grouped LCs
    %      lc(:,6) -> LC Group 1 (LC 1&2)
    %      lc(:,7) -> LC Group 2 (LC 3&4)
    %   lc(:,8) -> Offset readings from LVDT in actuator
    
    %Use first 10 seconds of each reaction frame LC's signal to establish mean for offsetting.
    LCOffsetsIndices = 1/(m.NormTime(2,1) - m.NormTime(1,1));
    LCOffsets = mean(m.lc(1:LCOffsetsIndices,1:5),1);
    
    %Offset reaction frame LCs and then group 
    m.lc(:,7:9) = [(m.LC1(:,1) - LCOffsets(1)) + (m.LC2(:,1) - LCOffsets(2)), ...
                   (m.LC3(:,1) - LCOffsets(3)) + (m.LC4(:,1) - LCOffsets(4)), ...
                    m.MTSLC(:,1) - LCOffsets(5)];
    
    clearvars LCOffsetsIndices LCOffsets;
    
    fprintf('Concatenation of LC variables complete. Time taken: %.2f seconds.\n',toc)
end

%% Calculate angles of WP triangles
%----------------------------------------------------------------------------------------------------------------------------
if Process.WPAngles == true
    %procWPAngles Determines angles of triangles made by wirepots
    %   Note that wirepots are assigned a name such that the first number is the WP triangle grouping, followed by a slash, and then
    %   the wirepot's number in the group which is from right to left w/ the cylinder pointed upward.
    %       Example: WP5-1 is the first WP in WP group 5.
    %
    %   Old note: For ST1, wirepot 3 sat at the bottom of the beam and was
    %   turned upside due to clearance requiring an inversion of naming here.
    
    disp('Begin calculating WP Angles'); tic
    
    %Preallocate WP Angles
    lengthOfWP = size(m, 'wp11');
    m.wpAngles(lengthOfWP(1),1:18) = 0;
    m.wpAnglesDeg(lengthOfWP(1),1:18) = 0;
    
    %Repeat the matrix containing the distance of line c in wirepot triangles for use with lawOfCos()
    distBTWPsRep = repmat(distBTWPs.', [lengthOfWP(1), 1]);

    % Law of cosines (see lawOfCos function) calculates the angles of the WP triangle groups' vertices using WP measurements.
    % A, B, and C vertices correspond to WPs that change location depending on shear tab evaluated. With that said,
    % wpSet(:,1:6) maintains that order using a 1-by-6 cell-array with each cell containing a numeric-array comprised of the
    % distances between vertices (lines a, b, and c).
    %   wpSet{:,1} -> Wirepot Group 1
    %   wpSet{:,2} -> Wirepot Group 2
    %   wpSet{:,3} -> Wirepot Group 3
    %   wpSet{:,4} -> Wirepot Group 4
    %   wpSet{:,5} -> Wirepot Group 5
    %   wpSet{:,6} -> Wirepot Group 6
    switch ProcessShearTab
        case 1
            wpSet(:,1:6) = {[],[],[],[],[],[]};
        case 2
            wpSet(:,1:6) = [[],[],[],[],[],[]];
        case 3
            WPSet(:,1:6) = {[m.wp(:,1) m.wp(:,7) distBTWPsRep(:,1)], [m.wp(:,8) m.wp(:,2) distBTWPsRep(:,2)] ...
                            [], [], ...
                            [m.wp(:,12) m.wp(:,3) distBTWPsRep(:,5)], [m.wp(:,4) m.wp(:,13) distBTWPsRep(:,6)]};
        case 4
            wpSet(:,1:6) = [[],[],[],[],[],[]];
       otherwise
            error('Unable to determine connection in data record.')
    end
    
    % Calculate angles of between sides of WP trianglr groups using law of cosines (see lawOfCose function). Output by 
    % lawOfCos are the angles in the order of alpha, beta, and gamma. These angles are concatenated into a single
    % numeric-array, wpAngles, in which every 3 columns correspondes to a WP group's angles such that:
    %   wpAngles(:,1:3)   -> Wirepot Set 1
    %   wpAngles(:,4:6)   -> Wirepot Set 2
    %   wpAngles(:,7:9)   -> Wirepot Set 3
    %   wpAngles(:,10:12) -> Wirepot Set 4
    %   wpAngles(:,13:15) -> Wirepot Set 5 (Bottom group 1)
    %   wpAngles(:,16:18) -> Wirepot Set 6 (Bottom group 1)
    %
    % Example wpAngles{1, 1:6) = [alpha, beta, gamma, alpha, beta, gamma]
    
    [m.wpAngles(:,1), m.wpAngles(:,2), m.wpAngles(:,3)] = lawOfCos(WPSet{1,1});     %Wirepot Set 1
    [m.wpAngles(:,4), m.wpAngles(:,5), m.wpAngles(:,6)] = lawOfCos(WPSet{1,2});     %Wirepot Set 2
    [m.wpAngles(:,13), m.wpAngles(:,14), m.wpAngles(:,15)] = lawOfCos(WPSet{1,5});  %Wirepot Set 5 (Bottom group 1)
    [m.wpAngles(:,16), m.wpAngles(:,17), m.wpAngles(:,18)] = lawOfCos(WPSet{1,6});  %Wirepot Set 6 (Bottom group 1)
    
    %Make angles avaliable in degrees for convenience.
    m.wpAnglesDeg(:,:) = (180/pi).*m.wpAngles;
    
    % Check if valid angles were calculated. The angles of a triangle should sum to pi. Therefore, round the output angles
    % and pi to the 12th decimal place to account for numerical subtleties occuring when calculating angles, the compare each
    % WP triangle group's sum to pi.
    %
    % Personal note: Use of arithmatic operator in place of sum() is intentional -- results in a ~30% speed increase. 
    wpAnglesRounded = cat(2, (m.wpAngles(:,1) + m.wpAngles(:,2) + m.wpAngles(:,3)), ...
                             (m.wpAngles(:,4) + m.wpAngles(:,5) + m.wpAngles(:,6)), ...
                             (m.wpAngles(:,13) + m.wpAngles(:,14) + m.wpAngles(:,15)), ...
                             (m.wpAngles(:,16) + m.wpAngles(:,17) + m.wpAngles(:,18)));

    wpAnglesRounded = round(wpAnglesRounded,12);
    
    if ~all(wpAnglesRounded == round(pi,12))
        error('Unable to establish accuracy of WP angles calculated. Please verify that groups of angles are equal to pi')
    end
    
    clearvars lengthOfWP distBTWPsRep WPSet1 WPSet2 WPSet5 WPSet6 wpAnglesRounded
    
    fprintf('Calculated WP angles successfully. Time taken: %.2f seconds.\n',toc)
end

%% Calculate various properties of WP triangles
%----------------------------------------------------------------------------------------------------------------------------
if Process.WPProperties == true
    % Calculates the area and the height of the grouped WP triangles. 
    %   This may be useful for atlernative means of calculating beam rotation. Presently, the values calculated here are
    %   unused by the post-processing suite, and are retained merely for legacy or the future expansion of post-processing
    %   features. In the past, the values calculated were used for vectorially calculating beam rotation, in addition to
    %   a few other geometric methods for determining rotation.
    %
    %   Furthermore, alternative methods for calculating these values are featured in comments. These methods were commented
    %   out due to more computationally efficient/high-speed methods being avaliable.
    %
    %   If desired, additional triangle properties easily implemented include the altitudes, medians, and angle bisectors.
    
    disp('Calculating WP triangle properties.')
    
    %Pre-allocate variables in MAT-file
    lengthOfWP = size(m, 'wp11');
    m.wpArea(lengthOfWP(1),1:6) = 0;
    m.wpHeight(lengthOfWP(1),1:6) = 0;
    
    %Creates an array that repeats line c of the WP triangle groups in each column
    dist = [distBTWPs(1), distBTWPs(2), distBTWPs(3), distBTWPs(4), distBTWPs(5), distBTWPs(6)];
    dist = repmat(dist, lengthOfWP(1), 1);
    
    %Define the distances between verticies (lines) of each WP groups' triangle in the order of lines a, b, and c.
    g = {[m.wp(:,7) m.wp(:,1) dist(:,1)], [m.wp(:,2) m.wp(:,8) dist(:,2)], [m.wp(:,5) m.wp(:,6) dist(:,3)], ...
         [m.wp(:,14) m.wp(:,9) dist(:,4)], [m.wp(:,3) m.wp(:,12) dist(:,5)], [m.wp(:,13) m.wp(:,4) dist(:,6)]};
    
    %Calculate the area of each WP groups' triangle using Heron's Formula. See heronsFormula() for more information.
    wpArea = cat(2, heronsFormula(g{1,1}), heronsFormula(g{1,2}), heronsFormula(g{1,3}), ...
                    heronsFormula(g{1,4}), heronsFormula(g{1,5}), heronsFormula(g{1,6}));
    
    %%%%%%%%%%%% vv DEPRECATED vv
    % Calc distance, d, from vertex A to the point on the triangle's base that is perpendicular to its apex. 
    %   Needed for calculating WP triangle groups' height using the Pythagorean theorem.
    %
    %   Deprecated in favor of more computationally efficient method with near identical (~10^-14) results.
    %
    %
    %Simplify typing by creating an anonymoud function
    %getd = @(x, y, z) (-1.*(x.^2) + y.^2 + z.^2)./(2.*z);
    %
    %Calculate d
    %d = cat(2, getd(g{1,1}(:,1), g{1,1}(:,2), g{1,1}(:,3)), getd(g{1,2}(:,1), g{1,2}(:,2), g{1,2}(:,3)), ...
    %           getd(g{1,3}(:,1), g{1,3}(:,2), g{1,3}(:,3)), getd(g{1,4}(:,1), g{1,4}(:,2), g{1,4}(:,3)), ... 
    %           getd(g{1,5}(:,1), g{1,5}(:,2), g{1,5}(:,3)), getd(g{1,6}(:,1), g{1,6}(:,2), g{1,6}(:,3)));
    %%%%%%%%%%%% ^^ DEPRECATED ^^
    
    % Calculate heights of WP triangle groups using geometric equation for area of a triangle.
    %   Given that the area of a triangle may be determined by the following:
    %       Area = (Base * Height)/2.
    %   And having previously determined both the area and base of the triangle(s), the equation may be manipulated to obtain 
    %   WP triangle groups' height as follows:
    %       Height = (2 * Area)/Base
    %
    wpHeight = cat(2, (2.*(wpArea(:,1)./dist(:,1))), (2.*(wpArea(:,2)./dist(:,2))), (2.*(wpArea(:,3)./dist(:,3))),  ...
                      (2.*(wpArea(:,4)./dist(:,4))), (2.*(wpArea(:,5)./dist(:,5))), (2.*(wpArea(:,6)./dist(:,6))));
    
    %%%%%%%%%%%% vv DEPRECATED vv
    % Calculate WP triangle heights using the Pythagorean theorem
    %   Given the distance from vertex A to the point on the base that forms a perpendicular line with the apex, in addition
    %   to the height and leg length, Pythagorean theorem may be manipulated accordingly to determine height.
    %
    %   Deprecated in favor of more computationally efficient method with near identical (~10^-14) results
    %
    %wpHeight2 = cat(2, sqrt(g{1,1}(:,2).^2 - d(:,1).^2), sqrt(g{1,2}(:,2).^2 - d(:,2).^2), ...
    %                   sqrt(g{1,3}(:,2).^2 - d(:,3).^2), sqrt(g{1,4}(:,2).^2 - d(:,4).^2), ...
    %                   sqrt(g{1,5}(:,2).^2 - d(:,5).^2), sqrt(g{1,6}(:,2).^2 - d(:,6).^2));
    
    % It is faster to process these calculations when they are stored in memory as apposed to disk (MAT-file). The calculated
    % values are now stored to disk so that clearvars may be invoked to free memory.
    m.wpArea = wpArea;
    m.wpHeight = wpHeight;
    
    % Free memory. Note the inclusion of variables that are never created since the portions responsible for their generation
    % are commented out. This is to ensure garbage collection takes place if these portions are ever uncommented.
    clearvars lengthOfWP dist g wpArea getd d wpHeight wpHeight2
    
    disp('Calculated WP triangle properties successfully.')
end

%% Calculate coordinates of WP strings                                
%----------------------------------------------------------------------------------------------------------------------------
if Process.WPCoords == true
    disp('Begin processing WP coordinates.'); tic
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get (x3,y3) coords of vertex C of wire pot triangles
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %WP G1 Top
    coordAngles(:,1) = pi - (atan2((WPPos(13,2)-WPPos(3,2)),WPPos(3,1)-WPPos(13,1)) + m.wpAngles(:,14));
    x3Loc(:,1) = -1.*m.wp(:,12).*cos(coordAngles(:,1));
    x3Glo(:,1) = x3Loc(:,1) + WPPos(13,1);
    
    y3Loc(:,1) = m.wp(:,12).*sin(coordAngles(:,1));
    y3Glo(:,1) = WPPos(13,2)-y3Loc(:,1);
    
    %WP G2 Top
    coordAngles(:,2) = atan2((WPPos(4,2) - WPPos(14,2)),(WPPos(4,1) - WPPos(14,1))) + m.wpAngles(:,16);
    x3Loc(:,2) = m.wp(:,13).*cos(coordAngles(:,2));
    x3Glo(:,2) = x3Loc(:,2) + WPPos(14,1);
    
    y3Loc(:,2) = (m.wp(:,13).*sin(coordAngles(:,2)));
    y3Glo(:,2) = WPPos(14,2) + y3Loc(:,2);
    
    %WP G1 Bottom
    coordAngles(:,3) = pi - (atan2((WPPos(1,2)-WPPos(7,2)),WPPos(7,1)-WPPos(1,1)) + m.wpAngles(:,2));
    x3Loc(:,3) = -1.*m.wp(:,1).*cos(coordAngles(:,3));
    x3Glo(:,3) =  x3Loc(:,3) + WPPos(1,1);
    
    y3Loc(:,3) = m.wp(:,1).*sin(coordAngles(:,3));
    y3Glo(:,3) = WPPos(1,2)-y3Loc(:,3);
    
    %WP G2 Bottom
    coordAngles(:,4) = atan2((WPPos(8,2) - WPPos(2,2)),(WPPos(8,1) - WPPos(2,1))) + m.wpAngles(:,4);
    x3Loc(:,4) = m.wp(:,2).*cos(coordAngles(:,4));
    x3Glo(:,4) = x3Loc(:,4) + WPPos(2,1);
    
    y3Loc(:,4) = (m.wp(:,2).*sin(coordAngles(:,4)));
    y3Glo(:,4) = WPPos(2,2) + y3Loc(:,4);
    
    %WP G5 at Top of Column (Global Positioning)
    %Using WP5-1
    x3Loc(:,5) = m.wp(:,9).*sin((pi/2) - m.wpAngles(:,10));
    x3Glo(:,5) = WPPos(9,1) + x3Loc(:,5);
    
    y3Loc(:,5) = m.wp(:,9).*cos((pi/2) - m.wpAngles(:,10));
    y3Glo(:,5) = WPPos(9,2) + y3Loc(:,5);
    
    %Using WP5-2
    x3Loc(:,6) = m.wp(:,14).*sin((pi/2) - m.wpAngles(:,11));
    x3Glo(:,6) = WPPos(10,1) + x3Loc(:,6);
    
    y3Loc(:,6) = m.wp(:,14).*cos((pi/2) - m.wpAngles(:,11));
    y3Glo(:,6) = WPPos(10,2) + y3Loc(:,6);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get (x4,y4) coords (middle of line c)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Don't need a local since it would just be half the length of the line
    %C which we calculate in the D* variables.
    
    %WP G1 Top
    x4Glo(:,1) = (WPPos(7,1) + WPPos(1,1))/2;
    y4Glo(:,1) = (WPPos(7,2) + WPPos(1,2))/2;
    
    %WP G1 Bottom
    x4Glo(:,2) = (WPPos(3,1) + WPPos(13,1))/2;
    y4Glo(:,2) = (WPPos(3,2) + WPPos(13,2))/2;
    
    %WP G2 Top
    x4Glo(:,3) = (WPPos(8,1) + WPPos(2,1))/2;
    y4Glo(:,3) = (WPPos(8,2) + WPPos(2,2))/2;
    
    %WP G2 Bottom
    x4Glo(:,4) = (WPPos(4,1) + WPPos(14,1))/2;
    y4Glo(:,4) = (WPPos(4,2) + WPPos(14,2))/2;
    
    %Save results to MAT-file
    m.x3Loc = x3Loc;
    m.x3Glo = x3Glo;
    m.y3Loc = y3Loc;
    m.y3Glo = y3Glo;
    m.x4Glo = x4Glo;
    m.y4Glo = y4Glo;
    
    clearvars x3Loc x3Glo y3Loc y3Glo x4Glo y4Glo
    
    fprintf('Processing WP coordinates complete. Time taken: %.2f seconds.\n',toc)
end

%% Calculate beam rotations using WPs
%----------------------------------------------------------------------------------------------------------------------------
if Process.BeamRotation == true
    %% Use Horn's Method to calculate beam's rotation with respect to the face of the column.
    %	Through Horn's Method, rotation of the beam may be obtained through mathmatical manipulation of the known initial
    %   and present coordinates of points on the beam to retrieve the transformation having taken place, i.e., absolute
    %   orientation. Provided by this transformation are the means necessary to obtain the rotation matrix and vector,
    %   scale factor, homogenus coordinate transform matrix, and, lastly, the counter-clockwise rotation angle about
    %   specified origin.
    %
    %   More information on Horn's Method may be found in the paper "Closed-form solution of absolute orientation using unit
    %   quaternions" by Berthold K. P. Horn (1986). A copy is avaliable for few at:
    %       http://people.csail.mit.edu/bkph/papers/Absolute_Orientation.pdf
    %
    %   Horn's Method is implemented into this suite using ABSOR by Matt J., and may be found in the link directly preceeding
    %   this paragraph. To be noted are the few minor modifications performed to enhance the speed of Matt J.'s ABSOR. See
    %   absor() for more information.
    %       http://www.mathworks.com/matlabcentral/fileexchange/26186-absolute-orientation-horn-s-method
    %
    %   Additionally, the center of rotation may be obtained using ABSOR's output. Given ABSOR's output rotation matrix, R,
    %   and translation vector, t, the point remaining constant during translation, x, represents the COR (x = COR).
    %   Stated mathmatically:
    %       R*x + t
    %   Back solving for point x, where I_2 is a 2x2 identity matrix, yields:
    %       x = (I_2 - R)\t
    %   Whereas absorData represents ABSOR() output, an example of this implemented using MATLAB scripting language follows:
    %       x = (eye(2)-absorData.R)\absorData.t;  
    
    disp('Calculating beam rotation information.'); tic;
    
    %Determine number of records to be used during process
    lengthOfWP = size(m, 'wp');
    
    % Parfor will likely be slower than a simple for-loop under most conditions. Accordingly, by disabling the automatic
    % creation of paralell pools, MATLAB will automatically fallback to a simple for-loop. Moreover, parfor will not execute
    % for smaller data records and/or when explicitly set to be disabled. Auto creation is re-enabled prior to garbage
    % collection.
    if enableParallelComputing == false || lengthOfWP(1) < 75000
        parCompSettings = parallel.Settings;
        parCompSettings.Pool.AutoCreate = false;
    end
    
    %Pre-allocate variables containing ouput obtained using Horn's Method
    rotInfo(lengthOfWP) = struct('R', [], 't', [], 's', [], 'M', [], 'theta', []);
    
    if  Process.BeamCOR == true
        beamCOR = zeros(lengthOfWP,1:2);
    end
    
    % Define constants describing initial position, pointsA, and WP hook positions, x1-4 & y1-4.
    %   The order of the values contained within these variables is dependant on shear tab being processed currently.
    %   Additionally, a description of these two variables includes:
    %
    %   pointsA - initial position
    %       Specify the initial position of hooks at the end of WP strings
    %
    %   x1-4 & y1-4: Prevents broadcast variables that degrage performance
    %       Explenation: Assuming r to be the parfor index variable, were x3Glo(r,1) to be reference within parfor, the
    %       entire m-x-4 matrix would be sent to the parallel pool workers and row r of column 1 out of 4 reviewed. This
    %       creates significant overhead when solely required is the first column. Therefor, split things up.
    %
    %   Note that the abscence of a wirepot group is accounted for by repeating a present wirepot group.
    %
    if ismember(ProcessShearTab, [1, 3, 4])
        pointsA = [[m.x3Glo(1,1); m.y3Glo(1,1)] [m.x3Glo(1,2); m.y3Glo(1,2)] [m.x3Glo(1,3); m.y3Glo(1,3)] [m.x3Glo(1,4); m.y3Glo(1,4)]];
        x1 = m.x3Glo(:,1); x2 = m.x3Glo(:,2); x3 = m.x3Glo(:,3); x4 = m.x3Glo(:,4);
        y1 = m.y3Glo(:,1); y2 = m.y3Glo(:,2); y3 = m.y3Glo(:,3); y4 = m.y3Glo(:,4);
    elseif ProcessShearTab == 2
        % Modify Accordingly
    else
        error('Unable to determine connection in data record.')
    end

    % Begin beam rotation information calculations
    %   Could not establish a better method other than this nasty logic for controlling behavior based on desired output.
    %   Additionally, if-else logic was excluded to cut down on execution time.
    if ProcessBeam.Rotation == true && Process.BeamCOR == true
        %Process beam rotations AND COR
        parfor r = 1:1:lengthOfWP(1)
            %Current Position
            pointsB = [[x1(r); y1(r)] [x2(r); y2(r)] [x3(r); y3(r)] [x4(r); y4(r)]];
            
            %Store ABSOR results
            rotInfoTmp = absor(pointsA, pointsB);
            rotInfo(r) = rotInfoTmp;
            
            %Calculate beam's center of rotation
            beamCOR(r,:) = (eye(2)-rotInfoTmp.R)\rotInfoTmp.t;
        end
    elseif Process.BeamRotation == true && Process.BeamCOR == false
        %Process beam rotations ONLY
        parfor r = 1:1:lengthOfWP(1)
            %Current Position
            pointsB = [[x1(r); y1(r)] [x2(r); y2(r)] [x3(r); y3(r)] [x4(r); y4(r)]];
            
            %Store ABSOR results
            rotInfoTmp = absor(pointsA, pointsB);
            rotInfo(r) = rotInfoTmp;
        end
    elseif ProcessBeamRotation == false && ProcessBeamCOR == true
        %Process COR ONLY
        parfor r = 1:1:lengthOfWP(1)
            %Current Position
            pointsB = [[x1(r); y1(r)] [x2(r); y2(r)] [x3(r); y3(r)] [x4(r); y4(r)]];
            
            %Store ABSOR results
            rotInfoTmp = absor(pointsA, pointsB);
            
            %Calculate beam's center of rotation
            beamCOR(r,:) = (eye(2)-rotInfoTmp.R)\rotInfoTmp.t;
        end
    else
        error('Unable to determine the motivation behind executing this process. Please correct existential crisis.')
    end
    
    % Process ABSOR results
    if ProcessBeamRotation == true    
        %Corrects subtle variations in beam rotation placing certain values in the wrong quadrant.
        tempTheta = [rotInfo(:).theta].';        
        [row, ~] = find(tempTheta > 25);
        tempTheta(row) = tempTheta(row) - 360;
        
        %Save beam rotations
        m.beamRotation(1:lengthOfWP,1) = tempTheta;
    end
    
    %Process beam COR
    if ProcessBeamCOR == true    
        %Save beam rotations
        m.beamCOR(1:lengthOfWP,1:2) = beamCOR;
    end
    
    %Re-enable automatic creation of parallel pools if disabled prior to processing beam rotation
    if enableParallelComputing == false || lengthOfWP(1) < 75000
        parCompSettings = parallel.Settings;
        parCompSettings.Pool.AutoCreate = true;
    end
    
    clearvars parCompSettings lengthOfWP rotInfo beamCOR pointsA x1 x2 x3 x4 y1 y2 y3 y4 pointsB rotInfoTmp row
    
    fprintf('Calculated beam rotation information successfully. Time taken: %.2f seconds.\n',toc)
end

%% Calculate moments using sensor data
%----------------------------------------------------------------------------------------------------------------------------
if Process.Moments == true
    % Calculates moment at shear tab bolt line using the distance between the center of shear tab bolt line and the center
    % of the rollers projecting from the LCs groups on reaction frames.
    disp('Calculating moments.'); tic
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Moments calculated using LC Data %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    sizeOfLCRecord = size(m,'LC1');
    m.moment(sizeOfLCRecord(1),2) = 0;
    
    %Dist from center of LC G1 (distG1) and LC G2 (distG2) to column face
    switch ProcessShearTab
        case 1
            distG1 = 29.6875;
            distG2 = 29.4375;
        case 2
            %Use caution
            distG1 = 29.0;
            distG2 = 29.0;
        case 3
            distG1 = 29.25;
            distG2 = 29.0;
        case 4
            distG1 = 28.9375;
            distG2 = 29.125;
        otherwise
            error('Unable to determine connection in data record.')
    end
    
    %Unadjusted due to rotation. From roller to column flange
    m.moment(:,1) = (m.lc(:,7)*distG2) - (m.lc(:,6)*distG1);
    
    %Adjust due to rotation changing distance from roller to col. face
    %Method 1: Using average from linear potentiometers.
    %moment(:,7) = lc(:,7)*distG2 - lc(:,6)*distG1;
    %Method 2: Using beam rotation from wire-pot group 3.
    x1 = mean([2*WPPos(7,2).*sin((m.beamRotation(:,3)/10)/2) 2*WPPos(3,2).*sin((m.beamRotation(:,3)/10)/2)],2);
    x2 = mean([2*WPPos(8,2).*sin((m.beamRotation(:,3)/10)/2) 2*WPPos(4,2).*sin((m.beamRotation(:,3)/10)/2)],2);
    m.moment(:,2) = m.lc(:,7).*(distG2-x2) - m.lc(:,6).*(distG1-x1);
    
    fprintf('Calculating moments complete. Time taken: %.2f seconds.\n',toc)
end

%% Calculate area of hysteresis (energy dissipated)
%----------------------------------------------------------------------------------------------------------------------------
if Process.Hysteresis == true
    % Calculates moment at shear tab bolt line using the distance between the center of shear tab bolt line and the center
    % of the rollers projecting from the LCs groups on reaction frames.
    %allReqdVariablesExist(ProcessListOfVariables, {'wp', 'moment','beamRotation'));
    disp('Calculating area of hystereses (energy dissipated)'); tic
    
    % Load values into memory for faster results
    moment = m.moment(:,1);
    beamRotation = m.beamRotation(:,1);
    
    % Use MTS LVDT measurements to determine when complete revolution on hysteresis should have been made
    [ minMaxRanges, LVDTMinMax ] =  getActuatorRanges(m.wp(:,15));
    numOfMinMaxRanges = size(minMaxRanges,1);
    
    %Pre-allocate energyDissipated and index number
    energyDissipated = zeros(ceil(numOfMinMaxRanges/2),3);
    idx = 1;
    
    % Result where ranges for minima and maxima references where MTS LVDT measured actuator extension as 0 inches.
    for r = 1:2:numOfMinMaxRanges
        
        % Ranges used
        if r+2 >= numOfMinMaxRanges
            % Include what is likely the concluding flatline of the record
            hystMeth1Range1 = minMaxRanges(r,3);
            hystMeth1Range2 = minMaxRanges(r,4);
        else
            hystMeth1Range1 = minMaxRanges(r,3);
            hystMeth1Range2 = minMaxRanges(r+1,4);
        end
        
        % Beam rotation and moment used for hysteresis loop
        hystMeth1BeamRotation = beamRotation(hystMeth1Range1:hystMeth1Range2,1);
        hystMeth1Moment = moment(hystMeth1Range1:hystMeth1Range2,1);
        
        % Calculate energy dissipated in hysteresis loop
        energyDissipated(idx,1:3) = [trapz(hystMeth1BeamRotation, hystMeth1Moment), hystMeth1Range1, hystMeth1Range2];
        
        idx = idx+1;
    end
    
    fprintf('Calculated Area of hystereses successfully. Time taken: %.2f seconds.\n',toc)
    
    clearvars moment beamRotation minMaxRanges LVDTMinMax numOfMinMaxRanges r hystMeth1Range1 hystMeth1Range2 ...
        hystMeth1BeamRotation hystMeth1Moment
end
%%

%% (Untouched) PROCESS LP DATA
%----------------------------------------------------------------------------------------------------------------------------
%configLPs

%% (Untouched) PROCESS STRAIN PROFILES
%----------------------------------------------------------------------------------------------------------------------------
%strainProfiles

%% (Untouched) PROCESS FORCES FROM STRAIN GAUGES ON TEST SPECIMAN
%----------------------------------------------------------------------------------------------------------------------------
%strainForces

%% (Untouched) CALCULATE EQUILIBRIUM EQUATIONS
%----------------------------------------------------------------------------------------------------------------------------
%calculateEQM

%% (Untouched) GENERATE RELEVENT DATA PLOTS
%----------------------------------------------------------------------------------------------------------------------------
%generatePlots

%% Final cleanup
clearvars modulus boltEquation gaugeLength gaugeWidth stMidHeight yGaugeLocations yGaugeLocationsExpanded WPPos ...
    distBetweenWPs