function Step2_DataFilterGUI
%Step2_DataFilterGUI Filter signals contained within imported experimental data.
%   Raw experimental test data imported into MAT-file format using Step1_ImportRAWFiles.m or Step1_ImportASCIIFiles.m may
%   be filtered using this graphical user interface (GUI). Features include the review, spectral analysis, and filtering of
%   individual signals contained within the variables of imported data files. See appropriate help files.
%
%   Copyright 2016-2018 Christopher L. Kerner.
%

%Initialize suite
initializeSuite(mfilename('fullpath'))

%% Data Filtering GUI Setup Parameters
% ---------------------------------------------------------------------------------------------------------------------------
%
fileDir = ''; %Directory file is located in
filename = 'FS Testing - ST3 - Test 1 - 08-24-16'; %Name of file to be filtered

%List of variables to be ignored when generating table of variables present within file.
doNotFilter = {'NormTime', 'Run', 'importManifest', 'filterManifest', 'filterParameter', 'A', 'B', 'C', 'D', ...
    'E', 'F', 'G', 'H'}; 

%% Initialization Tasks
% ---------------------------------------------------------------------------------------------------------------------------
%
fullFilename = fullfile(fileDir,filename);

m = matfile(fullFilename, 'Writable', true);
fileVariables = who('-file', fullFilename);

% Check if signals were previously filtered using legacy system.
checkForLegacyManifest();

% Dimensions of figure script was developed using initially (See resizeProtection function below)
originalFigurePosPixels = [9 9 1264 931];

% General script variables
filterManifest = [];

% General records regarding data being filtered.
varList       = [];
varName       = [];
tempName      = [];
originalData  = [];
modifiedData  = [];
filteredData  = [];

% Initial DSP values to assure globalism and etc.
Fs = 0;              % Sampling frequency                    
T  = 0;  %#ok<NASGU> % Sampling period (Placeholder)      
L  = 0;              % Length of signal
t  = 0;  %#ok<NASGU> % Time vector (Placeholder)
decimationFactor = NaN;

% fir1() Filter Constants
fir1FilterType          = 'low';
fir1FilterTypeValue     = 1;
fir1FiltFreqType        = 0; % 0 -> undef, 1 -> lowpass/highpass filter, 2 -> bandpass/bandstop filter, 3 -> DC-0/DC-1 filter 
fir1FiltOrd             = [];
fir1FiltFreq            = [];

% Custom Filter Design Constants
% - Placeholder

%% Create Graphics Components of GUI
% Notes:
% 0) General note: GUI component positions are normalized units unless otherwise modified later. Position related properties
%    are defined using 1-by-4 double arrays that follow the standard MATLAB convention of [left, bottom, width, height].
% 1) Create a struct containing the GUI figure, then axes, then populate axes. The fields are as follows:
%       axes1 -> Filtering axes
%           * p1 -> original signal line
%           * p2 -> Filtered signal line
%       axes2 -> Spectral analysis axes
%           * p3 -> power spectral density line
% 2) Define the default data cursor used within the GUI to be the extended data cursor (See extendedDataCursor()).
% 3) Define UI components which are stored within assigned fields of the filterGUI structure.
% 4) Perform concluding GUI initilization tasks:
%       i)   Format axes (Apply titles, X & Y labels, X & Y major and minor grids).
%       ii)  Populate the Signal Viewer UI table.
%       iii) Correct Filter Design UI panel position.
%       iv)  Find the underling Java object reference of the spectral analysis and filter design textbox(es).
% 5) Call it good, and eat fried balogna sandwiches. Optional arguments for a pat on the back. This isn't serious or funny.
% ---------------------------------------------------------------------------------------------------------------------------
%

%% Initialize GUI
% Define GUI figure
filterAxes.fig = figure('Visible', 'on', 'Units', 'pixels', 'OuterPosition', [0 0 1280 1024], 'CloseRequestFcn', @clearData);

% Overcomes errors stemming from ResizeFcn being defined before the full initilization of related variables that occurs
% prior to the figure becoming visible. For further info, see "Why Has the Behavior of ResizeFcn Changed?" at
% https://www.mathworks.com/help/matlab/graphics_transition/why-has-the-behavior-of-resizefcn-changed.html
filterAxes.fig.ResizeFcn = @resizeProtection;

% Add title to GUI figure that includes the name of the MAT-file currently in use
filterAxes.fig.NumberTitle = 'off';
filterAxes.fig.Name = sprintf('Step2_DataFilterGUI - Opened: %s', filename);

% Define axes and axes' children
filterAxes.axes1 = axes('Parent', filterAxes.fig, 'Position', [0.04,0.565,0.75,0.40]);
filterAxes.axes2 = axes('Parent', filterAxes.fig, 'Position', [0.04,0.065,0.75,0.40]);
filterAxes.p1 = line(filterAxes.axes1, NaN, NaN);
filterAxes.p2 = line(filterAxes.axes1, NaN, NaN, 'Color', [0.8500, 0.3250, 0.0980]);
filterAxes.p3 = line(filterAxes.axes2, NaN, NaN);

% Assign legend for data filtering axes but turn off visibility prior to filtering.
%filterAxes.legend1 = legend(filterAxes.axes1, {'Orig. Data', 'Filt. Data'}, 'Location', 'Best');
%filterAxes.legend1.Visible = 'Off';

% Assign data cursors
dcm_obj = datacursormode(filterAxes.fig);
set(dcm_obj,'UpdateFcn',@extendedDataCursor)

% Define structure to contain UI components
filterGUI = struct([]);

%% Spectral Analysis Panel
addGUIComp('SDE_pnl');
setLastGUIComp(  ...
	'Type', 'uipanel', ...
    'Parent', filterAxes.fig, ... 
    'Title', 'Spectral Analysis Options', ...
    'Units', 'normalized', ...
    'Position', [0.8 0.872 0.182 0.1]);

% Decimation
addGUIComp('SDE_dcmtn_txt');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.SDE_pnl, ...
    'Style', 'text', ...
    'String', 'Decimate', ...
    'Units', 'normalized', ...
    'Position', [0.015 0.745 0.22 0.15]);

addGUIComp('SDE_dcmtn_fctrSet');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.SDE_pnl, ...
    'Style', 'edit', ...
    'Tag', 'decFactor', ...
    'Units', 'normalized', ...
    'Position', [0.26 0.65 0.35 0.25]);
    
addGUIComp('SDE_dcmtn_btn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.SDE_pnl, ...
    'String','Decimate', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0.65 0.685 0.29 0.25], ...
    'Callback', @decimateData);

% Frequency Units
addGUIComp('SDE_frqBtns_grp_mstr');
setLastGUIComp( ...
	'Type', 'uibuttongroup', ...
    'Parent', filterGUI.SDE_pnl, ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.015 0.05 0.9 0.55], ...
    'SelectionChangedFcn', @changeFrequencyUnits);

addGUIComp('SDE_frqBtns_grp_op1Btn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.SDE_frqBtns_grp_mstr, ...
    'Tag', 'normalFreq', ...
    'Style', 'radiobutton', ...
    'String', 'Normalized Frequency', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0 0.60 0.9 0.35]);

addGUIComp('SDE_frqBtns_grp_op2Btn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.SDE_frqBtns_grp_mstr, ...
    'Tag', 'standardFreq', ...
    'Style', 'radiobutton', ...
    'String', 'Standard Frequency', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0 0.10 0.9 0.35]);

% Analyze Button
addGUIComp('SDE_anlzBtns');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.SDE_pnl, ...
    'String','Analyze', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0.65 0.10 0.29 0.25], ...
    'Callback', @spectralAnalysis);
%%

%% Filter Design Panel
addGUIComp('filtDesg_pnl');
setLastGUIComp( ...
	'Type', 'uipanel', ...
    'Parent', filterAxes.fig, ... 
    'Title', 'Filter Design', ...
    'Units', 'normalized', ...
    'Position', [0.8000 0.6450 0.1820 0.2200]);

% Filter Type
addGUIComp('filtDesg_desgMeth_txt');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Style', 'text', ...
    'String', 'Design Method', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0210 0.8735 0.3300 0.085]);

addGUIComp('filtDesg_desgMeth_grp_mstr');
setLastGUIComp( ...
	'Type', 'uibuttongroup', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Tag', 'designMethodGroup', ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.3750 0.88 0.575 0.085], ...
    'SelectionChangedFcn', @changeFilterDesignMethod);

addGUIComp('filtDesg_desgMeth_grp_filtBtn1');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_desgMeth_grp_mstr, ...
    'Tag', 'fir1', ...
    'Style', 'radiobutton', ...
    'String', 'fir1', ...
    'Units', 'normalized', ...
    'Position', [0 0 0.30 1]);

addGUIComp('filtDesg_desgMeth_grp_filtBtn2');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_desgMeth_grp_mstr, ...
    'Tag', 'Custom', ...
    'Style', 'radiobutton', ...
    'String', 'Custom', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.35 0 0.45 1]);

% fir1 Filter Parameters
addGUIComp('filtDesg_fir1_filtTypeTxt');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Style', 'text', ...
    'String', 'Type', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.7335 0.15 0.085]);

addGUIComp('filtDesg_fir1_filtTypeSet');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Tag', 'fir1FilterType', ...
    'Style', 'popupmenu', ...
    'String', {'Lowpass', 'Highpass', 'Bandpass', 'Bandstop', 'DC-0', 'DC-1'}, ...
    'Value', fir1FilterTypeValue, ...
    'Units', 'normalized', ...
    'Position', [0.177 0.6685 0.4 0.085], ...
    'Callback', @fir1FilterTypeHandler);

addGUIComp('filtDesg_fir1_filtOrdTxt');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Style', 'text', ...
    'String', 'Order', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.5935 0.15 0.085]);

addGUIComp('filtDesg_fir1_filtOrdSet');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Tag', 'fir1FilterOrder', ...
    'Style', 'edit', ...
    'String', num2str(fir1FiltOrd), ...
    'Units', 'normalized', ...
    'Position', [0.177 0.5800 0.5 0.105]);

addGUIComp('filtDesg_fir1_filtWnTxt');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Style', 'text', ...
    'String', 'wn', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.4535 0.1 0.085]);

addGUIComp('filtDesg_fir1_filtWnSet');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Tag', 'fir1FilterFreq', ...
    'Style', 'edit', ...
    'String', num2str(fir1FiltFreq), ...
    'Units', 'normalized', ...
    'Position', [0.177 0.4435 0.5 0.105]);

addGUIComp('filtDesg_fir1_filtDataBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'String', 'Filter', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.3135 0.29 0.085], ...
    'Callback', @fir1FilterData);

% Data Display Control
addGUIComp('filtDesg_showOrig_txt');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Style', 'text', ...
    'String', 'Show Orig. Data', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0210 0.1935 0.3700 0.0700]);

addGUIComp('filtDesg_showOrig_grp_mstr');
setLastGUIComp( ...
	'Type', 'uibuttongroup', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Tag', 'showOriginalDataButtonGroup', ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.4120 0.1435 0.5500 0.1600], ...
    'SelectionChangedFcn', @modifyDataDisplay);

addGUIComp('filtDesg_showOrig_grp_yBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_showOrig_grp_mstr, ...
    'Tag', 'origOn', ...
    'Style', 'radiobutton', ...
    'String', 'Yes', ...
    'Units', 'normalized', ...
    'Position', [0 0 0.32 1]);

addGUIComp('filtDesg_showOrig_grp_nBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_showOrig_grp_mstr, ...
    'Tag', 'origOff', ...
    'Style', 'radiobutton', ...
    'String', 'No', ...
    'Units', 'normalized', ...
    'Position', [0.404 0 0.26 1]);

addGUIComp('filtDesg_showOrig_grp_nBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Style', 'text', ...
    'String', 'Show Filtered Data', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0210 0.0535 0.3300 0.0700]);

addGUIComp('filtDesg_showFilt_grp_mstr');
setLastGUIComp( ...
	'Type', 'uibuttongroup', ...
    'Parent', filterGUI.filtDesg_pnl, ...
    'Tag', 'showFilteredDataButtonGroup', ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.4120 0.0035 0.5500 0.1600], ...
    'SelectionChangedFcn', @modifyDataDisplay);

addGUIComp('filtDesg_showFilt_grp_yBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_showFilt_grp_mstr, ...
    'Tag', 'filtOn', ...
    'Style', 'radiobutton', ...
    'String', 'Yes', ...
    'Units', 'normalized', ...
    'Position', [0 0 0.32 1]);

addGUIComp('filtDesg_showFilt_grp_nBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.filtDesg_showFilt_grp_mstr, ...
    'Tag', 'filtOff', ...
    'Style', 'radiobutton', ...
    'String', 'No', ...
    'Units', 'normalized', ...
    'Position', [0.404 0 0.26 1]);
%%

%% Filter Manifest Display
addGUIComp('manifDisp_pnl');
setLastGUIComp( ...
	'Type', 'uipanel', ...
    'Parent', filterAxes.fig, ... 
    'Title', 'Filter Manifest Entry Viewer', ...
    'Units', 'normalized', ...
    'Position', [0.8000 0.5090 0.1820 0.129]);

addGUIComp('manifDisp_txt_filtMeth');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Style', 'text', ...
    'String', 'Filter Method', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.7421 0.2900 0.1850]);

addGUIComp('manifDisp_txt_filtType');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Style', 'text', ...
    'String', 'Filter Type', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.5221 0.2400 0.1850]);

addGUIComp('manifDisp_txt_filtOrd');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Style', 'text', ...
    'String', 'Filter Order', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.2721 0.2600 0.1850]);

addGUIComp('manifDisp_txt_wn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Style', 'text', ...
    'String', 'Filter wn', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.0322 0.2050 0.1850]);

% Values
addGUIComp('manifDisp_txt_filtMethVal');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.7421 0.4150 0.1850]);

addGUIComp('manifDisp_txt_filtTypeVal');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.5221 0.4150 0.1850]);

addGUIComp('manifDisp_txt_filtOrdVal');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.2721 0.4150 0.1850]);

addGUIComp('manifDisp_txt_wnVal');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.0322 0.4150 0.1850]);

% Set default values
addGUIComp('manifDisp_Btn_setDefs');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'String', 'Set Default', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.6250 0.2625 0.3500 0.2500], ...
    'Callback', @setDefFiltVals);

addGUIComp('manifDisp_Btn_clrDefs');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'String', 'Clear Default', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.6250 0.0125 0.3500 0.2500], ...
    'Callback', @clearDefaultFilterValues);
%%

%% General Operations (Save, reset, etc)
addGUIComp('genOps_pnl');
setLastGUIComp( ...
	'Type', 'uipanel', ...
    'Parent', filterAxes.fig, ... 
    'BorderType', 'none', ...
    'Units', 'normalized', ...
    'Position', [0.8000 0.4700 0.1820 0.028]);

addGUIComp('genOps_saveBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.genOps_pnl, ...
    'String', 'Save', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0 0.0150 0.4800 0.9545], ...
    'Callback', @saveFilteredData);

addGUIComp('genOps_rstBtn');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.genOps_pnl, ...
    'String', 'Reset', ...
    'Units', 'normalized', ...
    'Position', [0.5200 0.0150 0.4800 0.9545], ...
    'Callback', @resetDataFiltering);

addGUIComp('genOps_varTbl');
setLastGUIComp( ...
	'Type', 'uitable', ...
    'Parent', filterAxes.fig, ...
    'Unit', 'normalized', ...
    'Position', [0.8000, 0.06500, 0.1800, 0.4000],...
    'ColumnName', {'Variable Name', 'Filtered?'}, ...
    'ColumnWidth', {100, 'auto'}, ...
    'CellSelectionCallback', @initPlot);
%%

%% Concluding GUI Initilization Tasks
% ---------------------------------------------------------------------------------------------------------------------------
%
% Assign axes titles
title(filterAxes.axes1, 'Original/Filtered Signal');
title(filterAxes.axes2, 'Power Spectral Density');

% Assign generic X and Y labels for axes
set([filterAxes.axes1.XLabel, filterAxes.axes2.XLabel], 'String', 'Unassigned'); %Frequencies (Hz.)
set([filterAxes.axes1.YLabel, filterAxes.axes2.YLabel], 'String', 'Unassigned'); %String', 'Power/Frequency (dB/Hz)

% Assign major and minor X and Y grids for axes.
plotProps.XGrid = 'on';
plotProps.YGrid = 'on';
plotProps.XMinorGrid = 'on';
plotProps.YMinorGrid = 'on';
set([filterAxes.axes1, filterAxes.axes2], plotProps);

% Get list of variables contained within MAT-file specified to be read by this script/GUI
varList = getVariablesToFilter();

% Correct the placement of the filter type textbox.
fir1FilterTypeBoxHeight = filterGUI.filtDesg_fir1_filtTypeSet.Extent(4);
fir1FilterTypeBoxDistFromBottom = filterGUI.filtDesg_fir1_filtTypeSet.Position(2);
filterGUI.filtDesg_fir1_filtTypeSet.Position(2) = fir1FilterTypeBoxDistFromBottom + fir1FilterTypeBoxHeight;

% Find the underling Java object reference of the spectral analysis textbox(es) and set a keypress callback so that later
% the entered contents may be readily read by the script without having to press enter following entry.
filterGUI.SDE_dcmtn_fctrSetObj = findjobj(filterGUI.SDE_dcmtn_fctrSet);

set(filterGUI.SDE_dcmtn_fctrSetObj, 'KeyPressedCallback', @decimateHandler);

% Find the underling Java object reference of the fir1 filter design textboxes and set a keypress callback so that later the
% entered contents may be readily read by the script without having to press enter following entry.
filterGUI.filtDesg_fir1_filtOrdSetObj = findjobj(filterGUI.filtDesg_fir1_filtOrdSet);
filterGUI.filtDesg_fir1_filtWnSetObj = findjobj(filterGUI.filtDesg_fir1_filtWnSet);

set(filterGUI.filtDesg_fir1_filtOrdSetObj, 'KeyPressedCallback', @fir1FiltOrdHandler);
set(filterGUI.filtDesg_fir1_filtWnSetObj, 'KeyPressedCallback', @fir1FiltFreqHandler);

findGUI = [findGUIComps(filterGUI, 'SDE_'); findGUIComps(filterGUI, 'filtDesg_fir1_')]
disp('hey')
%

%% Corresponding Nested Functions
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% initPlot() - Populate GUI's axes with selected signal's data
    % -----------------------------------------------------------------------------------------------------------------------
    function initPlot(hObject, eventData, handles) %#ok<INUSD,INUSL>
        % Quick check if data is filtered
        isDataFiltered = strcmp(string(eventData.Source.Data(eventData.Indices(1,1),2)), 'Yes');
        
        % Very shady hack to quickly fix a bug regarding accidentally overwriting varName.
        tempName = varList{eventData.Indices(1,1)};
        
        % Check if just reviewing a filter manifest entry
        if eventData.Indices(1,2) == 2
            if isDataFiltered
                updateManifestDisplay();
                return
            end
            % Else... Carry on, have a good day.
        end
        
        % See if user is switching data file variables
        varNameOld = varName;
        
        % Get name of variable user has selected and then load data for it
        varName = varList{eventData.Indices(1,1)};
        originalData = m.(varName);
        
        % Check if this is the user's first variable selection. If it is, proceed to initial signal plotting. If not, user
        % is switching fromone variable to the other, and script must reset.
        if ~isempty(varNameOld) && ~strcmp(varNameOld, varName)
            resetManifestdisplay();
            resetSpectralAnalysis();
            resetFilterData();
        end
        
        % Plot variable's time-series data
        filterAxes.p1.XData = m.NormTime;
        filterAxes.p1.YData = originalData;
        
        % Determine y-axis representation using variable name/type
        if contains(varName,'sg')
            yLabelString = 'Strain Gauge Reading (uStrain)';
        elseif contains(varName,['wp','LVDT'])
            yLabelString = 'Displacement Reading (in.)';
        elseif contains(varName,'LC')
            yLabelString = 'Load Cell Reading (lbf.)';
        else 
            yLabelString = 'Unknown Secondary Axis Title';
        end
        
        % Update titles to reflect variable chosen and data presented
        title(filterAxes.axes1, sprintf('Plot of %s vs. Normal Time', varName));
        filterAxes.axes1.XLabel.String = 'Time (sec)';
        filterAxes.axes1.YLabel.String = yLabelString;
        
        % Make sure the correct options are avaliable
        filterGUI.SDE_dcmtn_btn.Enable = 'Off';
        filterGUI.filtDesg_fir1_filtDataBtn.Enable = 'Off';
        filterGUI.SDE_anlzBtns.Enable = 'On';
        
        if isDataFiltered
            updateManifestDisplay();
        end
        
        % Quick fix to correct filter button dissapearing once a default is set and then a different record is chosen
        if all([~isempty(fir1FilterType), ~isempty(fir1FilterTypeValue), ~isempty(fir1FiltOrd), ~isempty(fir1FiltFreq)])
            filterGUI.filtDesg_fir1_filtDataBtn.Enable = 'on';
        end
    end

    %% spectralAnalysis() - Generate SDE for selected signal
    % -----------------------------------------------------------------------------------------------------------------------
    function spectralAnalysis(hObject, eventData, handles)    %#ok<INUSD>
        disableUIComp(filterGUI.SDE_anlzBtns);
        % Get sampling frequency.
        if contains(fileVariables, 'importManifest')
            % Horrible method, because it assumes all files were imported with same parameters as the first file.
            importManifest = m.importManifest;
            if importManifest(1).decimationFactor > 0
                Fs = (1/importManifest(1).decimationFactor)*importManifest.blockRate;
            else
                Fs = importManifest.blockRate;
            end
        else
            Fs = 1/(m.NormTime(2,1)-m.NormTime(1,1));
        end
        
        % See if decimated data is being analyzed and adjust sampling frequency accordingly. If not, use original data
        if isempty(modifiedData)
            dataFocus = originalData - mean(originalData);
        else
           dataFocus = modifiedData - mean(modifiedData);
           Fs = (1/decimationFactor)*Fs;
        end
        
        % Set signal constants    
        L = length(dataFocus)-1;	% Length of signal

        % Run Fast Fourier Transform
        fftRun = fft(dataFocus);
        
        % Calculate power spectral density
        psd = fftRun.*conj(fftRun)/L;
        
        %[maxValue,indexMax] = max(abs(fftRun))
        
        % Calculate normalized frequency in terms of pi*rad/samples. A good explanation is found at
        % https://dsp.stackexchange.com/a/16017. Essentially, take the frequency in Hertz, multiply it by 2, then devide
        % by the sampling frequency in hertz.
        f = ((Fs/L).*(0:ceil(L/2)-1))./(Fs/2);
        
        % Set plot data
        filterAxes.p3.XData = f(1,1:ceil(L/2));
        filterAxes.p3.YData = psd(1:ceil(L/2),1);
        
        % Set plot titles.
        title(filterAxes.axes2, sprintf('Power Spectral Density of %s', varName));
        filterAxes.axes2.XLabel.String = 'Normalized Frequency  (\times\pi rad/sample)';
        filterAxes.axes2.YLabel.String = 'Power';
        
        % Ensure proper feature options are avaliable now.
        set([filterGUI.SDE_frqBtns_grp_op1Btn, filterGUI.SDE_frqBtns_grp_op2Btn], 'Enable', 'On');
        enableUIComp(filterGUI.SDE_anlzBtns);
    end

    %% decimateHandler() - Handles validation of user input and activation of the signal data decimation feature
    % -----------------------------------------------------------------------------------------------------------------------
    function decimateHandler(hObject, eventData, handles) %#ok<INUSD>
        % Handles input validation, setting decimation factor, and updating decimate button. Fail-safe for disabled decimate
        % button if decimation factor is invalid.
        if ~isempty(originalData) && isDecimateInpValid(eventData.getKeyCode)
            % Valid character for decimation factor entered, set decimation factor
            setDecimationFactor(hObject);
            
            % Check for valid decimation factor, and display decimate button if so
            if isDecimateValid(decimationFactor)
                enableUIComp(filterGUI.SDE_dcmtn_btn);
            end
        else
            % Fail-safe to decimate box disabled
            disableUIComp(filterGUI.SDE_dcmtn_btn);
        end
        
        if eventData.getKeyCode == 10 && isDecimateValid(decimationFactor)
            % Check if enter-key was pressed in editbox and that decimation factor is valid. If so, decimate.
            decimateData();
        end
    end

    %% decimateData() - Decimates the selected signal's data
    % -----------------------------------------------------------------------------------------------------------------------
    function decimateData(hObject, eventData, handles) %#ok<INUSD>
        % Deactivates the decimate button until decimation is complete
        disableUIComp(filterGUI.SDE_dcmtn_btn)

        % Ensure decimation factor is valid before continuing
        if ~isDecimateValid(decimationFactor)
            return
        end
        
        % Proceed with decimating data, then automatically perform a spectral analysis
        modifiedData = decimate(originalData, decimationFactor);
        spectralAnalysis();
        
        % Re-enable decimate button
        enableUIComp(filterGUI.SDE_dcmtn_btn)
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function changeFrequencyUnits(hObject, eventData, handles) %#ok<INUSD,INUSL>
        switch eventData.NewValue.Tag
            case 'standardFreq'
                f = ((Fs/L)*(0:ceil(L/2)-1));
                filterAxes.axes2.XLabel.String = 'Frequency (Hz)';
            case 'normalFreq'
                f = (2*((Fs/L)*(0:ceil(L/2)-1)))/Fs;
                filterAxes.axes2.XLabel.String = 'Normalized Frequency  (\times\pi rad/sample)';
        end
        
        filterAxes.p3.XData = f(1,1:ceil(L/2));
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function changeFilterDesignMethod(hObject, eventData, handles) %#ok<INUSD,INUSL>
        filtDesg_fir1Handles = findGUIComps(filterGUI,'filtDesg_fir1');
        switch eventData.NewValue.Tag
            case 'fir1'
                set(filtDesg_fir1Handles, 'Visible', 'On');
            case 'Custom'
                set(filtDesg_fir1Handles, 'Visible', 'Off');
        end
    end

%% FIR1 Filter Functions
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% fir1FilterTypeHandler() - Handler for fir1 filter type popupmenu
    % -----------------------------------------------------------------------------------------------------------------------
    function fir1FilterTypeHandler(hObject, eventData, handles) %#ok<INUSD>
        setFir1FiltType(hObject);
        
        if isFir1FiltDesgValid()
            enableUIComp(filterGUI.filtDesg_fir1_filtDataBtn);
        end     
    end

    %% fir1FiltOrdHandler() - Handler for fir1 filter order editbox
    % -----------------------------------------------------------------------------------------------------------------------
    function fir1FiltOrdHandler(hObject, eventData, handles) %#ok<INUSD>
        % Check if keyboard input is valid
        if isfir1FiltOrdInpValid(eventData.getKeyChar)
            % Valid, so set fir1 filter order global
            setFir1FiltOrd(hObject.getText)
            
            % Check if this input alongside with other filter design parameters are valid, and activate the 'Filter' button
            if isFir1FiltDesgValid()
                enableUIComp(filterGUI.filtDesg_fir1_filtDataBtn);
                
                % Now check the Enter-key was pressed and, if so, filter data
                if eventData.getKeyCode == 10
                    fir1FiltHandler();
                end
                
                % No need for failsafe
                return
            end
        end
        
        % Fail-safe to disabling 'Filter' button
        disableUIComp(filterGUI.filtDesg_fir1_filtDataBtn);
    end

    %% fir1FiltFreqHandler() - Handler for fir1 filter frequency editbox
    % -----------------------------------------------------------------------------------------------------------------------
    function fir1FiltFreqHandler(hObject, eventData, handles) %#ok<INUSD>
        % Check if keyboard input is valid
        if isfir1FiltFreqInpValid(eventData.getKeyChar)
            % Valid keyboard entry, validate the freqency editbox contents, and set related global variables accordingly
            [fir1FiltFreqs, fir1FiltType] = validateFir1FiltFreq(hObject.getText);
            
            if ~isempty(fir1FiltFreqs) && fir1FiltType ~= 0
                setFir1FiltFreq(fir1FiltFreqs);
                setFir1FiltFreqType(fir1FiltType);
            else
                % Make sure 'Filter' button remains disabled, return control to parent function
                disableUIComp(filterGUI.filtDesg_fir1_filtDataBtn);
                return
            end
            
            % Check if this input alongside with other filter design parameters are valid, and activate the 'Filter' button
            if isFir1FiltDesgValid()
                enableUIComp(filterGUI.filtDesg_fir1_filtDataBtn);
                
                % Now check the Enter-key was pressed and, if so, filter data
                if eventData.getKeyCode == 10
                    fir1FiltHandler();
                end
            end
            
            return
        end
        
        % Fail-safe to disabling 'Filter' button
        disableUIComp(filterGUI.filtDesg_fir1_filtDataBtn);
    end

    %% fir1FiltHandler() - Handles prerequisites prior to designing fir1 filter to filter signal data with
    % -----------------------------------------------------------------------------------------------------------------------
    function fir1FiltHandler(hObject, eventData, handles) %#ok<INUSD>
        if isFir1FiltDesgValid()
            fir1FilterData();
        else
            % Somehow in this function by mistake. Disable filter button.
            filterGUI.filtDesg_fir1_filtDataBtn.Enable = 'Off';
        end
    end

    %% fir1FilterData() - Design filter using fir1 and use it to filter selected signal data
    % -----------------------------------------------------------------------------------------------------------------------
    function fir1FilterData(hObject, eventData, handles) %#ok<INUSD>
        % Quick check to make sure the required conditions for filtering are met and that we're not here by mistake.
        if ~isFir1FiltDesgValid()
            return
        end
        
        % Disable filter button until design and application of filter is complete.
        disableUIComp(filterGUI.filtDesg_fir1_filtDataBtn)
        
        % Design fir1 filter
        b = fir1(fir1FiltOrd, fir1FiltFreq, fir1FilterType);
        
        % filter signal
        filteredData = filtfilt(b,1,originalData);
        
        % Update GUI
        filterAxes.p2.XData = m.NormTime;
        filterAxes.p2.YData = filteredData;
        
        % Re-activate the filter button and also allow the user to filtered signal
        enableUIComp(filterGUI.filtDesg_fir1_filtDataBtn)
        enableUIComp(filterGUI.genOps_saveBtn);
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function modifyDataDisplay(hObject, eventData, handles) %#ok<INUSD,INUSL>
        %orig data, filt data, legend addition
        switch eventData.NewValue.Tag
            case 'origOn'
                filterAxes.p1.Visible = 'On';
            case 'origOff'
                filterAxes.p1.Visible = 'Off';
            case 'filtOn'
                filterAxes.p2.Visible = 'On';
            case 'filtOff'
                filterAxes.p2.Visible = 'Off';
        end
    end

    %% saveFilteredData() - Replaces variable of selected signal data with its filtered version
    % -----------------------------------------------------------------------------------------------------------------------
    function saveFilteredData(hObject, eventData, handles) %#ok<INUSD>
        %Don't forget to include a legacy script/upgrade for old filter method....
        
        if ismember('filterManifest', fileVariables)
            load(fullFilename, 'filterManifest');
        else
            filterManifest = [];
            save(fullFilename, 'filterManifest', '-append');
        end
        
        filterManifest.(varName) = struct('filterMethod', 'fir1', 'filterType', fir1FilterType, 'filterOrder', ...
            fir1FiltOrd, 'wn', fir1FiltFreq, 'Fpass', [], 'Fstop', [], 'Ap', [], 'Ast', []);
        
        m.filterManifest = filterManifest;
        m.(varName) = filteredData;
        
        %A lazy way to assure data saved, and that the variable list now
        %reflects the variable's been filtered, but is computational
        %expensive considering.
        varList = getVariablesToFilter();
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function resetDataFiltering(hObject, eventData, handles) %#ok<INUSD>
        %Used to reset the most significant components of the GUI without
        %physically restarting the GUI.
        resetSpectralAnalysis();
        resetFilterData();
        originalData = [];
        varList = getVariablesToFilter();
        %clearData();
        %Step2_DatafilterGUI();
    end

    %% clearData() - Function to clear graphics objects when closing GUI
    % -----------------------------------------------------------------------------------------------------------------------
    function clearData(hObject, eventData, handles) %#ok<INUSD>
        %Function used when users closes GUI. This assures that all data is deleted, and that nothing is left behind.
         delete(filterAxes.fig)
         clear
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function resetSpectralAnalysis( ~ )
        %First, clear old graphic data
        filterAxes.p3.XData = NaN;
        filterAxes.p3.YData = NaN;
        title(filterAxes.axes2, 'Power Spectral Density');
        set([filterAxes.axes1.XLabel, filterAxes.axes2.YLabel], 'String', 'Unassigned');
        
        %Next, Remove old values
        modifiedData = [];
        decimationFactor = 0;
        filterGUI.SDE_dcmtn_fctrSet.String = '';
        
        %Last, reset feature options.
        set([filterGUI.SDE_frqBtns_grp_op1Btn, filterGUI.SDE_frqBtns_grp_op2Btn], 'Enable', 'Off');
        filterGUI.SDE_frqBtns_grp_op1Btn.Selected = 'On';
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function resetFilterData( ~ )
        %First, clear old graphic data
        set([filterAxes.p1, filterAxes.p2], {'XData','YData'}, {NaN,NaN});
        set([filterAxes.p1, filterAxes.p2], 'Visible', 'On');
        title(filterAxes.axes1, 'Original/Filtered Signal');
        set([filterAxes.axes1.XLabel, filterAxes.axes2.YLabel], 'String', 'Unassigned');
        
        %Next, Remove old values
        filteredData = [];
        filterGUI.filtDesg_fir1_filtTypeSet.Value = fir1FilterTypeValue;
        set([filterGUI.filtDesg_fir1_filtOrdSet, filterGUI.filtDesg_fir1_filtWnSet], {'String'}, ...
            {num2str(fir1FiltOrd); num2str(fir1FiltFreq)});
        
        %Last, reset feature options.
        set([filterGUI.filtDesg_desgMeth_grp_filtBtn1, filterGUI.filtDesg_showOrig_grp_yBtn, ...
            filterGUI.filtDesg_showFilt_grp_yBtn], 'Selected', 'On');
        set([filterGUI.filtDesg_fir1_filtDataBtn, filterGUI.genOps_saveBtn], 'Enable', 'Off');
    end

    %% getVariablesToFilter() - Gets variables containing signal data and eligable for filtering from list of MAT-File vars
    % -----------------------------------------------------------------------------------------------------------------------
    function varList = getVariablesToFilter()  
        if ismember('filterManifest', fileVariables)
            load(fullFilename, 'filterManifest');
            filterStatus = 1;
        else
            filterStatus = 0;
        end
        
        s = 1;
        for r = 1:size(fileVariables,1)
            if any(strcmp(fileVariables{r},doNotFilter))
                continue
            end
            
            if filterStatus == 1 && isfield(filterManifest, fileVariables(r))
                isFiltered = 'Yes';
            else
                isFiltered = 'No';
            end
            
            varList(s,1:2) = [fileVariables(r) isFiltered]; %#ok<AGROW>
            
            s = s+1;
        end
        
        filterGUI.genOps_varTbl.Data = varList;
        
    end

    %% checkForLegacyManifest() - Alert user if data was previously filtered using legacy filter GUI
    % -----------------------------------------------------------------------------------------------------------------------
    function checkForLegacyManifest()
        % If there is not a legacy filter manifest present, continue with initializing filter. Otherwise, alert user of past
        % filtering using legacy systems, and also omitt legacy filter manifest from signal viewer.
        if ~ismember('filterParameters', fileVariables)
            return
        end
        
        warndlg(['A filter manifest generated using a deprecated version of this GUI has been detected.', ...
            'Proceed with extreme caution. Data may already be filtered regardless of signal viewer status.'], ...
            'Legacy Filter Manifest Present');
        doNotFilter{1,(size(doNotFilter,2)+1)} = 'filterParameters';
    end

    %% updateManifestDisplay() - Updates filter manifest record of selected signal
    % -----------------------------------------------------------------------------------------------------------------------
    function updateManifestDisplay()
        %Turn on relevent UIControls
        set(allchild(filterGUI.manifDisp_pnl), 'Visible', 'on');
        
        %Enable Set button
        enableUIComp(filterGUI.manifDisp_Btn_setDefs);
        
        manifestDispUIHandles = findall(filterGUI.manifDisp_pnl, 'Tag', 'value');
        manifestValues = {num2str(filterManifest.(tempName).wn); ...
            num2str(filterManifest.(tempName).filterOrder); ...
            filterManifest.(tempName).filterType; ...
            filterManifest.(tempName).filterMethod};
        
        switch manifestValues{3}
            case 'low'
                manifestValues{3} = 'Lowpass';
            case 'high'
                manifestValues{3} = 'Highpass';
            case 'bandpass'
                manifestValues{3} = 'Bandpass';
            case 'stop'
                manifestValues{3} = 'Bandstop';
            case 'dc0'
                manifestValues{3} = 'DC-0';
            case 'dc1'
                manifestValues{3} = 'DC-1';
            otherwise
                manifestValues{3} = 'Unknown';
        end
        
        %Set was behaving strangley, so I opted for a loop for time.
        for r = 1:4
            manifestDispUIHandles(r).String = manifestValues(r);
        end
    end

    %% resetManifestdisplay() - Resets/hides the contents of the filter manifest panel
    % -----------------------------------------------------------------------------------------------------------------------
    function resetManifestdisplay()
        manifestUIDispHandles = allchild(filterGUI.manifDisp_pnl);
        set(manifestUIDispHandles, 'Visible', 'off')
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function setDefFiltVals(hObject, eventData, handles) %#ok<INUSD>
        switch filterManifest.(tempName).filterType
            case 'low'
                fir1FilterTypeValue = 1;
            case 'high'
                fir1FilterTypeValue = 2;
            case 'bandpass'
                fir1FilterTypeValue = 3;
            case 'stop'
                fir1FilterTypeValue = 4;
            case 'dc0'
                fir1FilterTypeValue = 5;
            case 'dc1'
                fir1FilterTypeValue = 6;
            otherwise
                % Uh-oh
        end
        
        fir1FilterType = filterManifest.(tempName).filterType;
        fir1FiltOrd  = filterManifest.(tempName).filterOrder;
        fir1FiltFreq = filterManifest.(tempName).wn;
        
        filterGUI.filtDesg_fir1_filtTypeSet.Value = fir1FilterTypeValue;
        filterGUI.filtDesg_fir1_filtOrdSet.String = num2str(fir1FiltOrd);
        filterGUI.filtDesg_fir1_filtWnSet.String = num2str(fir1FiltFreq);
        
        set([filterGUI.filtDesg_fir1_filtDataBtn, filterGUI.manifDisp_Btn_clrDefs], ...
            'Enable', 'on');
    end

    %% 
    % -----------------------------------------------------------------------------------------------------------------------
    function clearDefaultFilterValues(hObject, eventData, handles) %#ok<INUSD>
        fir1FilterType      = 'low';
        fir1FilterTypeValue = 1;
        fir1FiltOrd         = [];
        fir1FiltFreq        = [];
        
        filterGUI.manifDisp_Btn_clrDefs.Enable = 'off';
    end

%% Modification of GUI figure properties
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% resizeProtection() - Figure resize correcting function and dimensional requirements enforcement
    % -----------------------------------------------------------------------------------------------------------------------
    function resizeProtection(hObject, eventData, handles) %#ok<INUSD>
        % Two major functions performed by this function. See below.
        
        %Get position of FilterGUI fig in pixels
        currentFigurePosPixels = getpixelposition(filterAxes.fig);
        
        % 1) A very lackadaisical/non-deterministic way of assuring that the GUI is not shrunk down to a size that obscures
        %    the view of features/options. Note that his could cause the close button to be outside the display area of the 
        %    screen display, but displays with a resolution of 1280x1024 aren't prevelent, especially on the Auburn 
        %    University Campus.
        %
        %    In summary, it is both not worth the effort or overcoming my laziness to actually determine the true dimensions 
        %    at which the GUI becomes too small. Literally, it takes a lot of effort the way that MATLAB defines these parameters.
        
        %If width is smaller than that specified, resize to minimum width
        if currentFigurePosPixels(3) < 1245
            filterAxes.fig.OuterPosition(3) = 1280;
        end
        
        %If height is smaller than that specified, resize to minimum height
        if currentFigurePosPixels(4) < 922
            filterAxes.fig.OuterPosition(4) = 1024;
        end
        
        %Get position of FilterGUI fig in pixels again since resizing in 1) may have taken place.
        currentFigurePosPixels = getpixelposition(filterAxes.fig);

        % 2) A somewhat dirty, yet still efficient, method of preserving the aspect ratios of UI Panels when the GUI is
        %    resized for whatever reason. Note that the 1264 value is the width (in pixels) of the GUI figure used to obtain
        %    the normalized positions used. Development initially took place on a computer with a Dell 1908FPb display with
        %    a set resolution of 1280x1024 and scaling at 100% in Windows 7.
        UIPanelHandles = findobj(0, 'Type', 'uipanel', '-or', 'Type', 'uitable');
        
        for r = 1:size(UIPanelHandles,1)
            resizedPanelWidthPos = (UIPanelHandles(r).Position(3)*originalFigurePosPixels(3))/currentFigurePosPixels(3);
            resizedPanelHeightPos = (UIPanelHandles(r).Position(4)*originalFigurePosPixels(4))/currentFigurePosPixels(4);
            
            UIPanelHandles(r).Position(3:4) = [resizedPanelWidthPos, resizedPanelHeightPos];
        end
        
        %Update to reflect size change
        originalFigurePosPixels = currentFigurePosPixels;
    end

    %% extendedDataCursor() - Custom Data Cursor
    % -----------------------------------------------------------------------------------------------------------------------
    function output_txt = extendedDataCursor(obj,event_obj) %#ok<INUSL>
        % Display the position of the data cursor
        % obj          Currently not used (empty)
        % event_obj    Handle to event object
        % output_txt   Data cursor text string (string or cell array of strings).
        
        pos = get(event_obj,'Position');
        di = get(event_obj,'DataIndex');
        if event_obj.Target.Parent == filterAxes.axes2
            
            freqHz = (di-1) * (Fs/L);
            if decimationFactor > 1
                freqWn = freqHz * (2/(Fs*decimationFactor));
            else
                freqWn = freqHz * (2/Fs);
            end
            
            %Provides frequency output as if we had not decimated. This is
            %to help delineate frequencies. Decimation allows a deeper look
            %into frequencies without the noise of our big data, so relate
            %back to what we're actually working with.
            output_txt = {['X: ',num2str(pos(1),10)],...
                ['Y: ',num2str(pos(2),10)],...
                ['Index: ',num2str(di)], ...
                ['Freq (Hz): ',num2str(freqHz)], ...
                ['Wn (pi rad/samp): ', num2str(freqWn)]};
        elseif event_obj.Target.Parent == filterAxes.axes1
            output_txt = {['X: ',num2str(pos(1),10)],...
                ['Y: ',num2str(pos(2),10)],...
                ['Index: ',num2str(di)]};
        end

    end

%% GUIComp Wrapper & UI Control Related Functions
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% addGUIComp() - Add GUIComp
    % -----------------------------------------------------------------------------------------------------------------------
    function addGUIComp(GUICompName)
        %UNTITLED4 Summary of this function goes here
        %   Detailed explanation goes here
            filterGUI(1,1).(GUICompName) = gobjects(1,1);
    end

    %% getLastGUIComp() - Gets the name of the last GUI component added
    % -----------------------------------------------------------------------------------------------------------------------
    function lastGUIComp = getLastGUIComp()
        listOfGUIComps = fieldnames(filterGUI);
        lastGUIComp = listOfGUIComps{end,:};
    end

    %% setLastGUIComp() - Initialize and set most recently created GUI component
    % -----------------------------------------------------------------------------------------------------------------------
    function setLastGUIComp(varargin)
        lastGUIComp = getLastGUIComp();
        
        switch varargin{2}
            case 'uicontrol'
                filterGUI.(lastGUIComp) = uicontrol(varargin{3:end});
            case 'uibuttongroup'
                filterGUI.(lastGUIComp) = uibuttongroup(varargin{3:end});
            case 'uipanel'
                filterGUI.(lastGUIComp) = uipanel(varargin{3:end});
            case 'uitable'
                filterGUI.(lastGUIComp) = uitable(varargin{3:end});
            otherwise
                error('Invalid UI object type specified. See help for more info.')
        end
    end

    %% setGUIComp() - Initialize and set specific GUI component
    % -----------------------------------------------------------------------------------------------------------------------
    function setGUIComp(varargin) %#ok<DEFNU>
        %
    end

    %% findGUIComps() - Generate arrays of graphical handles for manipulating components en masse
    % Notes:
    %   - Placeholder. See /libCommonFxns/findGUIComps.m or type 'help findGUIComps' for use.
    % -----------------------------------------------------------------------------------------------------------------------
    % Placeholder. See /libCommonFxns/findGUIComps.m or type 'help findGUIComps' for use.

    %% enableUIComp() - Enables specified uicontrol object
    % Notes: Created function for mundane task so as to have a method for future behavior expansion.
    % -----------------------------------------------------------------------------------------------------------------------
    function enableUIComp(obj)
        objProperties = set(obj);
        
        if isfield(objProperties, 'Enable') && any(contains(objProperties.Enable,'on'))
            obj.Enable = 'on';
            drawnow
        else
            % May add error trapper in future
            return
        end
    end

    %% disableUIComp() - Disables specified uicontrol object
    % Notes: Created function for mundane task so as to have a method for future behavior expansion.
    % -----------------------------------------------------------------------------------------------------------------------
    function disableUIComp(obj)
        objProperties = set(obj);
        
        if isfield(objProperties, 'Enable') && any(contains(objProperties.Enable,'off'))
            obj.Enable = 'off';
            drawnow
        else
            % May add error trapper in future
            return
        end
    end

%% Data type conversion
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% javastr2double() - str2double for java.lang.string types
    % -----------------------------------------------------------------------------------------------------------------------
    function outp = javastr2double(inp)
        outp = str2double(char(inp));
    end

    %% javastr2num() - str2num for java.lang.string types
    % -----------------------------------------------------------------------------------------------------------------------
    function outp = javastr2num(inp) %#ok<DEFNU>
        outp = str2num(char(inp)); %#ok<ST2NM>
    end

%% Input Validation Functions
% Function naming convention: Fxns are prefixed with 'is' if fxn checks for validity, while fxns are prefixed with "validate"
% if fxn validates something.
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% isSignalSelected() - Determines if a signal has been selected and its corresponding data loaded
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isSignalSelected()
        flag = ~isempty(originalData);
    end

    %% isDecimateInpValid() - Determines if keyboard input for decimation factor is valid 
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isDecimateInpValid(inputStr)
        flag = ~isempty(inputStr) && any(ismember(inputStr,[8, 48:57, 96:105]));
    end

    %% isDecimateValid() - Determines if the decimation factor entered is valid
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isDecimateValid(inputStr)
        flag = ~isempty(inputStr) && ~isnan(inputStr) && isnumeric(inputStr) && isscalar(inputStr) && sign(inputStr) == 1;
    end

    %% isFir1FiltTypeValid() - Determines if selected fir1 filter type is valid
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isFir1FiltTypeValid(varargin)
        if nargin >= 1 % Check if specified string is valid
            flag = any(strcmp(varargin{1},{'low','high','bandpass','stop','dc0','dc1'}));
        else % Check if defined filter type global variable is valid
            flag = any(strcmp(fir1FilterType,{'low','high','bandpass','stop','dc0','dc1'}));
        end
    end

    %% isfir1FiltOrdInpValid - Determines if keyboard input for fir1 filter order is valid
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isfir1FiltOrdInpValid(inputStr)
        % Allow backspace, enter, 0-9 alphanumeric keys, and 0-9 numpad
        allowedChars = [8, 10 48:57, 96:105];
        
        flag = ~isempty(inputStr) && ismember(inputStr,allowedChars);
    end

    %% isfir1FiltOrdValid() - Determines if the fir1 filter order is valid
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isfir1FiltOrdValid()
        % Use sign() == 1 to check if fir1 filter order is greater than 0 (ergo, positive and nonzero)
        flag = ~isempty(fir1FiltOrd) && ~isnan(fir1FiltOrd) && isreal(fir1FiltOrd) && isscalar(fir1FiltOrd) && isWholeNum(fir1FiltOrd) ...
            && sign(fir1FiltOrd) == 1;
    end


    %% isfir1FiltFreqInpValid() - Determines if keyboard input for fir1 filter frequency is valid
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isfir1FiltFreqInpValid(inputStr)
        % Allow backspace, enter, space, comma, alphanumeric period, numpad period, 0-9 alphanumeric keys, 
        % opening bracket ([}, closing bracket (]), and 0-9 numpad
        allowedChars = [8, 10, 32, 44, 46, 110 48:57, 91, 93, 96:105];
        
        flag = ~isempty(inputStr) && ismember(inputStr,allowedChars);
    end
    
    %% isfir1FiltFreqInpValid() - Determines if keyboard input for fir1 filter frequency is valid
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isfir1FiltFreqValid()
        flag = fir1FiltFreqType ~= 0 && ~isempty(fir1FiltFreq);
    end

    %% validateFir1FiltFreq() - Validation for fir1 filter frequencies
    % -----------------------------------------------------------------------------------------------------------------------
    function [fir1FiltFreqs, fir1FiltType] = validateFir1FiltFreq(inputStr)
        % TMK, str2num is the easiest way to do this. Controlled enviroment mitigates any security risk as well.
        fir1FiltFreqs = str2num(inputStr); %#ok<ST2NM>
        
        % Check that input is valid
        if isempty(fir1FiltFreqs) || ~isreal(fir1FiltFreqs)
            fir1FiltFreqs = [];
            fir1FiltType = 0;
            return
        end
        
        % Force row array just to be safe
        fir1FiltFreqs = reshape(fir1FiltFreqs',1,[]);
        
        % Determine if frequency(ies) is/are between 0 and 1,
        if ~all(fir1FiltFreqs > 0) || ~all(fir1FiltFreqs < 1)
            fir1FiltFreqs = [];
            fir1FiltType = 0;
            return
        end
        
        fir1FiltFreqsLength = length(fir1FiltFreqs);
        
        % Make sure if multiple frequencies are present that they are monotonically increasing
        if fir1FiltFreqsLength > 1 && any(diff(fir1FiltFreqs)<=0)
            fir1FiltFreqs = [];
            fir1FiltType = 0;
            return
        end
        
        % Determine type
        if fir1FiltFreqsLength == 1 % lowpass/highpass filter
            fir1FiltType = 1;
        elseif fir1FiltFreqsLength == 2 % bandpass/bandstop filter
            fir1FiltType = 2;
        elseif fir1FiltFreqsLength >= 3 % multiband filter
            fir1FiltType = 3;
        else % Fail-safe (error)
            fir1FiltFreqs = [];
            fir1FiltType = 0;
            return
        end
    end

    %% isFir1FiltFreqTypeCompatible() - Determines if the filter type inferred by the specified fir1 filter frequency(ies)
    %                                   are in agreement with the filter type chosen in the filter type popupmenu
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isFir1FiltFreqTypeCompatible()        
        if fir1FiltFreqType == 1 && any(strcmp(fir1FilterType, {'low','high'}))
            flag = true;
        elseif fir1FiltFreqType == 2 && any(strcmp(fir1FilterType, {'bandpass','stop'}))
            flag = true;
        elseif fir1FiltFreqType == 3 && any(strcmp(fir1FilterType, {'dc0','dc1'}))
            flag = true;
        else
            flag = false;
        end
    end

    %% isFir1FiltDesgValid() - Returns whether the fir1 filter design parameters are valid and filtering prereqs met
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isFir1FiltDesgValid()
        flag = isFir1FiltTypeValid() && isfir1FiltOrdValid() && isfir1FiltFreqValid() && isFir1FiltFreqTypeCompatible() ...
            && isSignalSelected();
    end

    %% isWholeNum() - Determines whether input is a whole number
    % Notes: 
    %   - Accepts numeric arrays and unreal numbers. Returns false for nonnumeric, NaN, (+/-)Inf, or non-whole numbers.
    %   - The method used to determine if the input argument is a whole number (inputStr == floor(inputStr)) is significantly
    %     faster than mod() or rem() based methods and contains fewer behavioral quarks. However, it does fail for NaN or 
    %     (+/-)Inf values and, when combined with validation against those cases, is only a slight improvement. Moreover,
    %     non-numeric input can cause this method to fail and, once isnumeric() is included, performance decreases to roughly
    %     ~20% less than mod() or rem() based methods. Regardless, the general stability of the chosen method's behavior
    %     and the simplicity of its use in this script ultimatly influenced its use here.
    % -----------------------------------------------------------------------------------------------------------------------
    function flag = isWholeNum(inputStr)
        flag = isnumeric(inputStr) && ~isnan(inputStr) && ~isinf(inputStr) && (inputStr == floor(inputStr));
    end
%

%% Set variable functions
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% setDecimationFactor() - Set decimation factor global variable
    % -----------------------------------------------------------------------------------------------------------------------
    function setDecimationFactor(hObject)
        decimationFactor = javastr2double(hObject.getText);
    end
    
    %% setFir1FiltType() - Set fir1 filter type global variable
    % -----------------------------------------------------------------------------------------------------------------------
    function setFir1FiltType(hObject)
        switch hObject.String{hObject.Value}
            case 'Lowpass'
                fir1FilterType = 'low';
            case 'Highpass'
                fir1FilterType = 'high';
            case 'Bandpass'
                fir1FilterType = 'bandpass';
            case 'Bandstop'
                fir1FilterType = 'stop';
            case 'DC-0'
                fir1FilterType = 'dc0';
            case 'DC-1'
                fir1FilterType = 'dc1';                
            otherwise
                warning('Invalid fir1 filter type')
        end
    end
    
    %% setFir1FiltOrd - Set fir1 filter order global variable
    % -----------------------------------------------------------------------------------------------------------------------    
    function setFir1FiltOrd(inputStr)
        if isa(inputStr, 'java.lang.String')
            % If the input is a java reference, perform appropriate conversion. It is assumed that this contains validated due to
            % validation that occurs prior to invoking this function in such circumstances.
            fir1FiltOrd = javastr2double(inputStr);
        else
            % Ortherwise, assume properly validated and typecast variable being input, and assign directly to global.
            fir1FiltOrd = inputStr;
        end
    end

    %% setFir1FiltFreq() - Set fir1 filter frequency(ies) global variable
    % -----------------------------------------------------------------------------------------------------------------------
    function setFir1FiltFreq(inputStr)
        fir1FiltFreq = inputStr;
    end

    %% setFir1FiltFreqType() - Set fir1 filter type global variable that corresponds with the frequency(ies) specified
    % -----------------------------------------------------------------------------------------------------------------------
    function setFir1FiltFreqType(inputStr)
        fir1FiltFreqType = inputStr;
    end
end % end for Step2_DataFilterGUI() function

%
%
%
%
%
%
%
%
%
%
%
%
%
%
%