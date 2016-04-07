clear
close all
clc

textFileLocation = 'C:\Users\clk0032\Dropbox\Friction Connection Research\Full Scale Test Data\FS Testing -ST2 - 04-07-16\'; %Location of File
textFileName     = 'fs testing -st2 - 04-07-16Run'; %Name of file to be processed
textFileSeed     = 200;
t_saveFileAs     = 'FS Testing - ST2 - Test 2 - 04-07-16'; %What to name file upon save
t_saveFileAs2    = sprintf('[Filter]%s',t_saveFileAs);
amount           = 31;

names = {'NormTime','run','sg1','sg2','sg3','sg4','sg5','sg6','sg7','sg8','sg9','sg10','sg11','sg12','sg13','sg14','sg15','sg16','sg17','sg18','sg19','sg20','sg21','sg22','wp11','wp12','wp21','wp22','wp31','wp32','wp41','wp42','wp51','sgBolt','wp61','wp62','LC1','LC2','LC3','LC4','MTSLC','MTSLVDT','A','B','C','D','E','F','G','H'};
formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

for y = 1:1:length(names)
    eval(sprintf('%s = [];',names{y}));
end

for z = 1:1:amount;
    %% Initialize variables.

    filename = sprintf('%s%s%d.txt',textFileLocation,textFileName,((textFileSeed+z)-1))
    delimiter = '\t';
    startRow = 14;

    %% Open the text file.
    fileID = fopen(filename,'r');

    %% Read columns of data according to format string.
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);

    %% Close the text file.
    fclose(fileID);

    %% Convert the contents of columns containing numeric strings to numbers.
    % Replace non-numeric strings with NaN.
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col = 1:1:length(names)
        % Converts strings in the input cell array to numbers. Replaced non-numeric
        % strings with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1);
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData{row}, regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if any(numbers==',');
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(thousandsRegExp, ',', 'once'));
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric strings to numbers.
                if ~invalidThousandsSeparator;
                    numbers = textscan(strrep(numbers, ',', ''), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch me
            end
        end
    end


    %% Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells

    %% Allocate imported array to column variable names
    for i = 1:1:length(rawData)
        for j = 1:1:length(names)
            eval(sprintf('%s(length(%s)+1,:) = cell2mat(raw(i, j));',names{j},names{j}));
        %{
        NormTime(length(NormTime)+1,:) = cell2mat(raw(i, 1));
        run(length(run)+1,:) = cell2mat(raw(i, 2));
        sg1(length(sg1)+1,:) = cell2mat(raw(i, 3));
        sg2(length(sg2)+1,:) = cell2mat(raw(i, 4));
        sg3(length(sg3)+1,:) = cell2mat(raw(i, 5));
        sg4(length(sg4)+1,:) = cell2mat(raw(i, 6));
        sg5(length(sg5)+1,:) = cell2mat(raw(i, 7));
        sg6(length(sg6)+1,:) = cell2mat(raw(i, 8));
        sg7(length(sg7)+1,:) = cell2mat(raw(i, 9));
        sg8(length(sg8)+1,:) = cell2mat(raw(i, 10));
        sg9(length(sg9)+1,:) = cell2mat(raw(i, 11));
        sg10(length(sg10)+1,:) = cell2mat(raw(i, 12));
        sg11(length(sg11)+1,:) = cell2mat(raw(i, 13));
        sg12(length(sg12)+1,:) = cell2mat(raw(i, 14));
        sg13(length(sg13)+1,:) = cell2mat(raw(i, 15));
        sg14(length(sg14)+1,:) = cell2mat(raw(i, 16));
        sg15(length(sg15)+1,:) = cell2mat(raw(i, 17));
        sg16(length(sg16)+1,:) = cell2mat(raw(i, 18));
        sg17(length(sg17)+1,:) = cell2mat(raw(i, 19));
        sg18(length(sg18)+1,:) = cell2mat(raw(i, 20));
        sg19(length(sg19)+1,:) = cell2mat(raw(i, 21));
        sg20(length(sg20)+1,:) = cell2mat(raw(i, 22));
        sg21(length(sg21)+1,:) = cell2mat(raw(i, 23));
        sg22(length(sg21)+1,:) = cell2mat(raw(i, 24));
        wp11(length(wp11)+1,:) = cell2mat(raw(i, 25));
        wp12(length(wp12)+1,:) = cell2mat(raw(i, 26));
        wp21(length(wp21)+1,:) = cell2mat(raw(i, 27));
        wp22(length(wp22)+1,:) = cell2mat(raw(i, 28));
        wp31(length(wp31)+1,:) = cell2mat(raw(i, 29));
        wp32(length(wp32)+1,:) = cell2mat(raw(i, 30));
        wp41(length(wp41)+1,:) = cell2mat(raw(i, 31));
        wp42(length(wp42)+1,:) = cell2mat(raw(i, 32));
        wp51(length(wp51)+1,:) = cell2mat(raw(i, 33));
        wp61(length(wp61)+1,:) = cell2mat(raw(i, 34));
        wp62(length(wp62)+1,:) = cell2mat(raw(i, 35));
        LC1(length(LC1)+1,:)   = cell2mat(raw(i, 36));
        LC2(length(LC2)+1,:)   = cell2mat(raw(i, 37));
        LC3(length(LC3)+1,:)   = cell2mat(raw(i, 38));
        LC4(length(LC4)+1,:)   = cell2mat(raw(i, 39));
        MTSLC(length(MTSLC)+1,:) = cell2mat(raw(i, 40));
        MTSLVDT(length(MTSLVDT)+1,:) = cell2mat(raw(i, 41));
            %}
        end
    end
    complete = (z/amount)*100
end

%Correct Time
timeModifier = NormTime(2,1) - NormTime(1,1);
for x = 2:1:length(NormTime)
    NormTime(x,1) = NormTime((x-1),1)+timeModifier;
end
%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me R amount i names textFileLocation textFileLocation textFileSeed x y z j complete;

save(t_saveFileAs, '-regexp', '^(?!t_.*$).')
save(t_saveFileAs2, '-regexp', '^(?!t_.*$).')