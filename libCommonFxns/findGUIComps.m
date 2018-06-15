function foundGUIComps = findGUIComps(GUIComps,pattern,varargin)
%findGUIComps Returns which GUI components stored in top-level structure-array contain the specified pattern name
%
% Syntax:
%	foundGUIComps = findjobj(GUIComps, pattern)
%	foundGUIComps = findjobj(GUIComps, pattern, outputDataType)
%	foundGUIComps = findjobj(GUIComps, pattern, searchCase)
%	foundGUIComps = findjobj(GUIComps, pattern, outputDataType, searchCase)
%
% Input parameters:
%   GUIComps        - Required. A linear structure-array in which the field names reflect the handle of the graphics object
%                     that it stores. Example:
%                     filterGUI.SDE_pnl = [1×1 Panel]
%                     filterGUI.filtDesg_pnl = [1×1 Panel]
%                     filterGUI.manifDisp_pnl = [1×1 Panel]
%                     filterGUI.genOps_pnl = [1×1 Panel]
%   pattern         - Required. String-type. The desired pattern to be used in locating the desired GUI components.
%   outputDataType  - Optional. String-type. Default 'string'. Specifies the data-type of output results. Option input is
%                     case-insensitive, and includes:
%                       - 'handle' -> Outputs a MATLAB UI Control array of results.
%                       - 'cellh'  -> Outputs a cell-array in which each cell is a located MATLAB UI Control array.
%                       - 'string' -> Outputs a string-type containing the names of the handles which contained the specified
%                                     pattern, NOT graphics control related handles.
%   searchCase      - Optional. Logical-type. Default TRUE. Dictates the case-sensitivity of determining if any of the GUI
%                     components contain the pattern. Options include:
%                       - TRUE -> Determination using the pattern is case-sensitive
%                       - FALSE -> Determination using the pattern is case-insensitive
% 
% Output Parameters
%   foundGUIComps   - If results are found, contains an array of component(s) that contained pattern, and of the type data 
%                     type specified through input parameters. If no results are found, returns a 0x0 array of the data type
%                     specified.
%                   - If an output is not specified, output remains unchanged.
%
% Usage Examples
%   findGUIComps(GUIComps, pattern);    % Array of graphical handles with the GUI comps. containing pattern case-sensitively
%
%   findGUIComps(GUIComps, '');         % Array of all graphical handles stored within GUIComps' structure-array
%
%   foundGUIComps = findGUIComps(GUIComps, pattern, 'string');          % A string of GUI component handles which contained
%                                                                         pattern case-sensitively
%
%   foundGUIComps = findGUIComps(GUIComps, pattern, TRUE);              % Array of graphical handles handles which contained
%                                                                         pattern case-sensitively
%
%   foundGUIComps = findGUIComps(GUIComps, pattern, 'handle', FALSE);   % Array of graphical handles containing the
%                                                                         GUI components containing pattern case-insensitive
%
% Known-Limitations/Future-Improvements
%   - Only performs search on the specific type of array-structure specified
%   - Does not support multiple patterns (i. e. pattern = {'balloon','xylophone','hairnet'}) in some unknown instances fully.
%   - Does not support the ability to exclude specific results.
%   - Need to improve pattern validation.
%   - Only searches and locates results solely based on fieldnames. In the future it will include properties, handles, etc.
%
%   Copyright 2017-2018 Christopher L. Kerner.
                                                                        

    if nargin < 2 || nargin > 4
        error('Invalid number of input arguments. See help for more info.');
    end
    
    % Validate GUI Components source
    if ~isstruct(GUIComps) || ~all(structfun(@ishandle,GUIComps))
        error(['Unable to execute due to expected GUI Components source file is not a structure, or does not', ...
            'contain valid graphics or Java object handles.']);
    end
    
    % Validate supplied search pattern.
    %if pattern ~empty, isstring,ischar,iscellstr()
    %    
    %end
    
    % Assign execution parameters
    % For output data type:
        % 1 -> graphics object array
        % 2 -> cell of graphic object handles
        % 3 -> string-array of names
    % for search case:
        % 1 -> true (search is case-sensitive)
        % 2 -> false (search is case-insensitive)
    outputType = 1;
    searchCase = true();
    
    % If user has supplied data for the optional arguments, validate them. Cases 1 & 2 superfulous as seen above.
    if nargin == 3
            %Check if user has specified output type or case-sensitivity for third argument, validate and set accordingly
            if islogical(varargin{1})
                searchCase = varargin{1};
            elseif ischar(varargin{1}) || isstring(varargin{1})
                outputType = determineOutputType(varargin{1});
            else
                error('Invalid third argument specified. See help for more info.')
            end
    elseif nargin == 4
            % Validate data output type input arguments
            if ischar(varargin{1}) || isstring(varargin{1})
                outputType = determineOutputType(varargin{1});
            else
                error('Invalid input provided for output data type. See help for more info.')
            end
            
            if islogical(varargin{2})
                searchCase = varargin{2};
            else
                error('Invalid input provided for search-case. See help for more info.')
            end
    end
    
    % Perform search as user specified. If sucessful, proceed to outputting data. Otherwise, return empty graphics obj array
    listFieldnames = fieldnames(GUIComps);
    idxMatchingFields = contains(listFieldnames, pattern, 'IgnoreCase', ~searchCase) == 1;
    valMatchingFields = listFieldnames(idxMatchingFields,:);
    numOfResults = size(valMatchingFields,1);
    
    % No results generated. Return empty graphics object array
    if numOfResults == 0
        foundGUIComps = gobjects(1,1);
        return
    end
    
    % Pre-allocate output data
    switch outputType
        case 1
            foundGUIComps = gobjects(numOfResults,1);
        case 2
            foundGUIComps = cell(numOfResults,1);
        case 3
            foundGUIComps = strings(numOfResults,1);
    end
    
    % List of non-UI related indices to remove
    idxToRemove = [];
    
    % Populate output data
    for r = 1:numOfResults
        % Check if field contains a non-UI type. If so, mark for deletion, and move on. Otherwise, carry on.
        if ~contains(class(GUIComps.(valMatchingFields{r,1})), 'matlab.ui')
            idxToRemove = [idxToRemove; r]; %#ok<AGROW>
            continue
        end
        
        switch outputType
            case 1
                foundGUIComps(r,1) = GUIComps.(valMatchingFields{r,1});
            case 2
                foundGUIComps{r,1} = GUIComps.(valMatchingFields{r,1});
            case 3
                foundGUIComps(r,1) = [inputname(1) '.' valMatchingFields{r}];
        end
    end
    
    % Remove invalid results if present
    if ~isempty(idxToRemove)
        foundGUIComps(idxToRemove) = [];
    end
end
    
% Performs the substition for phrases to keys
function outputTypeTemp = determineOutputType(inputStr)
    outputTypeTemp = [contains(inputStr, 'handle', 'IgnoreCase', true), ...
                      contains(inputStr, 'cellh', 'IgnoreCase', true), ...
                      contains(inputStr, 'string', 'IgnoreCase', true)];

    if any(outputTypeTemp)
        % Cheap trick that takes advantage of logical-types
        outputTypeTemp = outputTypeTemp .* [1, 2, 3];
        outputTypeTemp(outputTypeTemp == 0) = [];
    else
        error('Invalid output data type requested. See help for more info.')
    end
end
