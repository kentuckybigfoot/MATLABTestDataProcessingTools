function [ ProcessShearTab ] = getShearTab( ProcessFileName )
%getShearTab Attempts through filename validation to obtain the shear tab experimentally evaluated 
%   Proper formmating calls for signals filenames to be formatted:
%       FS Testing - ST3 - Test 1 - 08-24-16.mat
%   Locates the 'STX' portion to return X. Attempts to allow some wiggle room by also using some light regexp.
%
%   Copyright 2017-2018 Christopher L. Kerner.
%

    % First attempt to obtain value through string manipulation
    filenSTstrSplit = strtrim(strsplit(ProcessFileName,'-'));
    STStrfind = contains(filenSTstrSplit, {'ST1','ST2','ST3','ST4'}, 'IgnoreCase', true);
    idxSTStr = find(STStrfind == 1);
    
    % Now also try through regexp
    STRegexpResults = regexp(ProcessFileName, '[a-zA-Z]{2}\d{1}', 'match');
    
    % Create a logical array and find location of any logical true
    ResLogic = [size(STRegexpResults)==1, any(idxSTStr)];
    
    if all(ResLogic)
        % Both methods found result(s). Format the value, and return it Regardless of if they are identical, err on the side
        % of caution with regexp in the event that they did not.
        ProcessShearTab = str2double(strrep(STRegexpResults, 'ST', ''));
        return     
    elseif any(idxResLogic)
        % Only one returned results, attempt to clean and return it.
        if ResLogic(1)
            ProcessShearTab = str2double(strrep(STRegexpResults, 'ST', ''));
            return
        else
            STStrRes = char(filenSTstrSplit(idxSTStr));
            ProcessShearTab = str2double(strrep(STStrRes, 'ST', ''));
            return
        end
    else
        error('Could not determine a valid shear tab value using filename.')
    end
end

