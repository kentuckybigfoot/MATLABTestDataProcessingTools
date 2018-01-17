function [ x ] = undoEUConv( x, sensitivity, voltageOffset, voltageSlope, gain )
%undoEUConv Converts DAQ engineering unit data back to ADC values.
%   
        x = x / sensitivity;
        x = x - voltageOffset;
        x = x / voltageSlope;
        x = x * gain;
        x = x * 32767.0;
        x = x / 10000;
        x = round(x);
end

