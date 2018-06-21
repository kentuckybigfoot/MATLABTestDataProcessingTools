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
fileInfo = whos(m);
fileVariables = {fileInfo.name}.';

% Check if signals were previously filtered using legacy system.
checkForLegacyManifest();

% Dimensions of figure script was developed using initially (See resizeProtection() function below)
originalFigurePosPixels = [9 9 1264 931];

% General script variables
filterManifest = [];

% General records regarding data being filtered.
signalList    = [];
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
filterAxes.axes1 = axes('Parent', filterAxes.fig, 'Position', [0.0400, 0.5650, 0.7600, 0.4000]);
filterAxes.axes2 = axes('Parent', filterAxes.fig, 'Position', [0.0400, 0.0650, 0.7600, 0.4000]);
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

%% Create GUI Panels and related components
% ---------------------------------------------------------------------------------------------------------------------------
createSpectralAnalysisPnl()         % Spectral Analysis Options Panel
createFilterDesignPnl()             % Filter Design Panel
createFilterManifestDisplayPnl()    % Filter Manifest Display Panel
createGeneralOperationsPnl()        % General Operations Panel (Save, reset, etc)

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
plotProps.Box = 'on';
set([filterAxes.axes1, filterAxes.axes2], plotProps);

% Get list of variables contained within MAT-file specified to be read by this script/GUI
signalList = signalsListHandler();

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
        tempName = signalList{eventData.Indices(1,1)};
        
        % Check if just reviewing a filter manifest entry
        if eventData.Indices(1,2) == 2 && isDataFiltered
                updateManifestDisplay();
                return
        end
        
        % See if user is switching data file variables
        varNameOld = varName;
        
        % Get name of variable user has selected and then load data for it
        varName = signalList{eventData.Indices(1,1)};
        originalData = m.(varName);
        
        % Get current Tightinset to use later in preventing axis label clipping
        initTightInset = filterAxes.axes1.TightInset;
        
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
        
        % Adjust axis to remove whitespace
        axis(filterAxes.axes1, [min(m.NormTime)-250, max(m.NormTime)+250, filterAxes.axes1.YLim])
                
        % Determine y-axis representation using variable name/type
        if contains(varName,'sg')
            yLabelString = ['Strain Gauge Reading (',char(181),char(603),')'];
        elseif contains(varName,['wp','LVDT'])
            yLabelString = 'Displacement Reading (in.)';
        elseif contains(varName,'LC')
            yLabelString = 'Load Cell Reading (lbf)';
        else 
            yLabelString = 'Unknown Secondary Axis Title';
        end
        
        % Update titles to reflect variable chosen and data presented
        title(filterAxes.axes1, sprintf('Plot of %s vs. Normal Time', varName));
        filterAxes.axes1.XLabel.String = 'Time (sec)';
        filterAxes.axes1.YLabel.String = yLabelString;
        
        % Adjust left position and width of Signal Axes to prevent axis label clipping.
        if filterAxes.axes1.TightInset(1) > 0.04
            axesPos = [filterAxes.axes1.Position; filterAxes.axes2.Position];
            posIncr = (filterAxes.axes1.TightInset(1)-initTightInset(1));
            
            filterAxes.axes1.Position([1,3]) = [axesPos(1,1) + posIncr, axesPos(1,3) - posIncr];
            filterAxes.axes2.Position([1,3]) = [axesPos(2,1) + posIncr, axesPos(2,3) - posIncr];
        end
        
        % Make sure the correct options are avaliable
        enableGUIComp({'SDE_anlzBtns', 'filtDesg_fir1_filtTypeSet', 'filtDesg_fir1_filtOrdSet', 'filtDesg_fir1_filtWnSet'});
        disableGUIComp({'SDE_dcmtn_btn', 'filtDesg_fir1_filtDataBtn'});
        
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
        disableGUIComp('SDE_anlzBtns');
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
        filterAxes.axes2.XLabel.String = ['Normalized Frequency (\times',char(960),char(183),'rad/spl)'];
        filterAxes.axes2.YLabel.String = 'Power';
        
        % Ensure proper feature options are avaliable now.
        enableGUIComp({'SDE_frqBtns_grp_op1Btn', 'SDE_frqBtns_grp_op2Btn', 'SDE_anlzBtns'});
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
                enableGUIComp('SDE_dcmtn_btn');
            end
        else
            % Fail-safe to decimate box disabled
            disableGUIComp('SDE_dcmtn_btn');
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
        disableGUIComp('SDE_dcmtn_btn')

        % Ensure decimation factor is valid before continuing
        if ~isDecimateValid(decimationFactor)
            return
        end
        
        % Proceed with decimating data, then automatically perform a spectral analysis
        modifiedData = decimate(originalData, decimationFactor);
        spectralAnalysis();
        
        % Re-enable decimate button
        enableGUIComp('SDE_dcmtn_btn')
    end

    %% frequencyUnitsHandler() - Handles Spectral Analysis Options Panel toggling of unit of measure for frequency
    % -----------------------------------------------------------------------------------------------------------------------
    function frequencyUnitsHandler(hObject, eventData, handles) %#ok<INUSD,INUSL>
        switch eventData.NewValue.Tag
            case 'standardFreq'
                f = ((Fs/L)*(0:ceil(L/2)-1));
                filterAxes.axes2.XLabel.String = 'Frequency (Hz)';
            case 'normalFreq'
                f = (2*((Fs/L)*(0:ceil(L/2)-1)))/Fs;
                filterAxes.axes2.XLabel.String = ['Normalized Frequency (\times',char(960),char(183),'rad/spl)'];
        end
        
        filterAxes.p3.XData = f(1,1:ceil(L/2));
    end

    %% Not currently in use.
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
            enableGUIComp('filtDesg_fir1_filtDataBtn');
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
                enableGUIComp('filtDesg_fir1_filtDataBtn');
                
                % Now check the Enter-key was pressed and, if so, filter data
                if eventData.getKeyCode == 10
                    fir1FiltHandler();
                end
                
                % No need for failsafe
                return
            end
        end
        
        % Fail-safe to disabling 'Filter' button
        disableGUIComp('filtDesg_fir1_filtDataBtn');
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
                disableGUIComp('filtDesg_fir1_filtDataBtn');
                return
            end
            
            % Check if this input alongside with other filter design parameters are valid, and activate the 'Filter' button
            if isFir1FiltDesgValid()
                enableGUIComp('filtDesg_fir1_filtDataBtn');
                
                % Now check the Enter-key was pressed and, if so, filter data
                if eventData.getKeyCode == 10
                    fir1FiltHandler();
                end
            end
            
            return
        end
        
        % Fail-safe to disabling 'Filter' button
        disableGUIComp('filtDesg_fir1_filtDataBtn');
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
        disableGUIComp('filtDesg_fir1_filtDataBtn')
        
        % Design fir1 filter
        b = fir1(fir1FiltOrd, fir1FiltFreq, fir1FilterType);
        
        % filter signal
        filteredData = filtfilt(b,1,originalData);
        
        % Update GUI
        filterAxes.p2.XData = m.NormTime;
        filterAxes.p2.YData = filteredData;
        filterAxes.p2.Visible = 'On';
        
        % Re-activate the filter button and allow the user to filtered signal, also ensure enable viewer controls are enabled
        enableGUIComp({'filtDesg_fir1_filtDataBtn', 'genOps_saveBtn', 'filtDesg_showOrig_grp_yBtn', ...
            'filtDesg_showOrig_grp_nBtn', 'filtDesg_showFilt_grp_yBtn', 'filtDesg_showFilt_grp_nBtn'});
        setGUIComp('filtDesg_showFilt_grp_yBtn', 'Value', 1);
    end

    %% dataDisplayHandler() - Handles toggling the display of filtered/unfiltered signals
    % -----------------------------------------------------------------------------------------------------------------------
    function dataDisplayHandler(hObject, eventData, handles) %#ok<INUSD,INUSL>
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
        
        %A lazy way to assure data saved, and that the variable list now reflects the variable's been filtered
        signalList = signalsListHandler();
    end

    %% resetDataFiltering () - Resets the GUI
    % -----------------------------------------------------------------------------------------------------------------------
    function resetDataFiltering(hObject, eventData, handles) %#ok<INUSD>
        delete(filterAxes.fig)
        clear
        run([mfilename('fullpath'),'.m'])
    end

    %% clearData() - Function to clear data when closing GUI
    % -----------------------------------------------------------------------------------------------------------------------
    function clearData(hObject, eventData, handles) %#ok<INUSD>
         delete(filterAxes.fig)
         clear
    end

    %% resetSpectralAnalysis() - Resets all variables related to Spectral Analysis Panel
    % -----------------------------------------------------------------------------------------------------------------------
    function resetSpectralAnalysis()
        %First, clear old graphic data
        set(filterAxes.p3, {'XData','YData'}, {NaN,NaN});
        title(filterAxes.axes2, 'Power Spectral Density');
        set([filterAxes.axes2.XLabel, filterAxes.axes2.YLabel], 'String', 'Unassigned');
        
        %Next, Remove old values
        modifiedData = [];
        decimationFactor = 0;
        setGUIComp('SDE_dcmtn_fctrSet', 'String', '');
        
        %Last, reset feature options.
        disableGUIComp({'SDE_frqBtns_grp_op1Btn', 'SDE_frqBtns_grp_op2Btn'});
        setGUIComp('SDE_frqBtns_grp_op1Btn', 'Value', 1);
    end

    %% resetFilterData() - Resets Filter Design Panel and filtered data
    % -----------------------------------------------------------------------------------------------------------------------
    function resetFilterData()
        %First, clear old graphic data
        set([filterAxes.p1, filterAxes.p2], {'XData','YData'}, {NaN,NaN});
        set([filterAxes.p1, filterAxes.p2], 'Visible', 'On');
        title(filterAxes.axes1, 'Original/Filtered Signal');
        set([filterAxes.axes1.XLabel, filterAxes.axes2.YLabel], 'String', 'Unassigned');
        axis(filterAxes.axes1, 'auto');
        
        %Next, Remove old values
        filteredData = [];
        setGUIComp('filtDesg_fir1_filtTypeSet', 'Value', fir1FilterTypeValue);
        set([filterGUI.filtDesg_fir1_filtOrdSet, filterGUI.filtDesg_fir1_filtWnSet], {'String'}, ...
            {num2str(fir1FiltOrd); num2str(fir1FiltFreq)});
        
        %Last, reset feature options.
        setGUIComp({'filtDesg_desgMeth_grp_filtBtn1', 'filtDesg_showOrig_grp_yBtn', 'filtDesg_showFilt_grp_yBtn'}, ...
            'Value', 1);
        disableGUIComp({'filtDesg_fir1_filtDataBtn', 'genOps_saveBtn'});
    end

    %% signalsListHandler() - Handles Signals List content generation
    % -----------------------------------------------------------------------------------------------------------------------
    function signalList = signalsListHandler()
        % Create list of signals and preallocate filter status
        signalList = fileVariables;
        signalList(:,2) = {'No'};
        
        % If a filter manifest exists, load it, and then indicate which signals, if any, have been filtered.
        % Note that the method used to determine if a filter manifest is present is the fastest of 4 tested:
        % Case 1: 1st Exec - 2.543e-03, 1k Exec Mean - 4.809e-05, Method: ismember('filterManifest', fileVariables);
        % Case 2: 1st Exec - 1.387e-03, 1k Exec Mean - 1.207e-05, Method: any(contains(fileVariables,'filterManifest'));
        % Case 3: 1st Exec - 1.622e-03, 1k Exec Mean - 1.188e-04, Method: find(strcmp(fileVariables,'filterManifest'));
        % Case 4: 1st Exec - 1.312e-03, 1k Exec Mean - 9.438e-06, Method: any(strcmp(fileVariables,'filterManifest'));
        if any(strcmp(fileVariables,'filterManifest'))
            load(fullFilename, 'filterManifest');
            filtSgnls = fieldnames(filterManifest);
            filtSgnlsIdx = contains(fileVariables,filtSgnls);
            signalList(filtSgnlsIdx,2) = {'Yes'};
        end
        
        % Find entries in doNotFilter from Signals Viewer list. Note that interesect method is faster than ismember+cleanup
        [~,rmvSgnlIdx,~] = intersect(signalList,doNotFilter);
        
        % Find entries that are not vectors
        sgnlLstSz = vertcat(fileInfo.size);
        sgnlLstSzIdx = find(sgnlLstSz(:,2) > 1 & sgnlLstSz(:,2) > 1 | diff(sgnlLstSz,1,2) == 0);
        
        % Combine indices lists for non-vectorial and doNotFilter entries
        rmvIdx = union(sgnlLstSzIdx,rmvSgnlIdx);
        signalList(rmvIdx,:) = [];
        
        setGUIComp('genOps_varTbl', 'Data', signalList);
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
        enableGUIComp('manifDisp_Btn_setDefs');
        
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
        
        enableGUIComp({'filtDesg_fir1_filtDataBtn', 'manifDisp_Btn_clrDefs'});
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
        
        % Prevents invocation of this function upon initial script run.
        if currentFigurePosPixels(3:4) == originalFigurePosPixels(3:4)
            return
        end
        
        % 1) A very lackadaisical/non-deterministic way of assuring that the GUI is not shrunk down to a size that obscures
        %    the view of features/options. Ultimately, the effort, nor overcoming my laziness, are worth the time to actually
        %    determine the true dimensions at which the GUI becomes too small. Literally, it takes a lot of effort the way
        %    that MATLAB defines these parameters.
        %
        %    Note: This could cause the close button to be outside the display area of the screen display, but displays with
        %    a resolution of 1280x1024 aren't prevelent, especially on the Auburn University Campus.
        
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
        UIPnlObjs = findobj(0, 'Type', 'uipanel', '-or', 'Type', 'uitable');
        UIPnlObjsSize = size(UIPnlObjs,1);
        rszPnlChgs = zeros(UIPnlObjsSize,2);
        
        for r = UIPnlObjsSize:-1:1
            % Calculate new normalized positions
            resizedPanelWidthPos = (UIPnlObjs(r).Position(3)*originalFigurePosPixels(3))/currentFigurePosPixels(3);
            resizedPanelHeightPos = (UIPnlObjs(r).Position(4)*originalFigurePosPixels(4))/currentFigurePosPixels(4);
            resizedPanelLeftPos = UIPnlObjs(r).Position(1) + (UIPnlObjs(r).Position(3)-resizedPanelWidthPos);
            if r == UIPnlObjsSize
                resizedPanelBotPos = UIPnlObjs(r).Position(2) + (UIPnlObjs(r).Position(4)-resizedPanelHeightPos);
            else
                resizedPanelBotPos = (UIPnlObjs(r+1).Position(2) - 0.007) - resizedPanelHeightPos;
            end
            
            % Change in width to be used for resizing axes, height just for tracking
            rszPnlChgs(r,1:2) = [(UIPnlObjs(r).Position(3) - resizedPanelWidthPos), ...
                (UIPnlObjs(r).Position(4)-resizedPanelHeightPos)];
            
            % Apply new normalized positions
            UIPnlObjs(r).Position = [resizedPanelLeftPos, resizedPanelBotPos ,resizedPanelWidthPos, resizedPanelHeightPos];
        end
        
        % If all of the UI Panel objects were identically resized, correct size of axes
        if ~any(diff(rszPnlChgs(:,1)))
            filterAxes.axes1.Position(3) = filterAxes.axes1.Position(3) + rszPnlChgs(1,1);
            filterAxes.axes2.Position(3) = filterAxes.axes2.Position(3) + rszPnlChgs(1,1);
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
            
            % Adjusts units according format selected in Spectral Analysis Options Panel
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
            output_txt = { ...
                ['X: ',num2str(pos(1),10)], ...
                ['Y: ',num2str(pos(2),10)], ...
                ['Data Idx: ',num2str(di)], ...
                ['Std. Freq. (Hz): ',num2str(freqHz)], ...
                ['N. Freq. (Wn) (',char(960),char(183),'rad/spl): ', num2str(freqWn)]};
        elseif event_obj.Target.Parent == filterAxes.axes1
            output_txt = { ...
                ['X: ',num2str(pos(1),10)], ...
                ['Y: ',num2str(pos(2),10)], ...
                ['Data Idx: ',num2str(di)]};
        end

    end

%% GUIComp Wrapper & UI Control Related Functions
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% initGUIComp() - Initiate the entry for a GUI component to be stored
    % -----------------------------------------------------------------------------------------------------------------------
    function initGUIComp(GUICompName)
            filterGUI(1,1).(GUICompName) = gobjects(1,1);
    end

    %% lastInitGUIComp() - Returns the the last initiated GUI component regardless it being created
    % -----------------------------------------------------------------------------------------------------------------------
    function lastGUICompFound = lastInitGUIComp()
        listOfGUIComps = fieldnames(filterGUI);
        lastGUICompFound = listOfGUIComps{end,:};
    end

    %% createLastGUIComp() - Creates the specified UI Control and assigns it to initGUIComp()
    % -----------------------------------------------------------------------------------------------------------------------
    function createLastGUIComp(varargin)
        lastGUIComp = lastInitGUIComp();
        
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
                error(['Invalid UI Object type ',varargin{2},' specified. See help for more info.'])
        end
    end

    %% createGUIComp() -  Creates the specified UI Control and assigns it to initGUIComp()
    % Notes: 
    % The first property to be defined when invoking createGUIComp() should be 'AssignTo' whose attribute consists of a
    % string providing the name assigned to the UI Control it creates. This attribute should match that specified during
    % invocation of initGUIComp().
    %
    % Example:
    %       initGUIComp('manifDisp_txt_filtTypeVal');
    %
    %       createLastGUIComp( ...
    %           'AssignTo', 'manifDisp_txt_filtTypeVal', ...
    %           'Type', 'uicontrol', ...
    %           'Parent', filterGUI.manifDisp_pnl);
    % -----------------------------------------------------------------------------------------------------------------------
    function createGUIComp(varargin) %#ok<DEFNU>
        if ~strcmpi(varargin{1}, 'AssignTo')
            error(['Properties related to the fieldname contained in GUI Objects Structure created for assignment of ', ...
                'the GUI component to be generated, ''AssignTo'', is either missing from first entry, or malformed'])
        end
        
        if isempty(varargin{2}) || ~ischar(varargin{2}) || ~isfield('filterGUI', varargin{2})
            error(['''AssignTo'' property attribute that specifies the GUI Objects Structure fieldname for assigment ', ...
                'of the GUI component to be generate is either field ''',varargin{2},''' not created, is empty, and/or ', ...
                'is not a character array'])
        end
        
        assignTo = varargin{2};
        
        switch varargin{3}
            case 'uicontrol'
                filterGUI.(assignTo) = uicontrol(varargin{5:end});
            case 'uibuttongroup'
                filterGUI.(assignTo) = uibuttongroup(varargin{5:end});
            case 'uipanel'
                filterGUI.(assignTo) = uipanel(varargin{5:end});
            case 'uitable'
                filterGUI.(assignTo) = uitable(varargin{5:end});
            otherwise
                error(['Invalid UI Object type ',varargin{3},' specified. See help for more info.'])
        end
    end

    %% setGUIComp() - A set() wrapper for GUI Components' objects
    % Notes:
    % Supports a syntax nearly identical to traditional set(). Not reccomended for Java objects.
    % H is GUI Component(s)' object either directly (filterGUI.example) or the GUI Objects' Structure's fieldname
    % (i. e., 'example'). Multiple GUI compent objects or fieldnames may be passed using a row vector [1 n] cell.
    %
    % More info www.mathworks.com/help/matlab/ref/set.html
    %       set(H,Name,Value)
    %       set(H,NameArray,ValueArray)
    %       set(H,S)
    %       s = set(H)
    %       values = set(H,Name)
    % -----------------------------------------------------------------------------------------------------------------------
    function varargout = setGUIComp(varargin)
        H = validateGUICompObjs(varargin{1});
        switch nargin
            case 1
                varargout{1} = set(H);
            case 2
                if ~isstruct(varargin{2})
                    varargout{1} = set(H,varargin{2});
                else
                    set(H,varargin{2});
                end
            case 3
                set(H,varargin{2},varargin{3});
            otherwise
                error('Invalid number of input arguments. See help for more information')
        end
    end

    %% validateGUICompObjs() - GUI Components' object handler/validator for setGUIComp()
    % -----------------------------------------------------------------------------------------------------------------------
    function H = validateGUICompObjs(varargin)
        HTemp = varargin{:};
        HTempLength = length(HTemp);
        H = [];
        
        % Assure non-empty and 2d
        if isempty(HTemp) || ~isvector(HTemp)
            error('GUI Component object(s) are either undefined or the incorrect data type.');
        end
        
        % If column array input, convert to row array
        if ~isrow(HTemp); HTemp = HTemp.'; end
        
        % Validate GUI Component(s) for use as objects, H, in set()
        if all(isgraphics(HTemp)) % Specified GUI Object(s) directly, add redundancy for non-cell def
            H = HTemp;
        elseif ischar(HTemp) % Specified GUI Objects' Structure fieldname
            % Ensure field exists. If so, set as object for set(). Else, error.
            if ~isfield(filterGUI, HTemp)
                error(['GUI Objects Structure fieldname specified, ', HTemp, ' does not exist.'])
            end
            
            H = filterGUI.(HTemp);
        elseif iscell(HTemp) && HTempLength > 1 % Cell of poss. mix-matched GUI components' handles. > 1 to avoid scalars
            for r = 1:HTempLength
                if ischar(HTemp{r}) % Specified GUI Objects' Structure fieldname
                    % Ensure field exists. If so, add to list of object for set(). Else, error.
                    if ~isfield(filterGUI, HTemp{r})
                        error(['GUI Objects Structure fieldname specified, ', HTemp{r}, ' does not exist.'])
                    end
                    
                    H = [H, filterGUI.(HTemp{r})]; %#ok<AGROW>
                elseif all(isgraphics(HTemp{r})) % Specified GUI Object(s) directly. Allows some leeway in certain multilevel
                    % Ensure dimensions agree if multilevel array of some sort was passed
                    if length(HTemp{r}) > 1 && ~isrow(HTemp{r})
                        H = [H, HTemp{r}.']; %#ok<AGROW>
                    else
                        H = [H, HTemp{r}]; %#ok<AGROW>
                    end
                else % Error due to invalid content found within cell
                    error(['Invalid GUI Component specified for index ', r ,'. Data type provided was ', class(HTemp{r}), ...
                        ' and of length ', length(HTemp{r})])
                end
            end
        else % Error due to invalid GUI Component(s) provided
            error(['GUI Component(s) input invalid. Must be either graphics array, character array of GUI Objects ', ...
                'Structure fieldname(s), or row-cell consisting of GUI Objects Structure fieldname(s) and/or ', ...
                'specific GUI Object(s). Input was type ',class(HTemp),' of length ',HTempLength]);
        end
    end

    %% enableGUIComp() - Wrapper for setGUICompOpState() that enables specified GUI Component object(s)
    % -----------------------------------------------------------------------------------------------------------------------
    function enableGUIComp(obj)
        setGUICompOpState(obj, 'on');
    end

    %% disableGUIComp() - Wrapper for setGUICompOpState() that disables specified GUI Component object(s)
    % -----------------------------------------------------------------------------------------------------------------------
    function disableGUIComp(obj)
        setGUICompOpState(obj, 'off');
    end

    %% inactivateGUIComp() - Wrapper for setGUICompOpState() that inactivates specified GUI Component object(s)
    % Notes: If a valid property/attribute, sets objects' op state to 'inactive' which is non-operation, but appears enabled.
    % -----------------------------------------------------------------------------------------------------------------------
    function inactivateGUIComp(obj) %#ok<DEFNU>
        setGUICompOpState(obj, 'inactive');
    end

    %% setGUICompOpState(obj,state) - Sets the operational state of provided GUI Component object(s)
    % Notes: 
    % Supports input of a cell containing multiple GUI Component objects or (names of objects ) for modification of operation
    % state to either 'on', 'off', or 'inactive'. If supplied GUI Component object(s) support the modification of their
    % operational state, sets property attribute of object(s) to that provided by variable 'state', provided the supplied
    % state itself is supported by the GUI Component object.
    %
    % For more, see 'Enable' at www.mathworks.com/help/matlab/ref/matlab.ui.control.uicontrol-properties.html
    % -----------------------------------------------------------------------------------------------------------------------
    function setGUICompOpState(obj,state)
        % Validate GUI Component objects input
        H = validateGUICompObjs(obj);
        
        % Validate provided operation state input
        if ~any(strcmpi(state,{'on','off','inactive'}))
            % Check if state may be displayed. If so, format it for warning output. Otherwise, sanitize.
            if ischar(state); stateFormatted = sprintf('''%s'' provided', state); else; stateFormatted = 'provided'; end
            
            warning(['Invalid operational state ',stateFormatted,'. Choices are ''on'', ''off'', or ''inactive'])
        end        
        
        for r = 1:length(H)
            objProperties = set(H(r));
            
            if isfield(objProperties, 'Enable') && any(contains(objProperties.Enable,state))
                H(r).Enable = state;
                drawnow
            else
                warning(['GUI Component object at index ',r,' of class ''',class(H(1)),''' either does no allow ',...
                    'modification of its operational state, or does allow state ''',state,'''']);
                continue
            end
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

%% Functions to create GUI panels
% ---------------------------------------------------------------------------------------------------------------------------
%
    %% createSpectralAnalysisPnl() - Creates the Spectral Analysis Options {anel and related UI components
    % -----------------------------------------------------------------------------------------------------------------------
    function createSpectralAnalysisPnl()
        initGUIComp('SDE_pnl');
        createLastGUIComp(  ...
            'Type', 'uipanel', ...
            'Parent', filterAxes.fig, ...
            'Title', 'Spectral Analysis Options', ...
            'Units', 'normalized', ...
            'Position', [0.8100 0.8720 0.1820 0.1000]);

        % Decimation
        initGUIComp('SDE_dcmtn_txt');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.SDE_pnl, ...
            'Style', 'text', ...
            'String', 'Decimate', ...
            'Units', 'normalized', ...
            'Position', [0.015 0.745 0.22 0.15]);

        initGUIComp('SDE_dcmtn_fctrSet');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.SDE_pnl, ...
            'Style', 'edit', ...
            'Tag', 'decFactor', ...
            'Units', 'normalized', ...
            'Position', [0.26 0.65 0.35 0.25]);

        initGUIComp('SDE_dcmtn_btn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.SDE_pnl, ...
            'String','Decimate', ...
            'Enable', 'Off', ...
            'Units', 'normalized', ...
            'Position', [0.65 0.685 0.29 0.25], ...
            'Callback', @decimateData);

        % Frequency Units
        initGUIComp('SDE_frqBtns_grp_mstr');
        createLastGUIComp( ...
            'Type', 'uibuttongroup', ...
            'Parent', filterGUI.SDE_pnl, ...
            'BorderWidth', 0, ...
            'Units', 'normalized', ...
            'Position', [0.015 0.05 0.9 0.55], ...
            'SelectionChangedFcn', @frequencyUnitsHandler);

        initGUIComp('SDE_frqBtns_grp_op1Btn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.SDE_frqBtns_grp_mstr, ...
            'Tag', 'normalFreq', ...
            'Style', 'radiobutton', ...
            'String', 'Normalized Frequency', ...
            'Value', 1, ...
            'Enable', 'Off', ...
            'Units', 'normalized', ...
            'Position', [0 0.60 0.9 0.35]);

        initGUIComp('SDE_frqBtns_grp_op2Btn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.SDE_frqBtns_grp_mstr, ...
            'Tag', 'standardFreq', ...
            'Style', 'radiobutton', ...
            'String', 'Standard Frequency', ...
            'Enable', 'Off', ...
            'Units', 'normalized', ...
            'Position', [0 0.10 0.9 0.35]);

        % Analyze Button
        initGUIComp('SDE_anlzBtns');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.SDE_pnl, ...
            'String','Analyze', ...
            'Enable', 'Off', ...
            'Units', 'normalized', ...
            'Position', [0.65 0.10 0.29 0.25], ...
            'Callback', @spectralAnalysis);
    end

    %% createFilterDesignPnl() - Creates the Filter Design Panel and related UI components
    % -----------------------------------------------------------------------------------------------------------------------
    function createFilterDesignPnl()
        initGUIComp('filtDesg_pnl');
        createLastGUIComp( ...
            'Type', 'uipanel', ...
            'Parent', filterAxes.fig, ...
            'Title', 'Filter Design', ...
            'Units', 'normalized', ...
            'Position', [0.8100 0.6450 0.1820 0.2200]);
        
        % Filter Type
        initGUIComp('filtDesg_desgMeth_txt');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', 'Design Method', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0210 0.8735 0.3300 0.085]);
        
        initGUIComp('filtDesg_desgMeth_grp_mstr');
        createLastGUIComp( ...
            'Type', 'uibuttongroup', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Tag', 'designMethodGroup', ...
            'BorderWidth', 0, ...
            'Units', 'normalized', ...
            'Position', [0.3750 0.88 0.575 0.085], ...
            'SelectionChangedFcn', @changeFilterDesignMethod);
        
        initGUIComp('filtDesg_desgMeth_grp_filtBtn1');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_desgMeth_grp_mstr, ...
            'Tag', 'fir1', ...
            'Style', 'radiobutton', ...
            'String', 'fir1', ...
            'Units', 'normalized', ...
            'Position', [0 0 0.30 1]);
        
        initGUIComp('filtDesg_desgMeth_grp_filtBtn2');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_desgMeth_grp_mstr, ...
            'Tag', 'Custom', ...
            'Style', 'radiobutton', ...
            'String', 'Custom', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.35 0 0.45 1]);
        
        % fir1 Filter Parameters
        initGUIComp('filtDesg_fir1_filtTypeTxt');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', 'Type', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.021 0.7335 0.15 0.085]);
        
        initGUIComp('filtDesg_fir1_filtTypeSet');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Tag', 'fir1FilterType', ...
            'Style', 'popupmenu', ...
            'String', {'Lowpass', 'Highpass', 'Bandpass', 'Bandstop', 'DC-0', 'DC-1'}, ...
            'Value', fir1FilterTypeValue, ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.177 0.6685 0.4 0.085], ...
            'Callback', @fir1FilterTypeHandler);
        
        initGUIComp('filtDesg_fir1_filtOrdTxt');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', 'Order', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.021 0.5935 0.15 0.085]);
        
        initGUIComp('filtDesg_fir1_filtOrdSet');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Tag', 'fir1FilterOrder', ...
            'Style', 'edit', ...
            'String', num2str(fir1FiltOrd), ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.177 0.5800 0.5 0.105]);
        
        initGUIComp('filtDesg_fir1_filtOrdTxtUOM');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', '(int)', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'TooltipString', 'Integer Scalar', ...
            'Position', [0.6900 0.5935 0.102 0.08]);
        
        initGUIComp('filtDesg_fir1_filtWnTxt');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', 'Wn', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0210 0.4535 0.1000 0.0850]);
        
        initGUIComp('filtDesg_fir1_filtWnSet');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Tag', 'fir1FilterFreq', ...
            'Style', 'edit', ...
            'String', num2str(fir1FiltFreq), ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.177 0.4435 0.5 0.105]);
        
        initGUIComp('filtDesg_fir1_filtWnTxtUOM');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', ['(',char(960),char(183),'rad/spl)'], ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'TooltipString', sprintf('Normalized Frequency\n%s',['(',char(960),char(183),'radians)/sample']), ...
            'Position', [0.6900 0.4550 0.2560 0.0850]);
        
        initGUIComp('filtDesg_fir1_filtDataBtn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'String', 'Filter', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.021 0.3135 0.29 0.085], ...
            'Callback', @fir1FilterData);
        
        % Data Display Control
        initGUIComp('filtDesg_showOrig_txt');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', 'Show Orig. Data', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0210 0.1935 0.3700 0.0700]);
        
        initGUIComp('filtDesg_showOrig_grp_mstr');
        createLastGUIComp( ...
            'Type', 'uibuttongroup', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Tag', 'showOriginalDataButtonGroup', ...
            'BorderWidth', 0, ...
            'Units', 'normalized', ...
            'Position', [0.4120 0.1435 0.5500 0.1600], ...
            'SelectionChangedFcn', @dataDisplayHandler);
        
        initGUIComp('filtDesg_showOrig_grp_yBtn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_showOrig_grp_mstr, ...
            'Tag', 'origOn', ...
            'Style', 'radiobutton', ...
            'String', 'Yes', ...
            'Value', 1, ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0 0 0.32 1]);
        
        initGUIComp('filtDesg_showOrig_grp_nBtn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_showOrig_grp_mstr, ...
            'Tag', 'origOff', ...
            'Style', 'radiobutton', ...
            'String', 'No', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.404 0 0.26 1]);
        
        initGUIComp('filtDesg_showFilt_txt');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Style', 'text', ...
            'String', 'Show Filtered Data', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0210 0.0535 0.3300 0.0700]);
        
        initGUIComp('filtDesg_showFilt_grp_mstr');
        createLastGUIComp( ...
            'Type', 'uibuttongroup', ...
            'Parent', filterGUI.filtDesg_pnl, ...
            'Tag', 'showFilteredDataButtonGroup', ...
            'BorderWidth', 0, ...
            'Units', 'normalized', ...
            'Position', [0.4120 0.0035 0.5500 0.1600], ...
            'SelectionChangedFcn', @dataDisplayHandler);
        
        initGUIComp('filtDesg_showFilt_grp_yBtn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_showFilt_grp_mstr, ...
            'Tag', 'filtOn', ...
            'Style', 'radiobutton', ...
            'String', 'Yes', ...
            'Value', 1, ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0 0 0.32 1]);
        
        initGUIComp('filtDesg_showFilt_grp_nBtn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.filtDesg_showFilt_grp_mstr, ...
            'Tag', 'filtOff', ...
            'Style', 'radiobutton', ...
            'String', 'No', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.404 0 0.26 1]);
    end

    %% createFilterManifestDisplayPnl() - Creates the Filter Manifest Display Panel and related UI components
    % -----------------------------------------------------------------------------------------------------------------------
    function createFilterManifestDisplayPnl()
        initGUIComp('manifDisp_pnl');
        createLastGUIComp( ...
            'Type', 'uipanel', ...
            'Parent', filterAxes.fig, ...
            'Title', 'Filter Manifest Entry Viewer', ...
            'Units', 'normalized', ...
            'Position', [0.8100 0.5090 0.1820 0.129]);
        
        initGUIComp('manifDisp_txt_filtMeth');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Style', 'text', ...
            'String', 'Filter Method', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0150 0.7421 0.2900 0.1850]);
        
        initGUIComp('manifDisp_txt_filtType');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Style', 'text', ...
            'String', 'Filter Type', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0150 0.5221 0.2400 0.1850]);
        
        initGUIComp('manifDisp_txt_filtOrd');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Style', 'text', ...
            'String', 'Filter Order', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0150 0.2721 0.2600 0.1850]);
        
        initGUIComp('manifDisp_txt_wn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Style', 'text', ...
            'String', 'Filter Wn', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.0150 0.0322 0.2050 0.1850]);
        
        % Values
        initGUIComp('manifDisp_txt_filtMethVal');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Tag', 'value', ...
            'Style', 'text', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.3350 0.7421 0.4150 0.1850]);
        
        initGUIComp('manifDisp_txt_filtTypeVal');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Tag', 'value', ...
            'Style', 'text', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.3350 0.5221 0.4150 0.1850]);
        
        initGUIComp('manifDisp_txt_filtOrdVal');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Tag', 'value', ...
            'Style', 'text', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.3350 0.2721 0.4150 0.1850]);
        
        initGUIComp('manifDisp_txt_wnVal');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'Tag', 'value', ...
            'Style', 'text', ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', ...
            'Position', [0.3350 0.0322 0.4150 0.1850]);
        
        % Set default values
        initGUIComp('manifDisp_Btn_setDefs');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'String', 'Set Default', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.6250 0.2625 0.3500 0.2500], ...
            'Callback', @setDefFiltVals);
        
        initGUIComp('manifDisp_Btn_clrDefs');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.manifDisp_pnl, ...
            'String', 'Clear Default', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.6250 0.0125 0.3500 0.2500], ...
            'Callback', @clearDefaultFilterValues);
    end

    %% createGeneralOperationsPnl() - Creates the General Operations panel and related UI components
    % -----------------------------------------------------------------------------------------------------------------------
    function createGeneralOperationsPnl()
        initGUIComp('genOps_pnl');
        createLastGUIComp( ...
            'Type', 'uipanel', ...
            'Parent', filterAxes.fig, ...
            'BorderType', 'none', ...
            'Units', 'normalized', ...
            'Position', [0.8100 0.4700 0.1820 0.028]);
        
        initGUIComp('genOps_saveBtn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.genOps_pnl, ...
            'String', 'Save', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0 0.0150 0.4800 0.9545], ...
            'Callback', @saveFilteredData);
        
        initGUIComp('genOps_rstBtn');
        createLastGUIComp( ...
            'Type', 'uicontrol', ...
            'Parent', filterGUI.genOps_pnl, ...
            'String', 'Reset', ...
            'Units', 'normalized', ...
            'Position', [0.5200 0.0150 0.4800 0.9545], ...
            'Callback', @resetDataFiltering);
        
        initGUIComp('genOps_varTbl');
        createLastGUIComp( ...
            'Type', 'uitable', ...
            'Parent', filterAxes.fig, ...
            'Unit', 'normalized', ...
            'Position', [0.8100, 0.06500, 0.1820, 0.4000],...
            'ColumnName', {'Variable Name', 'Filtered?'}, ...
            'ColumnWidth', {100, 'auto'}, ...
            'CellSelectionCallback', @initPlot);
    end
end % end for Step2_DataFilterGUI() function