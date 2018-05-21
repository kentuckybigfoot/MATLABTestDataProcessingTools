function Step2_DataFilterGUI
%Step2_DataFilterGUI Filter signals contained within imported experimental data.
%   Raw experimental test data imported into MAT-file format using Step1_ImportRAWFiles.m or Step1_ImportASCIIFiles.m may
%   be filtered using this graphical user interface (GUI). Features include the review, spectral analysis, and filtering of
%   individual signals contained within the variables of imported data files. See appropriate help files.
%
%   Copyright 2016-2018 Christopher L. Kerner.
%

%Initialize suite
%initializeSuite(mfilename('fullpath'))

fileDir = ''; %Directory file is located in
filename = 'FS Testing - ST3 - Test 1 - 08-24-16'; %Name of file to be filtered

%List of variables to be ignored when generating table of variables present within file.
doNotFilter = {'NormTime', 'Run', 'importManifest', 'filterManifest', 'filterParameter', 'A', 'B', 'C', 'D', ...
    'E', 'F', 'G', 'H'}; 

fullFilename = fullfile(fileDir,filename);

m = matfile(fullFilename, 'Writable', true);
fileVariables = who('-file', fullFilename);

% Check if signals were previously filtered using legacy system.
checkForLegacyManifest();

%Dimensions of figure script was developed using initially (See resizeProtection function below)
originalFigurePosPixels = [9 9 1264 931];

%General script variables
filterManifest = [];

%General records regarding data being filtered.
varList       = [];
varName       = [];
tempName      = [];
originalData  = [];
modifiedData  = [];
filteredData  = [];

%Initial DSP values to assure globalism and etc.
Fs = 0;              % Sampling frequency                    
T  = 0;  %#ok<NASGU> % Sampling period       
L  = 0;              % Length of signal
t  = 0;  %#ok<NASGU> % Time vector
decimationFactor = NaN;

%fir1 Filter Constants
fir1FilterType      = 'low';
fir1FilterTypeValue = 1;
fir1Order           = [];
fir1Freq            = [];

%Custom Filter Design Constants
Fpass = [];
Fstop = [];
Ap    = [];
Ast   = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create dialogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 0) General note: GUI component positions are normalized units unless otherwise modified later (as is the case with
%    UIPanels). Position related properties are 1-by-4 double arrays that follow the standard MATLAB position defintion
%    convention of [left, bottom, width, height].
% 1) create the GUI figure, then axes, followed by the appropriate lines
%    to populate axes. The variables are described as follows:
%       axes1 -> Filtering axes
%           * p1 -> original signal line
%           * p2 -> Filtered signal line
%       axes2 -> Spectral analysis axes
%           * p3 -> power spectral density line
%    Lastly, establish the extended data-cursor.
% 2) Define UI components under filterGUI.* structure where "*" is a wildcard.
% 3) Format axes (Apply titles, X & Y labels, X & Y major and minor grids)
% 4) Apply formatting to UI components that best applies once components are fully defined and visible. Used primarily for
%    assuring aspect ratios remain correct.
% 5) Generate variable list and popular corresponding UI Table.
% 6) Call it good, and eat fried balogna sandwiches. Optional arguments for a pat on the back. This isn't serious or funny.

%Define GUI figure
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
filterAxes.legend1 = legend(filterAxes.axes1, {'Orig. Data', 'Filt. Data'}, 'Location', 'Best');
filterAxes.legend1.Visible = 'Off';

%Assign data cursors
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

%Decimation
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

%Frequency Units
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

%Analyze Button
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

%Filter Type
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
    'Units', 'normalized', ...
    'Position', [0.35 0 0.45 1]);

%fir1 Filter Parameters
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
    'String', {'Lowpass', 'Highpass', 'Bandpass', 'Bandstop'}, ...
    'Value', fir1FilterTypeValue, ...
    'Units', 'normalized', ...
    'Position', [0.177 0.6685 0.4 0.085], ...
    'Callback', @fir1FilterHandler);

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
    'String', num2str(fir1Order), ...
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
    'String', num2str(fir1Freq), ...
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

%Data Display Control
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

%Values
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

%Set default values
addGUIComp('manifDisp_Btn_setDefs');
setLastGUIComp( ...
	'Type', 'uicontrol', ...
    'Parent', filterGUI.manifDisp_pnl, ...
    'String', 'Set Default', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.6250 0.2625 0.3500 0.2500], ...
    'Callback', @setDefaultFilterValues);

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

% Switch UI Panels' units to pixels and then set each a fixed width so that UI Panels retain aspect ratio on resize

display([getpixelposition(filterGUI.SDE_pnl); getpixelposition(filterGUI.filtDesg_pnl)]);

%Get list of variables contained within MAT-file specified to be read by this script/GUI
varList = getVariablesToFilter();

%Correct the placement of the filter type textbox.
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

set(filterGUI.filtDesg_fir1_filtOrdSetObj, 'KeyPressedCallback', @fir1FilterHandler);
set(filterGUI.filtDesg_fir1_filtWnSetObj, 'KeyPressedCallback', @fir1FilterHandler);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Corresponding Nested Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function initPlot(hObject, eventData, handles) %#ok<INUSD,INUSL>
        %Quick check if data is filtered
        isDataFiltered = strcmp(string(eventData.Source.Data(eventData.Indices(1,1),2)), 'Yes');
        
        %Very shady hack to quickly fix a bug regarding accidentally overwriting varName.
        tempName = varList{eventData.Indices(1,1)};
        
        %Check if just reviewing a filter manifest entry
        if eventData.Indices(1,2) == 2
            if isDataFiltered
                updateManifestDisplay();
                return
            end
            %Else... Carry on, have a good day.
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
        
        %Plot variable's time-series data
        filterAxes.p1.XData = m.NormTime;
        filterAxes.p1.YData = originalData;
        
        %Determine y-axis representation using variable name/type
        if contains(varName,'sg')
            yLabelString = 'Strain Gauge Reading (uStrain)';
        elseif contains(varName,['wp','LVDT'])
            yLabelString = 'Displacement Reading (in.)';
        elseif contains(varName,'LC')
            yLabelString = 'Load Cell Reading (lbf.)';
        else 
            yLabelString = 'Unknown Secondary Axis Title';
        end
        
        %Update titles to reflect variable chosen and data presented
        title(filterAxes.axes1, sprintf('Plot of %s vs. Normal Time', varName));
        filterAxes.axes1.XLabel.String = 'Time (sec)';
        filterAxes.axes1.YLabel.String = yLabelString;
        
        %Make sure the correct options are avaliable
        filterGUI.SDE_dcmtn_btn.Enable = 'Off';
        filterGUI.filtDesg_fir1_filtDataBtn.Enable = 'Off';
        filterGUI.SDE_anlzBtns.Enable = 'On';
        
        if isDataFiltered
            updateManifestDisplay();
        end
        
        %Quick fix to correct filter button dissapearing once a default is set and then a different record is chosen
        if all([~isempty(fir1FilterType), ~isempty(fir1FilterTypeValue), ~isempty(fir1Order), ~isempty(fir1Freq)])
            filterGUI.filtDesg_fir1_filtDataBtn.Enable = 'on';
        end
    end

    function spectralAnalysis(hObject, eventData, handles)    %#ok<INUSD>
        deactivateButton(filterGUI.SDE_anlzBtns);
        %Get sampling frequency.
        if contains(fileVariables, 'importManifest')
            %Horrible method, because it assumes all files were imported
            %with same parameters as the first file.
            importManifest = m.importManifest;
            if importManifest(1).decimationFactor > 0
                Fs = (1/importManifest(1).decimationFactor)*importManifest.blockRate;
            else
                Fs = importManifest.blockRate;
            end
        else
            Fs = 1/(m.NormTime(2,1)-m.NormTime(1,1));
        end
        
        %See if decimated data is being analyzed and adjust sampling frequency accordingly. 
        %If not, use original data
        if isempty(modifiedData)
            dataFocus = originalData - mean(originalData);
        else
           dataFocus = modifiedData - mean(modifiedData);
           Fs = (1/decimationFactor)*Fs;
        end
        
        %Set signal constants    
        L = length(dataFocus)-1;	% Length of signal

        %Run Fast Fourier Transform
        fftRun = fft(dataFocus);
        
        %Calculate power spectral density
        psd = fftRun.*conj(fftRun)/L;
        
        %[maxValue,indexMax] = max(abs(fftRun))
        
        %Calculate normalized frequency in terms of pi*rad/samples. A good explanation is found at
        %https://dsp.stackexchange.com/a/16017. Essentially, take the frequency in Hertz, multiply it by 2, then devide
        %by the sampling frequency in hertz.
        f = ((Fs/L).*(0:ceil(L/2)-1))./(Fs/2);
        
        %Set plot data
        filterAxes.p3.XData = f(1,1:ceil(L/2));
        filterAxes.p3.YData = psd(1:ceil(L/2),1);
        
        %Set plot titles.
        title(filterAxes.axes2, sprintf('Power Spectral Density of %s', varName));
        filterAxes.axes2.XLabel.String = 'Normalized Frequency  (\times\pi rad/sample)';
        filterAxes.axes2.YLabel.String = 'Power';
        
        %Ensure proper feature options are avaliable now.
        set([filterGUI.SDE_frqBtns_grp_op1Btn, filterGUI.SDE_frqBtns_grp_op2Btn], 'Enable', 'On');
        activateButton(filterGUI.SDE_anlzBtns);
    end

    function decimateHandler(hObject, eventData, handles) %#ok<INUSD>
        % Handles input validation, setting decimation factor, and updating decimate button. Fail-safe for disabled decimate
        % button if decimation factor is invalid.
        if ~isempty(originalData) && isDecimateInpValid(eventData.getKeyCode)
            % Valid character for decimation factor entered, set decimation factor
            setDecimationFactor(hObject);
            
            % Check for valid decimation factor, and display decimate button if so
            if isDecimateValid(decimationFactor)
                activateButton(filterGUI.SDE_dcmtn_btn);
            end
        else
            % Fail-safe to decimate box disabled
            deactivateButton(filterGUI.SDE_dcmtn_btn);
        end
        
        if eventData.getKeyCode == 10 && isDecimateValid(decimationFactor)
            % Check if enter-key was pressed in editbox and that decimation factor is valid. If so, decimate.
            decimateData();
        end
    end

    function decimateData(hObject, eventData, handles) %#ok<INUSD>
        % Deactivates the decimate button until decimation is complete
        deactivateButton(filterGUI.SDE_dcmtn_btn)

        % Ensure decimation factor is valid before continuing
        if ~isDecimateValid(decimationFactor)
            return
        end
        
        % Proceed with decimating data, then automatically perform a spectral analysis
        modifiedData = decimate(originalData, decimationFactor);
        spectralAnalysis();
        
        % Re-enable decimate button
        activateButton(filterGUI.SDE_dcmtn_btn)
    end

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
    function fir1FilterHandler(hObject, eventData, handles) %#ok<INUSD>
        % Handles input for fir1 filter parameters' editboxes.
        
        if superIsField(hObject, 'Tag') && strcmp(hObject.Tag, 'fir1FilterType')
            setFir1FilterType(hObject);
        elseif superIsField(hObject, 'Name')
            if isFir1InpValid(hObject, eventData.getKeyCode)
                switch hObject.Name
                    case 'fir1FilterOrder'
                        setFir1FilterOrder(hObject.getText);
                    case 'fir1FilterFreq'
                        setFir1FilterFreq(hObject.getText);
                end
            end
        else
            error('Unable to determine action to be performed.')
        end
        
        % Check if fir1 filter design parameters are valid. 
        % 	If filter parameters are valid, enable filter button and then filter data if enter button was pressed.
        % 	for all else otherwise, ensure that filter button is disabled.
        % Note the passing of the appropriate variable to each validation function. This was done to aid in extensibility.
        if ~isempty(originalData) && isFir1FilterTypeValid(fir1FilterType) && isFir1FilterOrderValid(fir1Order) ...
                && isFir1FilterFreqValid(fir1Freq)
            
            % Enable filter button
            filterGUI.filtDesg_fir1_filtDataBtn.Enable = 'On';
            
            % Filter data if enter button was pressed
            if superIsField(hObject, 'Name') && eventData.getKeyCode == 10
                fir1FilterData();
            end
        else
           % Disable filter button
           filterGUI.filtDesg_fir1_filtDataBtn.Enable = 'Off';
       end
    end

    function fir1FilterData(hObject, eventData, handles) %#ok<INUSD>
        % Quick check to make sure the required conditions for filtering are met.
        if isempty(originalData) || ~isFir1FilterTypeValid(fir1FilterType) || ~isFir1FilterOrderValid(fir1Order) ...
                || ~isFir1FilterFreqValid(fir1Freq)
            return
        end
        
        % Disable filter button until design and application of filter is complete.
        deactivateButton(filterGUI.filtDesg_fir1_filtDataBtn)
        
        % Design fir1 filter
        b = fir1(fir1Order, fir1Freq, fir1FilterType);
        
        % filter signal
        filteredData = filtfilt(b,1,originalData);
        
        % Update GUI
        filterAxes.p2.XData = m.NormTime;
        filterAxes.p2.YData = filteredData;
        
        % Re-activate the filter button and also allow the user to filtered signal
        activateButton(filterGUI.filtDesg_fir1_filtDataBtn)
        activateButton(filterGUI.genOps_saveBtn);
    end
%%

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
    
    %Created function for mundane task so as to have method for future behavior expansion.
    function deactivateButton(obj)
        obj.Enable = 'Off';
        drawnow
    end
    
    %Created function for mundane task so as to have method for future behavior expansion.
    function activateButton(obj)
        obj.Enable = 'On';
        drawnow
    end

    function saveFilteredData(hObject, eventData, handles) %#ok<INUSD>
        %Don't forget to include a legacy script/upgrade for old filter method....
        
        if ismember('filterManifest', fileVariables)
            load(fullFilename, 'filterManifest');
        else
            filterManifest = [];
            save(fullFilename, 'filterManifest', '-append');
        end
        
        filterManifest.(varName) = struct('filterMethod', 'fir1', 'filterType', fir1FilterType, 'filterOrder', fir1Order, 'wn', fir1Freq, 'Fpass', Fpass, 'Fstop', Fstop, 'Ap', Ap, 'Ast', Ast);
        
        m.filterManifest = filterManifest;
        m.(varName) = filteredData;
        
        %A lazy way to assure data saved, and that the variable list now
        %reflects the variable's been filtered, but is computational
        %expensive considering.
        varList = getVariablesToFilter();
    end

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

    function clearData(hObject, eventData, handles) %#ok<INUSD>
        %Function used when users closes GUI. This assures that all data is
        %deleted, and that nothing is left behind.
         delete(filterAxes.fig)
         clear
    end
 
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
            {num2str(fir1Order); num2str(fir1Freq)});
        
        %Last, reset feature options.
        set([filterGUI.filtDesg_desgMeth_grp_filtBtn1, filterGUI.filtDesg_showOrig_grp_yBtn, ...
            filterGUI.filtDesg_showFilt_grp_yBtn], 'Selected', 'On');
        set([filterGUI.filtDesg_fir1_filtDataBtn, filterGUI.genOps_saveBtn], 'Enable', 'Off');
    end

    function varList = getVariablesToFilter( ~ )  
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

    function checkForLegacyManifest()
        % If there is not a legacy filter manifest present, continue with initializing filter. Otherwise, alter user of past
        % filtering using legacy systems, and also omitt legacy filter manifest from signal viewer.
        if ~ismember('filterParameters', fileVariables)
            return
        end
        
        warndlg(['A filter manifest generated using a deprecated version of this GUI has been detected.', ...
            'Proceed with extreme caution. Data may already be filtered regardless of signal viewer status.'], ...
            'Legacy Filter Manifest Present');
        doNotFilter{1,(size(doNotFilter,2)+1)} = 'filterParameters';
    end

    function updateManifestDisplay()
        %Turn on relevent UIControls
        set(allchild(filterGUI.manifDisp_pnl), 'Visible', 'on');
        
        %Enable Set button
        activateButton(filterGUI.manifDisp_Btn_setDefs);
        
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
        end
        
        %Set was behaving strangley, so I opted for a loop for time.
        for r = 1:4
            manifestDispUIHandles(r).String = manifestValues(r);
        end
    end

    function resetManifestdisplay()
        manifestUIDispHandles = allchild(filterGUI.manifDisp_pnl);
        set(manifestUIDispHandles, 'Visible', 'off')
    end

    function setDefaultFilterValues(hObject, eventData, handles) %#ok<INUSD>
        switch filterManifest.(tempName).filterType
            case 'low'
                fir1FilterTypeValue = 1;
            case 'high'
                fir1FilterTypeValue = 2;
            case 'bandpass'
                fir1FilterTypeValue = 3;
            case 'stop'
                fir1FilterTypeValue = 4;
        end
        
        fir1FilterType = filterManifest.(tempName).filterType;
        fir1Order  = filterManifest.(tempName).filterOrder;
        fir1Freq = filterManifest.(tempName).wn;
        
        filterGUI.filtDesg_fir1_filtTypeSet.Value = fir1FilterTypeValue;
        filterGUI.filtDesg_fir1_filtOrdSet.String = num2str(fir1Order);
        filterGUI.filtDesg_fir1_filtWnSet.String = num2str(fir1Freq);
        
        set([filterGUI.filtDesg_fir1_filtDataBtn, filterGUI.manifDisp_Btn_clrDefs], ...
            'Enable', 'on');
    end

    function clearDefaultFilterValues(hObject, eventData, handles) %#ok<INUSD>
        fir1FilterType      = 'low';
        fir1FilterTypeValue = 1;
        fir1Order           = [];
        fir1Freq            = [];
        
        filterGUI.manifDisp_Btn_clrDefs.Enable = 'off';
    end

%% Modification of GUI figure properties

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

%% GUIComp Wrapper
%
    % Add GUIComp
    % --------------------------------------------------------------------------
    function addGUIComp(GUICompName)
        %UNTITLED4 Summary of this function goes here
        %   Detailed explanation goes here
            filterGUI(1,1).(GUICompName) = gobjects(1,1);
    end

    % Gets the name of the last GUI component added
    % --------------------------------------------------------------------------
    function lastGUIComp = getLastGUIComp()
        listOfGUIComps = fieldnames(filterGUI);
        lastGUIComp = listOfGUIComps{end,:};
    end

    % Initialize and set most recently created GUI component
    % --------------------------------------------------------------------------
    function setLastGUIComp(varargin)
        %UNTITLED4 Summary of this function goes here
        %   Detailed explanation goes here
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
                error('Invalid UI control type specified. See help for more info.')
        end
    end

    % Initialize and set specific GUI component
    % --------------------------------------------------------------------------

    % Generate arrays of graphical handles for manipulating components en masse
    % --------------------------------------------------------------------------
    % See /libCommonFxns/findGUIComps.m or type 'help findGUIComps' for use.
    
    % Handle specific set function that is tolerant of java objects
    % --------------------------------------------------------------------------
    function setGUIComp(varargin)
        %
    end
%

%% Data type conversion
%
    % Data type conversions from java types
    function outp = jstr2double(inp)
        outp = str2double(char(inp));
    end

    function outp = javaStr2Num(inp)
        outp = str2num(char(inp)); %#ok<ST2NM>
    end

%% Input Validation Functions
%
    % Validation functions for decimation features
    % --------------------------------------------------------------------------
    function flag = isDecimateInpValid(inputStr)
        flag = ~isempty(inputStr) && any(ismember(inputStr,[8, 48:57, 96:105]));
    end

    function flag = isDecimateValid(inputStr)
        flag = ~isempty(inputStr) && ~isnan(inputStr) && isnumeric(inputStr) && isscalar(inputStr) && sign(inputStr) == 1;
    end

    % Validation functions for fir1 filter features
    % --------------------------------------------------------------------------
    function flag = isFir1InpValid(hObject, inputStr)
        switch hObject.Name
            case 'fir1FilterOrder'
                allowedChars = [8, 48:57, 96:105];
            case 'fir1FilterFreq'
                allowedChars = [8, 32, 44, 46, 48:57, 91, 93, 96:105];
            otherwise
                error('Invalid means of invoking isFir1InpValid().');
        end
        
        flag = ~isempty(inputStr) && any(ismember(inputStr,allowedChars));
    end

    function flag = isFir1FilterTypeValid(inputStr)
        flag = any(strcmp(inputStr,{'low','high','bandpass','stop'}));
    end

    function flag = isFir1FilterOrderValid(inputStr)
        flag = ~isempty(inputStr) && ~isnan(inputStr) && isnumeric(inputStr) && isscalar(inputStr) ...
            && rem(inputStr,1) == 0 && sign(inputStr) == 1;
    end

    function flag = isFir1FilterFreqValid(inputStr)
        if all(strcmp(char(inputStr),{'[',']'})) %check if row or some shit
            % Welcome to the shit show
        else
            flag = ~isempty(inputStr) && ~isnan(inputStr) && isnumeric(inputStr) && isscalar(inputStr) ...
                && sign(inputStr) == 1 && inputStr > 0 && inputStr <= 1;
        end
    end
%

%% Set variable functions
%
    % Set Variable functions for spectral analysis
    % --------------------------------------------------------------------------
    function setDecimationFactor(hObject)
        decimationFactor = jstr2double(hObject.getText);
    end
    
    % Set variable functions for fir1 filter
    % --------------------------------------------------------------------------
    function setFir1FilterType(hObject)
        switch hObject.String{hObject.Value}
            case 'Lowpass'
                fir1FilterType = 'low';
            case 'Highpass'
                fir1FilterType = 'high';
            case 'Bandpass'
                fir1FilterType = 'bandpass';
            case 'Bandstop'
                fir1FilterType = 'stop';
            otherwise
                warning('Invalid fir1 filter type')
        end
    end

    function setFir1FilterOrder(inputStr)
    	fir1Order = jstr2double(inputStr);
    end

    function setFir1FilterFreq(inputStr)      
        if all(strcmp(inputStr,{'[',']'}))
            fir1Freq = jstr2num(inputStr);
        else
            fir1Freq = jstr2double(inputStr);
        end
    end
%
end