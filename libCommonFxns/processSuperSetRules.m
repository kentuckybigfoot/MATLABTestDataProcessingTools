function [ Process ] = processSuperSetRules(Process, ProcessSuperSet)
%processSuperSetRules Processes ProcessSuperSet variable rules and applies them
%   Detailed explanation goes here
    
    % Define list of post-processing components
    ProcessList = struct('ConsolidateSGs', false, 'ConsolidateWPs', false, 'ConsolidateLCs', false, 'ConsolidateLPs', false, ...
        'WPAngles', false, 'WPProperties', false, 'WPCoords', false, 'ConfigLPs', false, 'BeamRotation', false, ...
        'StrainProfiles', false, 'CenterOfRotation', false, 'Forces', false, 'Moments', false, 'EQM', false, ...
        'Hysteresis', false);
    
    if isempty(ProcessSuperSet) || any(strcmpi(ProcessSuperSet,{'disable','disabled'}))
            Process = processForcedComps(Process, ProcessList);
        return
    end
             
    % Define cases for ProcessSuperSet
    pattern = {'allStbl', 'expOnly', 'diag', 'consolidation', 'moment', 'rotation', 'energyDissipated', 'momRot', ... 
        'momRotHyst', 'forces'};

    % Define consolidation task and then what must be run for each process.
    consolidationReqs = {'ConsolidateSGs', 'ConsolidateWPs', 'ConsolidateLCs'};
    ProcessSuperSetReqs = { ...
        {'WPAngles','WPProperties','WPCoords','BeamRotation','CenterOfRotation','Forces','Moments','EQM','Hysteresis'}, ...
        {'ConsolidateLPs','ConfigLPs','StrainProfiles'}, ...
        {'WPAngles','WPProperties','WPCoords','BeamRotation','CenterOfRotation','Forces','Moments','EQM','Hysteresis', ...
              'ConsolidateLPs','ConfigLPs','StrainProfiles'}, ...
        {'ConsolidateSGs', 'ConsolidateWPs', 'ConsolidateLCs'}, ...
        {'Moments'}, ...
        {'WPAngles','WPProperties','WPCoords','BeamRotation','CenterOfRotation'}, ...
        {'WPAngles','WPProperties','WPCoords','BeamRotation','CenterOfRotation','Moments','Hysteresis'}, ...
        {'WPAngles','WPProperties','WPCoords','BeamRotation','CenterOfRotation','Moments',}, ...
        {'WPAngles','WPProperties','WPCoords','BeamRotation','CenterOfRotation','Moments','Hysteresis'}, ...
        {'forces'} ...
        };

    %Pre-define
    paterrnSize = size(pattern,2);
    noConsolidation = false;

    % Check if consolidation should be skipped
    if contains(ProcessSuperSet,'-')
        % A hyphen for it is present. Look for "noConsolidation" in splits, find the side that does not contain it.
        splitSuperSet = strsplit(ProcessSuperSet, '-');
        noConSuperSet = strcmpi(splitSuperSet(1,1:2),'noConsolidation');
        idxNoConSuperSet = find(noConSuperSet == 0);

        % If found, replace the ProcessSuperSet for a version without, and flag that consolidation shouldn't occur
        if ~isempty(idxNoConSuperSet)
            ProcessSuperSet = splitSuperSet{idxNoConSuperSet};
            noConsolidation = true;
        end
    end

    % Proceed with processing ProccessSuperSet string identifying cases 
    logicSuperSet = false(1,paterrnSize);
    for r = 1:paterrnSize
        logicSuperSet(r) = contains(ProcessSuperSet, pattern{r}, 'IgnoreCase', true);
    end

    if any(logicSuperSet)
        % Cheap trick that takes advantage of logical-types
        logicSuperSet = logicSuperSet .* (1:paterrnSize);
        logicSuperSet(logicSuperSet == 0) = [];
    else
        warning(['Unable to interpret ''&s'' in ProccessSuperSet. If there are no overrides in place, no post-processing', ...
            ' will take place'],ProcessSuperSet)
    end

    % Proccess variables to be added into queue for enabling
    if noConsolidation 
        caseSuperSet = ProcessSuperSetReqs{1,logicSuperSet};
    else
        caseSuperSet = [consolidationReqs, ProcessSuperSetReqs{1,logicSuperSet}];
    end
    
    % Configure ProcessSuperSet
    for r = 1:size(caseSuperSet,2)
        ProcessList.(caseSuperSet{1,r}) = true;
    end

    % Process ProcessSuperSet overrides

    % Process overrides (Process.Force)
    ProcessList = processForcedComps(Process, ProcessList)
    
    % Assign Proccess for return
    Process = ProcessList;
end

function Process = processForcedComps(Process, ProcessList)
    % Process overrides (Process.Force)
    if isfield(Process,'Force') && isstruct(Process.Force)
        forceFieldnames = fieldnames(Process.Force);
        for r = 1:size(forceFieldnames,1)
            if isfield(ProcessList, forceFieldnames{r}) && islogical(Process.Force.(forceFieldnames{r}))
                ProcessList.(forceFieldnames{r}) = Process.Force.(forceFieldnames{r});
            else
                warning('Process.Force.%s invalid. See documentation for info.',forceFieldnames{r})
            end
        end
    end
    
    Process = ProcessList;
end
