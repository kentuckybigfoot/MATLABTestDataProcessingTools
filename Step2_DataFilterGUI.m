function Step2_DataFilterGUI
%Step2_DataFilterGUI Filter signals contained within imported experimental data.
%   Raw experimental test data imported into MAT-file format using Step1_ImportRAWFiles.m or Step1_ImportASCIIFiles.m may
%   be filtered using this graphical user interface (GUI). Features include the review, spectral analysis, and filtering of
%   individual signals contained within the variables of imported data files. See appropriate help files.
%
%   Copyright 2016-2018 Christopher L. Kerner.
%

% Initialize suite
initializeSuite(mfilename('fullpath'))

fileDir = ''; %Directory file is located in
filename = 'FS Testing - ST3 - Test 1 - 08-24-16'; %Name of file to be filtered

% List of variables to be ignored when generating table of variables present within file.
doNotFilter = {'NormTime', 'Run', 'importManifest', 'filterManifest', 'filterParameter', 'A', 'B', 'C', 'D', ...
    'E', 'F', 'G', 'H'}; 

fullFilename = fullfile(fileDir,filename);

m = matfile(fullFilename, 'Writable', true);
fileVariables = who('-file', fullFilename);

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
T  = 0;  %#ok<NASGU> % Sampling period       
L  = 0;              % Length of signal
t  = 0;  %#ok<NASGU> % Time vector
decimationFactor = NaN;

% fir1 Filter Constants
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

%% Spectral Analysis Panel
filterGUI.spectralAnalysis.panel = uipanel( ...
    'Parent', filterAxes.fig, ... 
    'Title', 'Spectral Analysis Options', ...
    'Units', 'normalized', ...
    'Position', [0.8 0.872 0.182 0.1]);

%Decimation
filterGUI.spectralAnalysis.decimation.text = uicontrol( ...
    'Parent', filterGUI.spectralAnalysis.panel, ...
    'Style', 'text', ...
    'String', 'Decimate', ...
    'Units', 'normalized', ...
    'Position', [0.015 0.745 0.22 0.15]);

filterGUI.spectralAnalysis.decimation.textbox = uicontrol( ...
    'Parent', filterGUI.spectralAnalysis.panel, ...
    'Style', 'edit', ...
    'Tag', 'decFactor', ...
    'Units', 'normalized', ...
    'Position', [0.26 0.65 0.35 0.25], ...
    'KeyReleaseFcn', @enableDecimate);
    
filterGUI.spectralAnalysis.decimation.button = uicontrol( ...
    'Parent', filterGUI.spectralAnalysis.panel, ...
    'String','Decimate', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0.65 0.685 0.29 0.25], ...
    'Callback', @decimateData);


%Frequency Units
filterGUI.spectralAnalysis.freqButtons.group.master = uibuttongroup( ...
    'Parent', filterGUI.spectralAnalysis.panel, ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.015 0.05 0.9 0.55], ...
    'SelectionChangedFcn', @changeFrequencyUnits);

filterGUI.spectralAnalysis.freqButtons.group.option1Button = uicontrol( ...
    'Parent', filterGUI.spectralAnalysis.freqButtons.group.master, ...
    'Tag', 'normalFreq', ...
    'Style', 'radiobutton', ...
    'String', 'Normalized Frequency', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0 0.60 0.9 0.35]);

filterGUI.spectralAnalysis.freqButtons.group.option2Button = uicontrol( ...
    'Parent', filterGUI.spectralAnalysis.freqButtons.group.master, ...
    'Tag', 'standardFreq', ...
    'Style', 'radiobutton', ...
    'String', 'Standard Frequency', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0 0.10 0.9 0.35]);

%Analyze Button
filterGUI.spectralAnalysis.analyzeButton = uicontrol( ...
    'Parent', filterGUI.spectralAnalysis.panel, ...
    'String','Analyze', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0.65 0.10 0.29 0.25], ...
    'Callback', @spectralAnalysis);
%%

%% Filter Design Panel
filterGUI.filterDesign.panel = uipanel( ...
    'Parent', filterAxes.fig, ... 
    'Title', 'Filter Design', ...
    'Units', 'normalized', ...
    'Position', [0.8000 0.6450 0.1820 0.2200]);

%Filter Type
filterGUI.filterDesign.designMethodText = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Style', 'text', ...
    'String', 'Design Method', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0210 0.8735 0.3300 0.085]);

filterGUI.filterDesign.designMethod.group.master = uibuttongroup( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Tag', 'designMethodGroup', ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.3750 0.88 0.575 0.085], ...
    'SelectionChangedFcn', @changeFilterDesignMethod);

filterGUI.filterDesign.designMethod.group.filterButton1 = uicontrol( ...
    'Parent', filterGUI.filterDesign.designMethod.group.master, ...
    'Tag', 'fir1', ...
    'Style', 'radiobutton', ...
    'String', 'fir1', ...
    'Units', 'normalized', ...
    'Position', [0 0 0.30 1]);

filterGUI.filterDesign.designMethod.group.filterButton2 = uicontrol( ...
    'Parent', filterGUI.filterDesign.designMethod.group.master, ...
    'Tag', 'Custom', ...
    'Style', 'radiobutton', ...
    'String', 'Custom', ...
    'Units', 'normalized', ...
    'Position', [0.35 0 0.45 1]);

%fir1 Filter Parameters
filterGUI.filterDesign.fir1.filterTypeText = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Style', 'text', ...
    'String', 'Type', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.7335 0.15 0.085]);

filterGUI.filterDesign.fir1.filterTypeSelection = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Tag', 'fir1FilterType', ...
    'Style', 'popupmenu', ...
    'String', {'Lowpass', 'Highpass', 'Bandpass', 'Bandstop'}, ...
    'Value', fir1FilterTypeValue, ...
    'Units', 'normalized', ...
    'Position', [0.177 0.6685 0.4 0.085], ...
    'Callback', @fir1FilterConfig);

filterGUI.filterDesign.fir1.filterOrderText = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Style', 'text', ...
    'String', 'Order', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.5935 0.15 0.085]);

filterGUI.filterDesign.fir1.filterOrderTextBox = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Tag', 'fir1FilterOrder', ...
    'Style', 'edit', ...
    'String', num2str(fir1Order), ...
    'Units', 'normalized', ...
    'Position', [0.177 0.5800 0.5 0.105], ...
    'KeyReleaseFcn', @fir1FilterConfig);

filterGUI.filterDesign.fir1.filterWnText = uicontrol( ...+
    'Parent', filterGUI.filterDesign.panel, ...
    'Style', 'text', ...
    'String', 'wn', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.4535 0.1 0.085]);

filterGUI.filterDesign.fir1.filterWnTextBox = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Tag', 'fir1FilterFreq', ...
    'Style', 'edit', ...
    'String', num2str(fir1Freq), ...
    'Units', 'normalized', ...
    'Position', [0.177 0.4435 0.5 0.105], ...
    'KeyReleaseFcn', @fir1FilterConfig);

filterGUI.filterDesign.fir1.filterDataButton = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Tag', 'fir1FilterButton', ...
    'String', 'Filter', ...
    'Enable', 'Off', ...
    'Units', 'normalized', ...
    'Position', [0.021 0.3135 0.29 0.085], ...
    'Callback', @fir1FilterConfig);%@fir1FilterData);

%Data Display Control
filterGUI.filterDesign.showOriginalData.text = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Style', 'text', ...
    'String', 'Show Orig. Data', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0210 0.1935 0.3700 0.0700]);

filterGUI.filterDesign.showOriginalData.group.master = uibuttongroup( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Tag', 'showOriginalDataButtonGroup', ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.4120 0.1435 0.5500 0.1600], ...
    'SelectionChangedFcn', @modifyDataDisplay);

filterGUI.filterDesign.showOriginalData.group.yesButton = uicontrol( ...
    'Parent', filterGUI.filterDesign.showOriginalData.group.master, ...
    'Tag', 'origOn', ...
    'Style', 'radiobutton', ...
    'String', 'Yes', ...
    'Units', 'normalized', ...
    'Position', [0 0 0.32 1]);

filterGUI.filterDesign.showOriginalData.group.noButton = uicontrol( ...
    'Parent', filterGUI.filterDesign.showOriginalData.group.master, ...
    'Tag', 'origOff', ...
    'Style', 'radiobutton', ...
    'String', 'No', ...
    'Units', 'normalized', ...
    'Position', [0.404 0 0.26 1]);

filterGUI.filterDesign.showFilteredData.text = uicontrol( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Style', 'text', ...
    'String', 'Show Filtered Data', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0210 0.0535 0.3300 0.0700]);

filterGUI.filterDesign.showFilteredData.group.master = uibuttongroup( ...
    'Parent', filterGUI.filterDesign.panel, ...
    'Tag', 'showFilteredDataButtonGroup', ...
    'BorderWidth', 0, ...
    'Units', 'normalized', ...
    'Position', [0.4120 0.0035 0.5500 0.1600], ...
    'SelectionChangedFcn', @modifyDataDisplay);

filterGUI.filterDesign.showFilteredData.group.yesButton = uicontrol( ...
    'Parent', filterGUI.filterDesign.showFilteredData.group.master, ...
    'Tag', 'filtOn', ...
    'Style', 'radiobutton', ...
    'String', 'Yes', ...
    'Units', 'normalized', ...
    'Position', [0 0 0.32 1]);

filterGUI.filterDesign.showFilteredData.group.noButton = uicontrol( ...
    'Parent', filterGUI.filterDesign.showFilteredData.group.master, ...
    'Tag', 'filtOff', ...
    'Style', 'radiobutton', ...
    'String', 'No', ...
    'Units', 'normalized', ...
    'Position', [0.404 0 0.26 1]);
%%

%% Filter Manifest Display
filterGUI.filterManifestDisp.panel = uipanel( ...
    'Parent', filterAxes.fig, ... 
    'Title', 'Filter Manifest Entry Viewer', ...
    'Units', 'normalized', ...
    'Position', [0.8000 0.5090 0.1820 0.129]);

filterGUI.filterManifestDisp.text.filterMethod = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Style', 'text', ...
    'String', 'Filter Method', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.7421 0.2900 0.1850]);

filterGUI.filterManifestDisp.text.filterType = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Style', 'text', ...
    'String', 'Filter Type', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.5221 0.2400 0.1850]);

filterGUI.filterManifestDisp.text.filterOrder = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Style', 'text', ...
    'String', 'Filter Order', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.2721 0.2600 0.1850]);

filterGUI.filterManifestDisp.text.wn = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Style', 'text', ...
    'String', 'Filter wn', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.0150 0.0322 0.2050 0.1850]);

%Values
filterGUI.filterManifestDisp.text.filterMethodValue = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.7421 0.4150 0.1850]);

filterGUI.filterManifestDisp.text.filterTypeValue = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.5221 0.4150 0.1850]);

filterGUI.filterManifestDisp.text.filterOrderValue = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.2721 0.4150 0.1850]);

filterGUI.filterManifestDisp.text.wnValue = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'Tag', 'value', ...
    'Style', 'text', ...
    'HorizontalAlignment', 'left', ...
    'Units', 'normalized', ...
    'Position', [0.3350 0.0322 0.4150 0.1850]);

%Set default values
filterGUI.filterManifestDisp.button.setDefaults = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'String', 'Set Default', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.6250 0.2625 0.3500 0.2500], ...
    'Callback', @setDefaultFilterValues);

filterGUI.filterManifestDisp.button.clearDefaults = uicontrol( ...
    'Parent', filterGUI.filterManifestDisp.panel, ...
    'String', 'Clear Default', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0.6250 0.0125 0.3500 0.2500], ...
    'Callback', @clearDefaultFilterValues);
%%

%% General Operations (Save, reset, etc)
filterGUI.generalOperations.panel = uipanel( ...
    'Parent', filterAxes.fig, ... 
    'BorderType', 'none', ...
    'Units', 'normalized', ...
    'Position', [0.8000 0.4700 0.1820 0.028]);

filterGUI.generalOperations.saveButton = uicontrol( ...
    'Parent', filterGUI.generalOperations.panel, ...
    'String', 'Save', ...
    'Enable', 'off', ...
    'Units', 'normalized', ...
    'Position', [0 0.0150 0.4800 0.9545], ...
    'Callback', @saveFilteredData);

filterGUI.generalOperations.resetButton = uicontrol( ...
    'Parent', filterGUI.generalOperations.panel, ...
    'String', 'Reset', ...
    'Units', 'normalized', ...
    'Position', [0.5200 0.0150 0.4800 0.9545], ...
    'Callback', @resetDataFiltering);

filterGUI.generalOperations.variablesTable = uitable( ...
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

display([getpixelposition(filterGUI.spectralAnalysis.panel); getpixelposition(filterGUI.filterDesign.panel)]);

%Get list of variables contained within MAT-file specified to be read by this script/GUI
varList = getVariablesToFilter();

%Correct the placement of the filter type textbox.
fir1FilterTypeBoxHeight = filterGUI.filterDesign.fir1.filterTypeSelection.Extent(4);
fir1FilterTypeBoxDistFromBottom = filterGUI.filterDesign.fir1.filterTypeSelection.Position(2);
filterGUI.filterDesign.fir1.filterTypeSelection.Position(2) = fir1FilterTypeBoxDistFromBottom + fir1FilterTypeBoxHeight;

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
        
        %See if user is switching data file variables
        varNameOld = varName;
        
        %Get name of variable user has selected and then load data for it
        varName = varList{eventData.Indices(1,1)};
        originalData = m.(varName);
        
        %Check if this is the user's first variable selection. If it is,
        %proceed to initial signal plotting. If not, user is switching from
        %one variable to the other, and script must reset.
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
        filterGUI.spectralAnalysis.decimation.button.Enable = 'Off';
        filterGUI.filterDesign.fir1.filterDataButton.Enable = 'Off';
        filterGUI.spectralAnalysis.analyzeButton.Enable = 'On';
        
        if isDataFiltered
            updateManifestDisplay();
        end
        
        %Quick fix to correct filter button dissapearing once a default is set and then a different record is chosen
        if all([~isempty(fir1FilterType), ~isempty(fir1FilterTypeValue), ~isempty(fir1Order), ~isempty(fir1Freq)])
            filterGUI.filterDesign.fir1.filterDataButton.Enable = 'on';
        end
    end

    function spectralAnalysis(hObject, eventData, handles)    %#ok<INUSD>
        deactivateButton(filterGUI.spectralAnalysis.analyzeButton);
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
        set([filterGUI.spectralAnalysis.freqButtons.group.option1Button, filterGUI.spectralAnalysis.freqButtons.group.option2Button], 'Enable', 'On');
        activateButton(filterGUI.spectralAnalysis.analyzeButton);
    end

    function enableDecimate(hObject, eventData, handles) %#ok<INUSD,INUSL>
        if ~isempty(originalData)
            filterGUI.spectralAnalysis.decimation.button.Enable = 'On';
        end
        
        if strcmp(eventData.Key, 'return')
            decimateData();
        end     
    end

    function decimateData(hObject, eventData, handles) %#ok<INUSD>
        deactivateButton(filterGUI.spectralAnalysis.decimation.button)
        decimationFactor = str2double(filterGUI.spectralAnalysis.decimation.textbox.String);
        if decimationFactor > 1
            modifiedData = decimate(originalData, decimationFactor);
            spectralAnalysis();
        end
        activateButton(filterGUI.spectralAnalysis.decimation.button)
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
        switch eventData.NewValue.Tag
            case 'fir1'
                set([filterGUI.filterDesign.fir1.filterTypeText, filterGUI.filterDesign.fir1.filterTypeSelection, ...
                    filterGUI.filterDesign.fir1.filterOrderText, filterGUI.filterDesign.fir1.filterOrderTextBox, ...
                    filterGUI.filterDesign.fir1.filterWnText, filterGUI.filterDesign.fir1.filterWnTextBox, ...
                    filterGUI.filterDesign.fir1.filterDataButton], ...
                    'Visible', 'On');
            case 'Custom'
                set([filterGUI.filterDesign.fir1.filterTypeText, filterGUI.filterDesign.fir1.filterTypeSelection, ...
                    filterGUI.filterDesign.fir1.filterOrderText, filterGUI.filterDesign.fir1.filterOrderTextBox, ...
                    filterGUI.filterDesign.fir1.filterWnText, filterGUI.filterDesign.fir1.filterWnTextBox, ...
                    filterGUI.filterDesign.fir1.filterDataButton], ...
                    'Visible', 'Off');
        end
    end

    function fir1FilterConfig(hObject, eventData, handles)   %#ok<INUSD>
        [fir1FilterTypeTmp, fir1OrderTmp, fir1FreqTmp] = deal(fir1FilterType, fir1Order, fir1Freq);
        isDirectCall = false();
        
    	%Switch between which filter parameter was modified
        switch hObject.Tag
            case 'fir1FilterType'
                switch hObject.String{hObject.Value}
                    case 'Lowpass'
                        [fir1FilterType, fir1FilterTypeTmp] = deal('low');
                    case 'Highpass'
                        [fir1FilterType, fir1FilterTypeTmp] = deal('high');
                    case 'Bandpass'
                        [fir1FilterType, fir1FilterTypeTmp] = deal('bandpass');
                    case 'Stopband'
                        [fir1FilterType, fir1FilterTypeTmp] = deal('stop');
                end
            case 'fir1FilterOrder'
                fir1OrderTmp = str2double(hObject.String);
                
                if isnumeric(fir1OrderTmp)
                    fir1Order = fir1OrderTmp;
                else
                    fir1OrderTmp = [];
                end
            case 'fir1FilterFreq'
                fir1FreqTmp = str2double(hObject.String);
                
                if isnumeric(fir1FreqTmp)
                    fir1Freq = fir1FreqTmp;
                end
            case 'fir1FilterButton'
                isDirectCall = true();
        end
        
        if fir1IsReadyToFilter
            activateButton(filterGUI.filterDesign.fir1.filterDataButton)
            
            if isDirectCall || (isprop(eventData, 'Key') && strcmp(eventData.Key, 'return'))
                deactivateButton(filterGUI.filterDesign.fir1.filterDataButton)
                
                % Design filter
                b = fir1(fir1OrderTmp, fir1FreqTmp, fir1FilterTypeTmp);
                
                % Filter data
                filteredData = filtfilt(b,1,originalData);
                
                % Present filtered data
                filterAxes.p2.XData = m.NormTime;
                filterAxes.p2.YData = filteredData;
                
                % Active appropriate features' buttons
                activateButton(filterGUI.generalOperations.saveButton)
                activateButton(filterGUI.filterDesign.fir1.filterDataButton)
            end             
       else
           filterGUI.filterDesign.fir1.filterDataButton.Enable = 'Off';
       end
    end

    function isReadyToFilter = fir1IsReadyToFilter()
        if all([~isempty(fir1FilterType), ~isempty(fir1Order), ~isempty(fir1Freq)]) ...
                && all(~isnan([fir1FilterType, fir1Order, fir1Freq]))
            isReadyToFilter = true;
        else
            isReadyToFilter = false;
        end
    end
    %{
    function fir1FilterData(hObject, eventData, handles) %#ok<INUSD>
        deactivateButton(filterGUI.filterDesign.fir1.filterDataButton)
        if ~isempty(handles)
            b = fir1(fir1Order, fir1Freq, fir1FilterType);
        else
           b = fir1(fir1Order, fir1Freq, fir1FilterType);
        filteredData = filtfilt(b,1,originalData);
        
        filterAxes.p2.XData = m.NormTime;
        filterAxes.p2.YData = filteredData;
        
        filterGUI.generalOperations.saveButton.Enable = 'On';
        activateButton(filterGUI.filterDesign.fir1.filterDataButton)
    end
    %}
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
        filterGUI.spectralAnalysis.decimation.textbox.String = '';
        
        %Last, reset feature options.
        set([filterGUI.spectralAnalysis.freqButtons.group.option1Button, filterGUI.spectralAnalysis.freqButtons.group.option2Button], 'Enable', 'Off');
        filterGUI.spectralAnalysis.freqButtons.group.option1Button.Selected = 'On';
    end

    function resetFilterData( ~ )
        %First, clear old graphic data
        set([filterAxes.p1, filterAxes.p2], {'XData','YData'}, {NaN,NaN});
        set([filterAxes.p1, filterAxes.p2], 'Visible', 'On');
        title(filterAxes.axes1, 'Original/Filtered Signal');
        set([filterAxes.axes1.XLabel, filterAxes.axes2.YLabel], 'String', 'Unassigned');
        
        %Next, Remove old values
        filteredData = [];
        filterGUI.filterDesign.fir1.filterTypeSelection.Value = fir1FilterTypeValue;
        set([filterGUI.filterDesign.fir1.filterOrderTextBox, filterGUI.filterDesign.fir1.filterWnTextBox], {'String'}, ...
            {num2str(fir1Order); num2str(fir1Freq)});
        
        %Last, reset feature options.
        set([filterGUI.filterDesign.designMethod.group.filterButton1, filterGUI.filterDesign.showOriginalData.group.yesButton, ...
            filterGUI.filterDesign.showFilteredData.group.yesButton], 'Selected', 'On');
        set([filterGUI.filterDesign.fir1.filterDataButton, filterGUI.generalOperations.saveButton], 'Enable', 'Off');
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
        
        filterGUI.generalOperations.variablesTable.Data = varList;
        
    end
    
    function updateManifestDisplay()
        %Turn on relevent UIControls
        set(allchild(filterGUI.filterManifestDisp.panel), 'Visible', 'on');
        
        %Enable Set button
        filterGUI.filterManifestDisp.button.setDefaults.Enable = 'on';
        
        manifestDispUIHandles = findall(filterGUI.filterManifestDisp.panel, 'Tag', 'value');
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
                manifestValues{3} = 'Stopband';
        end
        
        %Set was behaving strangley, so I opted for a loop for time.
        for r = 1:4
            manifestDispUIHandles(r).String = manifestValues(r);
        end
    end

    function resetManifestdisplay()
        manifestUIDispHandles = allchild(filterGUI.filterManifestDisp.panel);
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
        
        filterGUI.filterDesign.fir1.filterTypeSelection.Value = fir1FilterTypeValue;
        filterGUI.filterDesign.fir1.filterOrderTextBox.String = num2str(fir1Order);
        filterGUI.filterDesign.fir1.filterWnTextBox.String = num2str(fir1Freq);
        
        set([filterGUI.filterDesign.fir1.filterDataButton, filterGUI.filterManifestDisp.button.clearDefaults], ...
            'Enable', 'on');
    end

    function clearDefaultFilterValues(hObject, eventData, handles) %#ok<INUSD>
        fir1FilterType      = 'low';
        fir1FilterTypeValue = 1;
        fir1Order           = [];
        fir1Freq            = [];
        
        filterGUI.filterManifestDisp.button.clearDefaults.Enable = 'off';
    end
    
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
end