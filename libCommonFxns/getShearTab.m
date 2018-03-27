function [ ProcessShearTab ] = getShearTab( ProcessFileName )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    ProcessFileNameTmp = strtrim(strsplit(ProcessFileName,'-'));

    ProcessFileNameTmp2 = contains(ProcessFileNameTmp,'ST');

    ProcessFileNameTmpIdx = find(ProcessFileNameTmp2 == 1);

    switch char(ProcessFileNameTmp(ProcessFileNameTmpIdx))
        case 'ST1'
            ProcessShearTab = 1;
        case 'ST2'
            ProcessShearTab = 2;
        case 'ST3'
            ProcessShearTab = 3;
        case 'ST4'
            ProcessShearTab = 4;
        otherwise
            error('Could not determine which shear tab data record pertains to');
    end
end

