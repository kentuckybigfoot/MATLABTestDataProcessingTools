%function [  ] = initializeSuite( invokingScriptsInfo )
%initializeSuite Performs initilization tasks neccessary to execute suite components
%   Rather straight-forward.
    
    % Diagnostics: comment out the function defintion and it's end before defining the following.
    invokingScriptsInfo = 'C:\Users\Christopher\Dropbox\Friction Connection Research\Full Scale Test Data\Data Processing Scripts\MATLABTestDataProcessingTools\Step3_DataProcessing2';
	
    % Get invoking suite component's filename and directory
	invokingScriptsInfoSplit = strsplit(invokingScriptsInfo, '\\');
	invokingScriptsInfoSplitLength = length(invokingScriptsInfoSplit);
    invokingScriptsDir = strjoin(invokingScriptsInfoSplit(1:invokingScriptsInfoSplitLength-1), '\\');
	invokingScriptsName = invokingScriptsInfoSplit{invokingScriptsInfoSplitLength};
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Check MATLAB version and installed products
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Determine the version number of the active/invoking MATLAB instance.
	currentVersion = version('-release');                   %Outputs '2017a', for example
    currentVersionNum = str2double(currentVersion(1:4));    %Obtains '2017' portion of example
    currentVersionLet = currentVersion(5);                  %Obtains 'a' portion of example
    
    % Check that MATLAB version is at least R2016b
    if currentVersionNum < 2016
        error('MATLAB Release R2016b or greater required to execute suite. Currently running Release R%s', currentVersion);
    elseif currentVersionNum == 2016 && ~strcmp(currentVersionLet, 'b')
        error('MATLAB Release R2016b or greater required to execute suite. Currently running Release R%s', currentVersion);
    end
    
    %% Check toolbox requirements 
    % - Introduction
    % Check if specific toolboxes are installed and warn user if they are not. If desired toolbox(es) is/are not installed, 
    % define flag(s) that will either warn or halt execution of suite components depending on severeity of toolbox absence.  
    %
    % Note: Solely reviewed by this operation is pressence of toolboxes currently installed, and does not verify version or 
    % if the current user maintains the active license for their execution.
    
    % - Define structure containing toolboxes that are implemented into the processing suite.
    %                Name -> Name of toolbox
    %          Dependants -> Which processing suite component is dependant on that toolbox
    %   LevelOfDependance -> Level of neccessity that each toolbox be installed in order for suite component(s)' execution
    toolboxManifest = struct( ...
        'Name',             {'Signal Processing Toolbox', 'GUI Layout Toolbox', 'Parallel Computing Toolbox', ...
                             'Statistics and Machine Learning Toolbox'}, ...
        'Dependants',        {[0, 0, 1, 0], [0, 0, 1, 0], [0, 0, 0, 1], [0, 0, 0, 1]}, ...
        'LevelOfDependance', {[0, 0, 2, 0], [0, 0, 2, 0], [0, 0, 0, 1], [0, 0, 1, 2]} ...
        );
    
    % - Predefine necessary variables
    % Predefine the logical-array for flags used in generating warnings/errors when the reccomended/required toolboxes for
    % the invoking suite component's are not installed. By default, array of logical-false. Each column correspondes to the
    % individual major components of the suite.
    numReqd = size(toolboxManifest,2);
    haltMissingToolboxes = false(1,numReqd);
    warnMissingToolboxes = false(1,numReqd);
    
    % Predefine cell containing numeric-arrays that contain the indices of missing toolbox(es)' names.
    namesOfWarnToolboxes = {{},{},{},{}};
    namesOfHaltToolboxes = {{},{},{},{}};
    
    % Get MathWorks products installed
    productsVersionInformation = ver;
    productsInstalled = string({productsVersionInformation(:).Name});
    productsInstalled([23, 22, 19, 7]) = []; %Uncomment and specify rows of toolboxes to simulate missing
    
    % Compare processing suite toolbox dependences again string-array of installed products
    for r = 1:size(toolboxManifest,2)
        for s = 1:size(toolboxManifest(r).Dependants,2)
            % Assess the level of dependance on the toolbox's installation for execution of dependant suite component
            if toolboxManifest(r).Dependants(s) == 0
                %Particular component is not dependant. Move on.
                continue
            elseif ~contains('Statistics and Machine Learning Toolbox', productsInstalled)
                % Suite component is dependant, get level of dependance
                switch toolboxManifest(r).LevelOfDependance(s)
                    case 0
                        % No dependance by this component. This case is a placeholder.
                    case 1
                        % Warn of toolbox's absense, then flag to warn of absence upon dependant(s)' initialization
                        warnMissingToolboxes(s) = true;
                        namesOfWarnToolboxes{1,s} = cat(2, namesOfWarnToolboxes{1,s},r);
                    case 2
                        % Warn of toolbox's absense and flag to halt execution upon dependant(s)' initialization
                        haltMissingToolboxes(s) = true;
                        namesOfHaltToolboxes{1,s} = cat(2, namesOfHaltToolboxes{1,s},r);
                end
            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Common Initialization Tasks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %   Check that dir 'libCommonFxns' exists. If so, add path
    if exist(fullfile(invokingScriptsDir, 'libCommonFxns'), 'dir') == 0
        error('Unable to locate required directory ''libCommonFxns'' in the directory containing %s.m.\nCheck %s', ...
            invokingScriptsName, invokingScriptsDir);
    else
        % Includes the directory path containing commonly utilized functions created specifically for this suite.
        addpath(fullfile(invokingScriptsDir, 'libCommonFxns'))
    end
    
    %   Check that dir 'libExternalFxns' exists. If so, add path
    if exist(fullfile(invokingScriptsDir, 'libExternalFxns'), 'dir') == 0
        error('Unable to locate required directory ''libExternalFxns'' in the directory containing %s.m.\nCheck %s', ...
            invokingScriptsName, invokingScriptsDir);
    else
        % Includes the directory path containing functions used by this suite that were created by external entities.
        addpath(genpath('libExternalFxns'))
    end
    
    % Note that libImport's existence is only checked when Step1_ImportRAWFiles.m is executed
    
    % Set Command Winow output display format to long, fixed-decimal format that, after the decimal point, returns 15 and 7
    % digits for double-type and single-type values, respectively.
    format long;
    
    %{
    % General modifications to MATLAB preferences to optimize editting. Additional file-specific modifications made whereas
    % required in later portions of this script. A helpful resource regarding programatically modifying preferences within
    % matlab.prf may be found at http://undocumentedmatlab.com/blog/changing-system-preferences-programmatically.
    
    % Define variables used for housekeeping
    haltPrefMods = false;                                        % Flag used to half mods if files are inaccessible 
    prefFilename = fullfile(prefdir,'matlab.prf');               % Path to default MATLAB preference file
    prefBackupFilename = fullfile(prefdir,'matlab_BACKUP.prf');  % Path to backup MATLAB preference file
    
    % Check that a backup of matlab.prf didn't get left behind due to hard close. If so, attempt to restore. Noteworthy is
    % that a backup could have also been left due to issues with file access
    
    %{
    if isFileReadable(prefBackupFilename)
        % A backup file remains. Check to see if enviroment supports swapping these out.
        if isFileReadable(prefFilename) && isDirWritable(refdir)
            [status,message,messageId] = copyfile(prefFilename, fullfile(prefdir,'matlab_BACKUP.prf'));
            if ~any([status, isempty(message), isempty(messageId)])
            %Could not copy file. Skip this task
            haltPrefMods = true;
        end
    %}
        
    
    %Check write access to directory invoking this function, in addition to read access to matlab.prf, before continuing
    if isDirWritable(prefdir) && isFileReadable(prefFilename)
        [status,message,messageId] = copyfile(prefFilename, fullfile(prefdir,'matlab_BACKUP.prf'));
        if ~any([status, isempty(message), isempty(messageId)])
            %Could not copy file. Skip this task
            haltPrefMods = true;
        end
    else
        %Can not access files(s) and/or directory(ies) needed to safely modify preferences. Skipping.
        haltPrefMods = true;
    end
    
    %Modify MATLAB preferences
    if ~haltPrefMods
        % Display right-hand text limit
        com.mathworks.services.Prefs.setBooleanPref('EditorRightTextLineVisible', true);
        
        % Extend right-hand text limit to 125 columns if not already larger and update comment formatting accordingly.
        if com.mathworks.services.Prefs.getIntegerPref('EditorRightTextLineLimit') < 125
            com.mathworks.services.Prefs.setIntegerPref('EditorRightTextLineLimit', 125);
            com.mathworks.services.Prefs.setIntegerPref('EditorMaxCommentWidth', 125);
        end
        
        % Auto-wrap comments at 125 columns.
        com.mathworks.services.Prefs.setBooleanPref('EditorAutoWrapComments', true);
        com.mathworks.services.Prefs.setIntegerPref('EditorMaxCommentWidth', 125);
        
        % Enable code folding for if/else and function blocks, for-loops, and section blocks. Some of these may be set to enabled by
        % default but occasionally an improper shut down of MATLAB will ruin them...
        com.mathworks.services.Prefs.setBooleanPref('Editorcode-folding-enable', true);
        com.mathworks.services.Prefs.setBooleanPref('EditorMCodeFoldEnabledif', true);
        com.mathworks.services.Prefs.setBooleanPref('EditorMCodeFoldEnabledfunction', true);
        com.mathworks.services.Prefs.setBooleanPref('EditorMCodeFoldEnabledfor', true);
        com.mathworks.services.Prefs.setBooleanPref('EditorMCodeFoldEnabledcell', true);
        
        % Ask for confirmation prior to exitting MATLAB.
        com.mathworks.services.Prefs.setBooleanPref('MatlabExitConfirm', true);
    end
    %}
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Suite-Component Specific Initialization Tasks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Determine the suite component being executed. Although componentExec looks ugly and redundant, the method used is still
    % more efficient than using regexp, cellfun, or the like. Additionally, the inclusion of the 'IgnoreCase' option results
    % in a 5% decrease in speed but, considering the already near-instantaneous execution given the limited number of tasks,
    % its inclusion becomes worthwhile in preventing a potential headache later.
    compExec = [contains(invokingScriptsName, 'ImportASCIIFiles', 'IgnoreCase', true), ...
                contains(invokingScriptsName, 'ImportRAWFiles', 'IgnoreCase', true), ...
                contains(invokingScriptsName, 'DataFilterGUI', 'IgnoreCase', true), ...
                contains(invokingScriptsName, 'DataProcessing', 'IgnoreCase', true)];
    
    % Cheap trick that takes advantage of logical-type compExec to determine which component is being executed
    compExec = compExec .* [1, 2, 3, 4];
    compExec(compExec == 0) = [];
    
    % Check if toolbox requirements are met. if not -- warn and/or error (halt execution) whereas appropriate prior to init.
    dispMissingToolboxes(invokingScriptsName, toolboxManifest, warnMissingToolboxes(compExec), ...
        haltMissingToolboxes(compExec), namesOfWarnToolboxes{1, compExec}, namesOfHaltToolboxes{1, compExec});

    % If required, perform the unique initialization task(s) for the suite component being executed.
    switch compExec
        case 1 % ImportASCIIFiles
            % None
        case 2 %  ImportRAWFiles
            % Includes the directory path containing PI6600 RAW-file import support scripts.
            if exist(fullfile(invokingScriptsDir, 'libImport'), 'dir') == 0
                error('Unable to locate required directory ''libImport'' in the directory containing %s.m.\nCheck %s', ...
                    invokingScriptsName, invokingScriptsDir);
            else
                % Includes the directory path containing functions for importing RAW-files.
                addpath(fullfile(invokingScriptsDir, 'libImport'))
            end
        case 3 % DataFilterGUI
            % None
        case 4 % DataProcessing
            % Enable initial code folding of if/else blocks to help simplify editting post-processing components
            com.mathworks.services.Prefs.setBooleanPref('EditorMCodeFoldCollapseFileOpenif', true);
            
            % Set default data cursor
            % set(0,'defaultFigureCreateFcn',@(s,e)datacursorextra(s))
        otherwise
            error('Unable to determine which suite component is being executed.')
    end
%end