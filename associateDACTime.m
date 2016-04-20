function [ DACTimeIndex ] = associateDACTime( DACTime, MilliTime )
%ASSOCIATEDACTIME Returns IMU data row that correspondes to NormTime rows
%   Input: DACTime, MilliTime.
%   Output: DACTimeIndex
%   See detailed code commentary.

%Attemp to find array index of matching DACTime value in IMU data. If no
%matching value is found, say index is 0 (Doesn't exist)
for r = 1:1:length(DACTime)
    value = find(MilliTime == DACTime(r,1));
    
    if ~isempty(value)
        DACTimeIndex(r,1) = value(1,1);
    else
        DACTimeIndex(r,1) = 0;
    end
end

%Determine ranges to search across. Starting time is found by matching the
%output of the DAC read by the DAQ to the output of the Arduino program
%recorded by a serial terminal program. At the start and stop of a test the
%DAC goes through a pattern of being set to high (>10^8) and then low/off
%(0). The last to occur of this pattern is a 0 with the first a high value
%>10^8. To determine the stopping point, the first value >10^8 is matched
%and the record less than that considered the last of the desired data.
start = find(DACTime == MilliTime(1),1,'first');
stop  = (start + find(DACTime(start:end) > 10^8,1,'first')) - 2;

DACTime(1:start-1) = DACTime(start);

%Orphan control. Due to electrical jitter the time output of the ADC chip 
%for the least significant digit may vary from what was actually output by
%the Arduino program. This attempts to rectify this by finding the value
%closest to the orphan time value and using it.
for s = start:1:stop
    if DACTimeIndex(s) ~= 0
        continue;
    end
    
    timeRecorded = DACTime(s);
    timeBefore   = MilliTime(DACTimeIndex(s-1));
    timeAfter    = MilliTime(DACTimeIndex(s+1));
    timeRange    = [timeBefore timeAfter];
    
    [c index] = min(abs(timeRange-timeRecorded));
    
    DACTimeIndex(s,1) = find(MilliTime == timeRange(index));
end

%Set all DACTimeIndex rows before valid data aquisition/sync to equal the
%first data record from the IMU.
DACTimeIndex(1:(find(DACTimeIndex == 1,1,'first')-1)) = 1;

%Set all DACTimeIndex rows after valid data aquisition/sync to equal the
%final data record of interest from the IMU
DACTimeIndex(DACTimeIndex == 0) = DACTimeIndex(stop);
end

