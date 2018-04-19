clear all
close all
clc

%Initialize suite
initializeSuite(mfilename('fullpath'))

%Script configuration parameters
t_textFileLocation = 'C:\Users\Christopher\Desktop\Random Import\'; %Location of File
t_textFileName     = 'fs testing -st4 - 07-20-16Run'; %Name of file to be processed
t_textFileSeed     = 2000;
t_saveFileAs       = fullfile(t_textFileLocation, 'TestRun2.mat'); %What to name file upon save
t_saveFileAs2      = fullfile(t_textFileLocation, '[Filter]TestRun2.mat');
t_amount           = 5;

t_names = {'NormTime','run','sg1','sg2','sg3','sg4','sg5','sg6','sg7','sg8','sg9','sg10','sg11','sg12','sg13','sg14','sg15','sg16','sg17','sg18','sg19','sg20','sg21','sg22','wp11','wp12','wp21','wp22','wp31','wp32','wp41','wp42','wp51','sgBolt','wp61','wp62','wp71','wp72','LC1','LC2','LC3','LC4','MTSLC','MTSLVDT','A','B','C','D','E','F','G','H','LP1','LP3','LP2','LP4','wp52'};
t_formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%Create empty doubles for empty file
for t_y = 1:1:length(t_names)
	eval(sprintf('%s = [];',t_names{t_y}));
end

%Same empty file to write to
save(t_saveFileAs, '-v7.3', '-regexp', '^(?!t_.*$).');

%Open
m = matfile(t_saveFileAs, 'Writable', true);

%Variable to save row count of each file
lengthOfFile = [];

for t_r = 1:1:t_amount;
    tic
    %% Initialize variables.
    for t_y = 1:1:length(t_names)
        eval(sprintf('%s = [];',t_names{t_y}));
    end
    
    filename = sprintf('%s%s%d.txt',t_textFileLocation,t_textFileName,((t_textFileSeed+t_r)-1));
    delimiter = '\t';
    startRow = 14;

    %% Open the text file.
    fileID = fopen(filename,'r');

    %% Read columns of data according to format string.
    dataArray = textscan(fileID, t_formatSpec, 'Delimiter', delimiter, 'HeaderLines' ,startRow-1, 'ReturnOnError', false);

    %% Close the text file.
    fclose(fileID);

    %% Convert the contents of columns containing numeric strings to numbers.
    % Replace non-numeric strings with NaN.
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = dataArray{col};
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));
    
    %Get length of files being imported and store them.
    lengthOfFile(t_r,1) = size(raw,1);

    for col = 1:1:length(t_names)
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
        sg22(length(sg22)+1,:) = cell2mat(raw(i, 24));
        wp11(length(wp11)+1,:) = cell2mat(raw(i, 25));
        wp12(length(wp12)+1,:) = cell2mat(raw(i, 26));
        wp21(length(wp21)+1,:) = cell2mat(raw(i, 27));
        wp22(length(wp22)+1,:) = cell2mat(raw(i, 28));
        wp31(length(wp31)+1,:) = cell2mat(raw(i, 29));
        wp32(length(wp32)+1,:) = cell2mat(raw(i, 30));
        wp41(length(wp41)+1,:) = cell2mat(raw(i, 31));
        wp42(length(wp42)+1,:) = cell2mat(raw(i, 32));
        wp51(length(wp51)+1,:) = cell2mat(raw(i, 33));
        sgBolt(length(sgBolt)+1,:) = cell2mat(raw(i, 34));
        wp61(length(wp61)+1,:) = cell2mat(raw(i, 35));
        wp62(length(wp62)+1,:) = cell2mat(raw(i, 36));
        wp71(length(wp71)+1,:) = cell2mat(raw(i, 37));
        wp72(length(wp72)+1,:) = cell2mat(raw(i, 38));
        LC1(length(LC1)+1,:) = cell2mat(raw(i, 39));
        LC2(length(LC2)+1,:) = cell2mat(raw(i, 40));
        LC3(length(LC3)+1,:) = cell2mat(raw(i, 41));
        LC4(length(LC4)+1,:) = cell2mat(raw(i, 42));
        MTSLC(length(MTSLC)+1,:) = cell2mat(raw(i, 43));
        MTSLVDT(length(MTSLVDT)+1,:) = cell2mat(raw(i, 44));
        A(length(A)+1,:) = cell2mat(raw(i, 45));
        B(length(B)+1,:) = cell2mat(raw(i, 46));
        C(length(C)+1,:) = cell2mat(raw(i, 47));
        D(length(D)+1,:) = cell2mat(raw(i, 48));
        E(length(E)+1,:) = cell2mat(raw(i, 49));
        F(length(F)+1,:) = cell2mat(raw(i, 50));
        G(length(G)+1,:) = cell2mat(raw(i, 51));
        H(length(H)+1,:) = cell2mat(raw(i, 52));
        LP1(length(LP1)+1,:) = cell2mat(raw(i, 53));
        LP3(length(LP3)+1,:) = cell2mat(raw(i, 54));
        LP2(length(LP2)+1,:) = cell2mat(raw(i, 55));
        LP4(length(LP4)+1,:) = cell2mat(raw(i, 56));
        wp52(length(wp52)+1,:) = cell2mat(raw(i, 57));
    end
    
    %Determine column ranges to save data to
    if t_r == 1
        saveRanges(t_r,:) = [1 lengthOfFile(1)];
    else
        prev = saveRanges(t_r-1,2);
        saveRanges(t_r,:) = [(prev+1) prev+lengthOfFile(t_r)];
    end
    
    m.NormTime(saveRanges(t_r,1):saveRanges(t_r,2),1) = NormTime;
    m.run(saveRanges(t_r,1):saveRanges(t_r,2),1) = run;
    m.sg1(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg1;
    m.sg2(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg2;
    m.sg3(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg3;
    m.sg4(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg4;
    m.sg5(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg5;
    m.sg6(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg6;
    m.sg7(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg7;
    m.sg8(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg8;
    m.sg9(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg9;
    m.sg10(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg10;
    m.sg11(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg11;
    m.sg12(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg12;
    m.sg13(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg13;
    m.sg14(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg14;
    m.sg15(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg15;
    m.sg16(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg16;
    m.sg17(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg17;
    m.sg18(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg18;
    m.sg19(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg19;
    m.sg20(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg20;
    m.sg21(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg21;
    m.sg22(saveRanges(t_r,1):saveRanges(t_r,2),1) = sg22;
    m.wp11(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp11;
    m.wp12(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp12;
    m.wp21(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp21;
    m.wp22(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp22;
    m.wp31(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp31;
    m.wp32(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp32;
    m.wp41(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp41;
    m.wp42(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp42;
    m.wp51(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp51;
    m.sgBolt(saveRanges(t_r,1):saveRanges(t_r,2),1) = sgBolt;
    m.wp61(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp61;
    m.wp62(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp62;
    m.wp71(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp71;
    m.wp72(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp72;
    m.LC1(saveRanges(t_r,1):saveRanges(t_r,2),1) = LC1;
    m.LC2(saveRanges(t_r,1):saveRanges(t_r,2),1) = LC2;
    m.LC3(saveRanges(t_r,1):saveRanges(t_r,2),1) = LC3;
    m.LC4(saveRanges(t_r,1):saveRanges(t_r,2),1) = LC4;
    m.MTSLC(saveRanges(t_r,1):saveRanges(t_r,2),1) = MTSLC;
    m.MTSLVDT(saveRanges(t_r,1):saveRanges(t_r,2),1) = MTSLVDT;
    m.A(saveRanges(t_r,1):saveRanges(t_r,2),1) = A;
    m.B(saveRanges(t_r,1):saveRanges(t_r,2),1) = B;
    m.C(saveRanges(t_r,1):saveRanges(t_r,2),1) = C;
    m.D(saveRanges(t_r,1):saveRanges(t_r,2),1) = D;
    m.E(saveRanges(t_r,1):saveRanges(t_r,2),1) = E;
    m.F(saveRanges(t_r,1):saveRanges(t_r,2),1) = F;
    m.G(saveRanges(t_r,1):saveRanges(t_r,2),1) = G;
    m.H(saveRanges(t_r,1):saveRanges(t_r,2),1) = H;
    m.LP1(saveRanges(t_r,1):saveRanges(t_r,2),1) = LP1;
    m.LP3(saveRanges(t_r,1):saveRanges(t_r,2),1) = LP3;
    m.LP2(saveRanges(t_r,1):saveRanges(t_r,2),1) = LP2;
    m.LP4(saveRanges(t_r,1):saveRanges(t_r,2),1) = LP4;
    m.wp52(saveRanges(t_r,1):saveRanges(t_r,2),1) = wp52;
    
    %Determine save range
    t_complete = (t_r/t_amount)*100
    toc
    %save(sprintf('%s%d',t_saveFileAs, t_r), '-regexp', '^(?!t_.*$).')
    %save(t_saveFileAs2, '-regexp', '^(?!t_.*$).')
    clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me R amount i names textFileLocation textFileLocation textFileSeed x y j textFileName timeModifier NormTime run sg1 sg2 sg3 sg4 sg5 sg6 sg7 sg8 sg9 sg10 sg11 sg12 sg13 sg14 sg15 sg16 sg17 sg18 sg19 sg20 sg21 sg22 wp11 wp12 wp21 wp22 wp31 wp32 wp41 wp42 wp51 sgBolt wp61 wp62 wp71 wp72 LC1 LC2 LC3 LC4 MTSLC MTSLVDT A B C D E F G H LP1 LP3 LP2 LP4 wp52;
end
   tic
%Correct Time
NormTime = m.NormTime;
timeModifier = m.NormTime(2,1) - NormTime(1,1);
for x = 2:1:length(NormTime)
    NormTime(x,1) = NormTime((x-1),1)+timeModifier;
end
m.NormTime = NormTime;

clearvars -except t_saveFileAs t_saveFileAs2

%Make filter copy
copyfile(t_saveFileAs, t_saveFileAs2)
toc