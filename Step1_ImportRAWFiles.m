%To-do
%Add toolbox checks
%Document
%Fix limitation of Run parameter posistion being set in findRawsInDirectory()

%Clear all isn't recommended, but is used to prevent any stragglers
clear all
close all

%Initialize suite
initializeSuite(mfilename('fullpath'))

%File import definitions
RAWDirectory     = '';
saveDir          = '';
saveName         = '';
rangeToImport    = 1000;
decimationFactor = 0;
decimateType     = 'fir';

[directoryList, runRanges] = findRawsInDirectory(RAWDirectory);

[filelist,runNumbers] = getRawsInRange(rangeToImport, directoryList, runRanges);

numberOfFilesToProcess = size(filelist,1);

for r = 1:numberOfFilesToProcess
    p(r) = PI660RawToM(fullfile(RAWDirectory, filelist(r,:)));
    p(r).DecimateBy = decimationFactor;
    p(r).decimateType = decimateType;
    p(r).DecodeDataStamp();
    p(r).DataDumpFrameInfo();
end

%Estimate length of savefile
[estLength, estRanges] = estimateVariableLengths(p);

%%Format Variable Names Names
default = ["sg1"; "sg2"; "sg3"; "sg4"; "sg5"; "sg6"; "sg7"; "sg8"; "sg9"; "sg10"; "sg11"; "sg12"; "sg13"; "sg14"; "sg15"; "sg16"; "sg17"; "sg18"; "sg19"; "sg20"; "sg21"; "sg22"; "wp11"; "wp12"; "wp21"; "wp22"; "wp31"; "wp32"; "wp41"; "wp42"; "wp51"; "sgBolt"; "wp62"; "wp61"; "wp71"; "wp72"; "LC1"; "LC2"; "LC3"; "LC4"; "MTSLC"; "MTSLVDT"; "A"; "B"; "C"; "D"; "E"; "F"; "G"; "H"; "LP1"; "LP3"; "LP2"; "LP4"; "wp52"];
lookFor = ["SG1"; "SG2"; "SG3"; "SG4"; "SG5"; "SG6"; "SG7"; "SG8"; "SG9"; "SG10"; "SG11"; "SG12"; "SG13"; "SG14"; "SG15"; "SG16"; "SG17"; "SG18"; "SG19"; "SG20"; "SG21"; "SG22"; "WP 1-1"; "WP 1-2"; "WP 2-1"; "WP 2-2"; "WP 3-1"; "WP 3-2"; "WP 4-1"; "WP 4-2"; "WP 5-1"; "Bolt"; "WP 6-2"; "WP 6-1"; "WP 7-1"; "WP 7-2"; "LC 1"; "LC 2"; "LC 3"; "LC 4"; "MTS LC"; "MTS LVDT"; "DAC A"; "DAC B"; "DAC C"; "DAC D"; "DAC E"; "DAC F"; "DAC G"; "DAC H"; "LP 1"; "LP 3"; "LP 2"; "LP 4"; "WP 5-2"];
formatObjectVariableNames(p, default, lookFor);

%Create MAT file to store data in
generateMATFile(saveDir, saveName, estLength, p(1).Name )

%Load reference to newly created MATFile
m = matfile(fullfile(saveDir,saveName), 'Writable', true);

%Preallocate import/conversion manifest
importManifest = importManifestHandler(3, m, numberOfFilesToProcess);

%Garbage collection to maximize free memory for process
clearvars RAWDirectory saveDir saveName default lookFor decimationFactor decimateType

lastTime = 0;
tic
for r = 1:numberOfFilesToProcess
    p(r).getRawData();
    p(r).ScanDataDump();
    p(r).SelectChannels();
    p(r).RawToEU
    dataFull = p(r).ReturnDataArray();
    
    %Garbage college to free memory
    p(r).RawChannelData = [];
    p(r).EUChannelData = [];
    p(r).clearRawData();
    p(r).closeDataFile();
    
    for s = 1:length(dataFull)
        m.(char(p(r).Name(s,1)))(estRanges(r,1):estRanges(r,2),1) = dataFull(s).EUData;
    end
    
    %Correct NormTime which resets to zero at each import.
    m.NormTime(estRanges(r,1):estRanges(r,2),1) = dataFull(1).Time + lastTime;
    lastTime = lastTime + (dataFull(1).Time(end,1) + (dataFull(1).Time(end,1)-dataFull(1).Time(end-1,1)));
    
    %Garbage collection to free memory.
    clear('dataFull');
    
    %Update Import Manifest
    importManifest(r) = importManifestHandler(1, p(r), estRanges(r,:));
    
    fprintf('Import and conversion %d of %d complete\n', r, numberOfFilesToProcess);
end
toc
%Save import manifest
importManifestHandler(2, m, importManifest);