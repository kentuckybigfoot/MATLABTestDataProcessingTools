function [ ] = generateMATFile( t_directory, t_saveFileAs, t_estLength, t_names )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    t_fileWrittenTo = fullfile(t_directory,t_saveFileAs);

    NormTime(t_estLength,1) = 0;
    Run(t_estLength,1) = 0;
    
    save(t_fileWrittenTo, '-v7.3', '-regexp', '^(?!t_.*$).');

    clear NormTime Run
    
    t_m = matfile(t_fileWrittenTo, 'Writable', true);
    
    for t_r = 1:length(t_names)
        t_m.(char(t_names(t_r)))(t_estLength,1) = 0;
        clear(char(t_names(t_r,:)));
    end
end

