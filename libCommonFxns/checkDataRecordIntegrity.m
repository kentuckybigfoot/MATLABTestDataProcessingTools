function [ dataIntact ] = checkDataRecordIntegrity( m )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    defaultVars = {'LC1','LC2','LC3','LC4','MTSLC','MTSLVDT','NormTime','filterManifest','sg1','sg10','sg11', ...
        'sg12','sg13','sg14','sg15','sg16','sg17','sg18','sg19','sg2','sg20','sg21','sg22','sg3','sg4','sg5','sg6','sg7', ...
        'sg8','sg9','sgBolt','wp11','wp12','wp21','wp22','wp31','wp32','wp41','wp42','wp51','wp52','wp61','wp62','wp71','wp72'};

    dataIntact = true;
    NormTimeMissing = false;
    defaultVarsSize = size(defaultVars,2);
    doesExists = false(1,defaultVarsSize);
    doesExistSize = zeros(1,defaultVarsSize);

    whosM = whos(m);
    whosMNames = {whosM(:).name};
    whosMSizes = reshape([whosM(:).size],2,[]);
    whosMSizes(2,:) = [];

    for r = 1:defaultVarsSize
        checkIfExists = strcmp(defaultVars{r}, whosMNames);
        if any(checkIfExists)
            doesExists(1,r) = true;
            doesExistSize(1,r) = whosMSizes(checkIfExists == 1);
        else
           doesExists(1,r) = false;
        end
    end

    if ~all(doesExists)
        idxOfMissing = find(doesExists == 0);
        warning(['Variables expected to be within the data record by default. Please verify the integrity of the data', ...
            ' record.\nVariables missing: %s'],strjoin({defaultVars{idxOfMissing}},', '))

        if ismember(7,idxOfMissing)
            warning(['NormTime variable absent from data record. It is highly likely that the record is corrupt. Use caution ',
                'when proceeding']);
            NormTimeMissing = true;
        end

        if ismember(8,idxOfMissing)
            warning(['The signals within the data record have not been filtered. It is HIGHLY advised that signals be filtered',
                ' otherwise post-processing output may obscured by noise.']);
        end

        dataIntact = false;
    end

    % Check if all record sizes match
    % First exclude filterManifest and missing values
    doesExistSize(8) = [];
    doesExistSize(doesExistSize == 0) = [];

    if any(diff(doesExistSize))
        warning(['Not all of the default data records are of equal size. It is HIGHLY likely that the data records may be ', ...
            'corrupt. Please use caution proceeding']);

        dataIntact = false;
    end

    % Validate NormTime record
    if ~NormTimeMissing
        % Validate NormTime record
        NormTime = m.NormTime;
        if round(range(NormTime(2:end,1)-NormTime(1:end-1,1)), 10) %Check if NormTime is equally spaced.
            warning('NormTime variable does not increment evenly. Ensure data record is valid.');
        elseif ~strcmp(num2str(round(NormTime(1,1),10)),'0') %Check if NormTime begins at zero
            warning('NormTime variable begins at %d instead of zero. Ensure data record is valid.');
        elseif any(NormTime(2:end,1) < 0) %Check if NormTime contains only positive values.
            warning('NormTime variable contains non-positive values. Ensure data record is valid.');
        end
    end
end

