% PI660RawToM 
% This m file reads/converts PI660 RAW data files into
% matlab/octave workspace variables. ONLY V10 files!
% (C) 2016 p.w. wong phil@weballey.com 
% Pacific Instruments, Inc. Concord, CA
% Revision History:
% 07/04/2016 V.1.0 Initial Release
%
% How To Use: (comments in [])
%   [instantiate the class]
% p = PI660RawToM ('SomePI660RawFile.raw')
%   [return the data]
% data = p.DoItAll()
%   [data is composed of the following fields: 
%    data(:).Descriptor
%    data(:).Time
%    data(:).NumberOfChannels
%    data(:).Units
%    data(:).RawADC
%    data(:).EUData ]
% Of course, the channels parameters are also available. Just
% gotta look inside this code.

%%%
%Look at
% - Incorrect 4th, 5th, etc calibration factors being input
% - removing this.Datawidths(ScanIndex) == 4 in input
% - Add octave check
classdef PI660RawToM < handle
    properties
        SyncPattern;
        run;
        datastream;
        channels;
        rackchannels;
        descriptor;
        scanlistblocks;
        blocks;
        ScanList;
        Datawidths;
        streamtype;
        blockrate;
        sensitivities;
        offsets;
        squared;
        cubed;
        gains;
        means;
        PostBalanceMv;
        icard;
        ColorInformation;
        Name;
        Units;
        Description;
        Location;
        Rate;
        GageType;
        TempConversion;
        PeriodsOrModes;
        TimeBase;
        VoltageOffset;
        VoltageSlope;
        AutobalanceEnable;
        InputAttenuation;
        RangeMultiplier;
        LookupTable;
        RackChName;
        RackChUnits;
        RackChHighAlarm;
        RackChHighWarn;
        RackChLowAlarm;
        RackChLowWarn;
        RackChHighAlarmType;
        RackChLowAlarmType;
        RackChHighWarnType;
        RackChLowWarnType;
        RackChAlarmColor;
        RackChWarningColor;
        RackChDataColor;
        RackChAlarmMask;
        RackChAlarmVector;
        RackChWarnMask;
        RackChWarnVector;
        % sizeof(UsedTable) = 1220 bytes
        UsedTable;
        PacificText;
        UserText;
        TempReferenceChannels;
        IcePointTemp;
        Fourth;
        Fifth;
        Sixth;
        Seventh;
        Eighth;
        Ninth;
        VoltageOffsetArray;
        VoltageSlopeArray;
        FireSwitchTiming;
        DataTestChannel;
        DataTestType;
        DataTestValue;
        DataTestVector
        intest;
        ChargeCaps_6068FC9;
        RangeResistors_6068FC9;
        StampSize;
        NumberOfRackChannels ;
        V10HeaderSize;
        TablesUsed;
        MaxTableEntries;
        PI660Version;
        NumberOfEntries;
        NumberOfChannels;
        EstDataStampSize;
        %The following variables are for my housekeeping
        filename;
        fid;
        RawData;
        isHeadless = true;
        decimateType = 'fir';
        MaxChannels = 0;
        FrameBufferSize;
        DataFrameSize;
        NumberOfDataFramesInFile;
        RawChannelData;
        EUChannelData;
        Time;
        DecimateBy = 0;
        ChannelSelector = 0;
        NumOfChanSelected = 0;
        BlockMapLengths;
        ScanDataSyncPattern = hex2dec ('2840fe6b'); %0x2840fe6b;
        enumCardTypes = {  	'CARD6033';	'CARD6013';	'CARD6018';	'CARD6040'; ...
                            'CARD6046'; 'CARD6048';	'CARD6014'; ...
                            'CARD6055'; 'CARD6047';	'CARD6028';	'CARD6041'; ...
                            'CARD6032';	'CARD6030';	'CARD6021';	'CARD6120'; ...
                            'CARD9016';
                            'CARD6042';	'CARD8400';	'CARD6093';	'CARD6031'; ...
                            'CARD6035';
                            'CARD6036';	'CARD7216';	'CARD6060'; ...
                            'CARD6016';
                            'CARD6037';	'CARD6160';	'CARD6017';	'CARD6029'; ...
                            'CARD6038';	'CARDINITIUM';	'CARDMOOG';	'CARDCANBUS';	
                            'CARD6039';	'CARD6062';	'CARD6052';	'CARD6044'; ...
                            'CARD6068';	'CARD2017';	'CARD1017';	'CARD6049'; ...
                            'CARD1052' };
        enumGageTypes = { 'GAGEBRIDGE';	'GAGEICP';	'GAGEVOLTAGE'; ...
                          'GAGEDCLVDT';	'GAGERTD'; 'GAGEFREQUENCY'; ...
                          'GAGEPERIOD'; 'GAGECOUNTER'; 'GAGEDIGITAL'; ...
                          'GAGEIRIG'; 'GAGEDAC'; 'GAGE5500'; ...
                          'GAGEDIGITALOUT'; 'GAGETCB'; 'GAGETCC'; ...
                          'GAGETCE'; 'GAGETCJ';	'GAGETCK'; 'GAGETCN'; ...
                          'GAGETCR'; 'GAGETCS'; 'GAGETCT'; 'GAGETCREF'; ...
                          'GAGEQTR120'; 'GAGEQTR350'; 'GAGEHALF'; ...
                          'GAGEFULL'; 'GAGEFREQUENCY32'; 'GAGEPERIOD32'; ...
                          'GAGECOUNTER32'; 'GAGEFTOV'; 'GAGEDSP'; ...
                          'GAGEDIGITALIN'; 'GAGE8400'; 'GAGECHARGE'; ...
                          'GAGESTATUS'; 'GAGEINITIUM'; 'GAGE9016'; ...
                          'GAGEMOOG'; 'GAGECANBUS'; };
    end
    methods
      function obj = PI660RawToM (filename)
          if nargin == 0
              error ('Need File Name');
          else
              obj.filename = filename;
              obj.fid = fopen (filename);
              fseek (obj.fid, -36, 'eof');
              obj.StampSize = fread(obj.fid,1,'int32');
              obj.NumberOfRackChannels = fread (obj.fid, 1, 'int32');
              obj.V10HeaderSize = fread (obj.fid, 1, 'int32');
              obj.TablesUsed = fread(obj.fid, 1, 'int32');
              obj.MaxTableEntries = fread(obj.fid, 1, 'int32');
              obj.PI660Version = fread(obj.fid, 1, 'double');
              obj.NumberOfEntries = fread(obj.fid, 1, 'int32');
              obj.NumberOfChannels = fread(obj.fid, 1, 'int32');
              obj.SyncPattern = hex2dec ('6cfe0000'); %0x6cfe0000;
              obj.MaxChannels = 4096;

              obj.CheckRawVersion();
          end
      end
      
      function getRawData (this)
          fseek (this.fid, 0, 'bof');
          this.RawData = fread(this.fid, 'short');
      end
      
      function clearRawData (this)
          this.RawData = [];
      end
      
      function GetEstDataStampSize (this)
          this.EstDataStampSize = 4 + 4 + 4 ...
              + (4 * this.NumberOfChannels) ...
              + (4 * this.NumberOfRackChannels) ...
              + 508 + 4 ...
              + (3 * (4 * this.NumberOfEntries))  ...
              + 4 + 8 ...
              + (8 * 14 * this.NumberOfChannels)  ...
              + (4 * this.MaxChannels) ...
              + (224 * this.NumberOfChannels) ...
              + (108 * this.NumberOfRackChannels) ...
              + (1220 * this.TablesUsed) ...
              + 512 + 512 ...
              + (4 * this.MaxChannels) ...
              + 8 + ...
              + 6 * (8 * this.NumberOfChannels) ...
              + 2 * (16 * 8 * this.NumberOfChannels) ...
              + 4 + 4 + 4 + 8 + 2  ...
              + (4 * this.NumberOfChannels) ...
              + (8 * 4) + (8 * 4) + 4 ...
              + 32;
      end

      function CheckRawVersion (this)
          if (this.PI660Version < 10.0)
              fprintf (1, 'WARNING: Very old RAW file detected  v.%f \n\n', this.PI660Version);
              error('Exiting...\n');
          end
              
          if (this.PI660Version < 10.110004)
              msg = 'WARNING: Older RAW file detected v.%f\n\n';
          end

          if ((this.PI660Version >= 10.06) && (this.PI660Version ...
                                               < 10.100023))
              this.StampSize = this.StampSize + 8;
              msg = 'Adjusting stampsize by 8 bytes.\n\n';
          end
          
          this.GetEstDataStampSize();
          if ~this.isHeadless
            fprintf(1, msg, this.PI660Version);
            fprintf(1, 'File open successful.\n\n');
          end
      end
      
      function DecodeDataStamp (this)
          fseek (this.fid, -this.StampSize, 'eof');
          this.SyncPattern = fread (this.fid, 1, 'int32');
          this.run = fread (this.fid, 1, 'int32');
          this.datastream = fread (this.fid, 1, 'int32');
          this.channels = fread (this.fid, this.NumberOfChannels, 'int32');
          this.rackchannels = fread (this.fid, this.NumberOfRackChannels, 'int32');
          this.descriptor = fread (this.fid, 508, 'uchar');
          
          % this is to fix the uninitialize data structure in
          % the PI software by nullifying the rest of the
          % string after the null terminator.
          % loop looking for the first null terminator then
          % zap the rest of the string
          %{
          nullify = 0;
          for (xxx = 1:508)
              if (nullify == 0)
                  if (this.descriptor(xxx) == 0)
                      nullify = 1;
                  end
              else
                  this.descriptor(xxx) = 0;
              end
          end
          %}
          this.descriptor = deblank(char (this.descriptor'));
          this.scanlistblocks = fread (this.fid, 1, 'int32');
          this.blocks = fread (this.fid, this.NumberOfEntries, 'int32');
          this.ScanList = fread (this.fid, this.NumberOfEntries, 'int32');
          this.Datawidths = fread (this.fid, this.NumberOfEntries, 'int32');
          this.streamtype = fread (this.fid, 1, 'int32');
          this.blockrate = fread (this.fid, 1, 'double');
          this.sensitivities = fread (this.fid, this.NumberOfChannels, 'double');
          this.offsets = fread (this.fid, this.NumberOfChannels, 'double');
          this.squared = fread (this.fid, this.NumberOfChannels,  'double');
          this.cubed = fread (this.fid, this.NumberOfChannels, 'double');
          this.gains = fread (this.fid, this.NumberOfChannels, 'double');
          this.means = fread (this.fid, [this.NumberOfChannels, 8], 'double');
          this.PostBalanceMv = fread (this.fid, this.NumberOfChannels, 'double');

          this.icard = fread (this.fid, this.MaxChannels,  'int32');

          this.ColorInformation = fread (this.fid, 52 * this.NumberOfChannels, 'char');
          this.Name = fread (this.fid, [32, this.NumberOfChannels], 'char');
          %disp(char(deblank(cellstr(char(Name')))));
          this.Name = char(deblank (cellstr(char(this.Name'))));
          %this.Name = deblank(char (this.Name'));

          this.Units = fread (this.fid, [8, this.NumberOfChannels], 'char');
          this.Units = char(deblank(cellstr(char (this.Units'))));
          
          %{
          this.Description = fread (this.fid, [30, this.NumberOfChannels], 'char');
          this.Description = char(deblank(cellstr(char (this.Description'))));
          this.Location = fread (this.fid, [30, this.NumberOfChannels], 'char');
          this.Location = char(deblank (cellstr(char (this.Location'))));
          
          this.Rate = fread (this.fid, this.NumberOfChannels, 'double');
          %}
          this.GageType = fread (this.fid, this.NumberOfChannels, 'int32');
          this.TempConversion = fread (this.fid, this.NumberOfChannels, 'int32');
          this.PeriodsOrModes = fread (this.fid, this.NumberOfChannels, 'double');
          this.TimeBase = fread (this.fid, this.NumberOfChannels, 'double');    
          this.VoltageOffset = fread (this.fid, this.NumberOfChannels, 'double');
          this.VoltageSlope = fread (this.fid, this.NumberOfChannels,'double');
          this.AutobalanceEnable = fread (this.fid, this.NumberOfChannels,'int32');
          this.InputAttenuation = fread (this.fid, this.NumberOfChannels, 'double');
          this.RangeMultiplier = fread (this.fid, this.NumberOfChannels, 'double');
          this.LookupTable = fread (this.fid, this.NumberOfChannels, 'int32');
          this.RackChName = fread (this.fid, [32, this.NumberOfRackChannels], 'char');
          this.RackChName = deblank(char (this.RackChName'));
          this.RackChUnits = fread (this.fid, [8, this.NumberOfRackChannels], 'char');
          this.RackChUnits = deblank(char (this.RackChUnits'));
          this.RackChHighAlarm = fread (this.fid, this.NumberOfRackChannels, 'double');
          this.RackChHighWarn = fread (this.fid, this.NumberOfRackChannels, 'double');
          this.RackChLowAlarm = fread (this.fid, this.NumberOfRackChannels, 'double');
          this.RackChLowWarn = fread (this.fid, this.NumberOfRackChannels, 'double');
          this.RackChHighAlarmType = fread (this.fid, this.NumberOfRackChannels, 'int32');
          this.RackChLowAlarmType = fread (this.fid, this.NumberOfRackChannels, 'int32');
          this.RackChHighWarnType = fread (this.fid, this.NumberOfRackChannels, 'int32');
          this.RackChLowWarnType = fread (this.fid, this.NumberOfRackChannels, 'int32');
          this.RackChAlarmColor = fread (this.fid, this.NumberOfRackChannels, 'uint32');
          this.RackChWarningColor = fread (this.fid, this.NumberOfRackChannels, 'uint32');
          this.RackChAlarmMask = fread (this.fid, this.NumberOfRackChannels, 'uint16');
          this.RackChAlarmVector = fread (this.fid, this.NumberOfRackChannels,'uint16');
          this.RackChWarnMask = fread (this.fid, this.NumberOfRackChannels, 'uint16');
          this.RackChAlarmVector = fread (this.fid, this.NumberOfRackChannels, 'uint16');
          this.UsedTable = fread (this.fid, 1220, 'char');   % decode this later
          this.PacificText = fread (this.fid, 512, 'char');
          this.UserText = fread (this.fid, 512, 'char');
          this.TempReferenceChannels = fread (this.fid, this.MaxChannels, 'int32');
          this.IcePointTemp = fread (this.fid, 1, 'double');
          this.Fourth = fread (this.fid, this.NumberOfChannels,  'double');
          this.Fifth = fread (this.fid, this.NumberOfChannels,  'double');
          this.Sixth = fread (this.fid, this.NumberOfChannels,  'double');
          this.Seventh = fread (this.fid, this.NumberOfChannels, 'double');
          this.Eighth = fread (this.fid, this.NumberOfChannels, 'double');
          this.Ninth = fread (this.fid, this.NumberOfChannels,  'double');
          this.VoltageOffsetArray = fread (this.fid, [16, this.NumberOfChannels], 'double');
          this.VoltageSlopeArray = fread (this.fid, [16, this.NumberOfChannels], 'double');
          this.FireSwitchTiming = fread (this.fid, 1, 'int32');
          this.DataTestChannel = fread (this.fid, 1, 'int32');
          this.DataTestType = fread (this.fid, 1, 'int32');
          this.DataTestValue = fread (this.fid, 1, 'double');
          this.DataTestVector = fread (this.fid, 1, 'short');
          this.intest = fread (this.fid, this.NumberOfChannels, 'int32');
          this.ChargeCaps_6068FC9 = fread (this.fid, 4, 'double');
          this.RangeResistors_6068FC9 = fread (this.fid, 4, 'double');
      end
      
      function DataDumpFrameInfo(this)
          this.FrameBufferSize = 16 + (this.NumberOfRackChannels * 2) + (2 * this.NumberOfEntries);
          
          fseek (this.fid, 0, 'eof');
          
          this.DataFrameSize = ftell(this.fid) - this.StampSize;
          
          this.NumberOfDataFramesInFile = this.DataFrameSize / this.FrameBufferSize;
          
          fseek (this.fid, 0, 'bof');
      end
      
      function ScanDataDump (this)
          this.DataDumpFrameInfo();
          
          %fprintf (1, 'Entries per frame %d, Frames %d         \n\n',  this.NumberOfEntries,this.NumberOfDataFramesInFile);
          fprintf (1, 'Entries per frame %d, Frames %d \n',  this.NumberOfEntries,this.NumberOfDataFramesInFile);
          %It is faster to create a temp variable to work with than loading
          %directly to obj.
          RawChannelDataTemp = zeros(this.scanlistblocks * this.NumberOfDataFramesInFile, this.NumberOfChannels);
          
          uniqueBlocks = unique(this.ScanList(:,1));
          for s = 1:this.NumberOfChannels
              [row(s).rows,~] = find(this.ScanList(:,1) == uniqueBlocks(s));
          end
          
          for s = 1:this.NumberOfChannels
              this.ScanList(row(s).rows,1) = s;
          end
          
          Row = 1;
          r = 1;
          for FrameIndex = 1:this.NumberOfDataFramesInFile
              CurrentBlock = 0;
              r = r + 8;
              %Decode the entire frame
              for ScanIndex = 1:this.NumberOfEntries
                  blockIndex = this.blocks(ScanIndex);
                  rowUsed = Row + blockIndex; %Row + CurrentBlock;
                  colUsed = this.ScanList(ScanIndex); %r - FirstCol;
                  
                  % preinitialize the next row entries with previous
                  % data so that subsampled channels can have repeated data
                  if (CurrentBlock ~= blockIndex)
                      RawChannelDataTemp(rowUsed,:) = RawChannelDataTemp(Row,:);
                      CurrentBlock = blockIndex;
                  end
                  
                  RawChannelDataTemp(rowUsed, colUsed) = this.RawData(r,1); %fread (this.fid, 1, 'short');
                  
                  r = r + 1;
                  
              end
              
              Row = Row + this.scanlistblocks;
              %fprintf (1,'\b\b\b\b\b\b\b\b\b\b\b%7d ...', FrameIndex);
          end
          this.RawChannelData = RawChannelDataTemp;
          
          if ~this.isHeadless
            fprintf (1, 'Formatting data...');
          end
          
          skipSequence = (1/this.blockrate);
          endSequence = (((this.NumberOfDataFramesInFile * this.scanlistblocks) - 1) * (1.0/this.blockrate));
          this.Time = 0:skipSequence:endSequence;
          
          if ~this.isHeadless
            fprintf (1,' Done!\n');
          end
      end
      
      function retval = GetCardType (this, chan)
          retval = (this.enumCardTypes((this.icard(chan)+1), :));
      end
      
      function retval = GetGageType (this, chan)
          retval = (this.enumGageTypes((this.GageType(chan)+1), ...
                                       :));
      end
      
      function GetBlockMapLength (this)
          y = 0;
          this.BlockMapLengths = zeros (this.scanlistblocks, 1);
          for index = 1:this.NumberOfEntries
              if (this.blocks(index) == y)
                  this.BlockMapLengths(y+1) = this.BlockMapLengths(y+1) + 1;
              else
                  y = y + 1;
                  this.BlockMapLengths(y+1) = this.BlockMapLengths(y+1) + 1;
              end
          end
      end
      
      function SelectChannels (this)
          if ~this.isHeadless
              this.SelectChannelsInteractive();
          else
              this.ChannelSelector = -1;
          end
      end         
      
      function SelectChannelsInteractive (this)
          fprintf (1, '\nChannels in test:\n');
          for idx = 1: this.NumberOfChannels
              %fprintf (1, '%d :: %s \n', idx, char
              %(this.Name(idx,:)'));
             fprintf (1, '%d :: %s \n', idx, char(this.Name(idx,:))); 
          end
          this.ChannelSelector = 0;
          fprintf (1, '\n');
          instring = lower(input('Enter range (ex: 1-3,4) or ALL: ', 's'));

          if (strcmp(instring, 'all') > 0)  % all found
              fprintf (1, 'All channels selected. \n\n');
              this.ChannelSelector = -1;
          else
              % split the array in comma separated string pieces
              arraystring = strsplit(instring,',');
              [~, sizearray] = size(arraystring);
              
              if (str2double(char(arraystring(sizearray))) > ...
                  this.NumberOfChannels)
                  error ('Greater than available. \n');
              end
          
              chselected = 0;
              this.NumOfChanSelected = 0;
          
              for i = 1: sizearray
                  % now check for the -
                  instring2 = strsplit (char(arraystring(i)), '-');
                  [~, nc] = size (instring2);
                  if (nc > 1)
                      % parse the -
                      if (str2double(char(instring2(1))) > ...
                          str2double(char(instring2(2))))
                          error ('Range error. ');
                      elseif (str2double(char(instring2(2))) > ...
                              this.NumberOfChannels)
                          error ('Out of Range. \n');
                      else
                          for chsel = str2double(char(instring2(1))) : ...
                                      str2double(char(instring2(2)))
                              this.ChannelSelector (chsel) = 1;
                              chselected = chselected + 1;
                          end
                      end
                  else
                      if (str2double(char(arraystring(i))) > ...
                          this.NumberOfChannels)
                          error ('Out of Range\n');
                      end

                      this.ChannelSelector (str2double(char(arraystring(i)))) ...
                          = 1;
                      chselected = chselected + 1;
                  end
              end
              fprintf (1, '%d channels selected. \n\n', chselected);
              this.NumOfChanSelected = chselected;
          end

          this.DecimateBy = input ('Decimate by (0 for NONE): ');
      end

      function RawToEU (this)
          for index = 1: this.NumberOfChannels
              mVrto = 10000.0 * this.RawChannelData(:,index) / 32767.0;
              mVrti = mVrto / this.gains(index);
              mVt = (mVrti * this.VoltageSlope(index)) + ...
                    this.VoltageOffset(index);
              this.EUChannelData(:,index) = ...
                (mVt * this.sensitivities(index)) + ...
                %{
                (mVt.^2 * this.squared(index)) + ...
                (mVt.^3 * this.cubed(index)) + ...
                (mVt.^4 * this.Fourth(index)) + ...
                (mVt.^6 * this.Fifth(index)) + ...
                (mVt.^7 * this.Seventh(index)) + ...
                (mVt.^8 * this.Eighth(index)) + ...
                (mVt.^9 * this.Ninth(index)) + ...
                %}
                this.offsets(index);
          end
      end
      
      function retval = ReturnDataArray(this)
          dataarray.Descriptor = this.descriptor;
          
          if this.ChannelSelector(1) == -1  %all channels selected
              dataarray.NumberOfChannels = this.NumberOfChannels;
              if (this.DecimateBy == 0) % all times selected
                  dataarray.Time = this.Time';
                  for idx = 1: this.NumberOfChannels
                      dataarray(idx).Name = this.Name(idx,:);
                      dataarray(idx).Units = this.Units(idx,:);
                      dataarray(idx).RawADC = this.RawChannelData(:,idx);
                      dataarray(idx).EUData = this.EUChannelData(:,idx);
                  end
              else
                  if this.decimateType == 'fir'
                      dataarray.Time = decimate(this.Time',this.DecimateBy, this.decimateType);
                      for idx = 1: this.NumberOfChannels
                          dataarray(idx).Name = this.Name(idx,:);
                          dataarray(idx).Units = this.Units(idx,:);
                          dataarray(idx).RawADC = decimate(this.RawChannelData(:,idx),this.DecimateBy, this.decimateType);
                          dataarray(idx).EUData = decimate(this.EUChannelData(:,idx),this.DecimateBy, this.decimateType);
                      end
                  else
                      dataarray.Time = this.Time';
                      dataarray.Time = dataarray.Time(1:this.DecimateBy:end);
                      for idx = 1:this.NumberOfChannels
                          dataarray(idx).Name = this.Name(idx,:);
                          dataarray(idx).Units = this.Units(idx,:);
                          dataarray(idx).RawADC = this.RawChannelData(1:this.DecimateBy:end,idx);
                          dataarray(idx).EUData = this.EUChannelData(1:this.DecimateBy:end,idx);
                      end
                  end
              end
              retval = dataarray;
          else
              dataarray.NumberOfChannels = ...
                  this.NumOfChanSelected;
              dataarray.Time = this.Time';
              [~, scanrange] = (size (this.ChannelSelector));
              if (this.DecimateBy == 0) % all times selected
                  idxnext = 1;
                  for idx = 1:scanrange
                      if (this.ChannelSelector(idx) == 1)
                          dataarray(idxnext).Name = this.Name(idx,:);
                          dataarray(idxnext).Units = this.Units(idx, :);
                          dataarray(idxnext).RawADC = this.RawChannelData(:, ...
                                                                      idx);
                          dataarray(idxnext).EUData = this.EUChannelData(:, ...
                                                                     idx);
                          idxnext = idxnext + 1;
                      end
                  end
              else
                  dataarray.Time = this.Time';
                  dataarray.Time = dataarray.Time(1: ...
                                                  this.DecimateBy:end);
                  [~, scanrange] = size (this.ChannelSelector);
                  idxnext = 1;
                  for idx = 1:scanrange
                      if (this.ChannelSelector(idx) == 1)
                          dataarray(idxnext).Name = this.Name(idx, ...
                                                              :);
                          dataarray(idxnext).Units = this.Units(idx,: ...
                                                                );
                          dataarray(idxnext).RawADC = ...
                              this.RawChannelData(1:this.DecimateBy:end, ...
                                                  idx);
                          dataarray(idxnext).EUData = ...
                              this.EUChannelData(1:this.DecimateBy:end, ...
                                                 idx);
                          idxnext = idxnext + 1;
                      end
                  end
              end
              retval = dataarray;
          end
      end
      
      function retval = DoItAll (this)
          fprintf (1, 'Opening file. \nDecoding header. \n');
          
          this.DecodeDataStamp();
          fprintf (1, 'Scanning data. \n');
          
          this.ScanDataDump();
          this.RawToEU();
          this.SelectChannels();
          retval = this.ReturnDataArray();
          fprintf (1, '\nReturning data. \n');

          fprintf (1, 'Fields: Descriptor, NumberOfChannels, ');

          fprintf (1, 'Time, Name, Units, RawADC, EUData\n\n ');
      end
      
      function closeDataFile (this)
          fclose(this.fid);
      end
  end
end