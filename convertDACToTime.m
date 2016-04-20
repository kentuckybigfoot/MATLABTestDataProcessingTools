function [ digit ] = convertDACToTime( time, flag )
%UCONVERTDACTOTIME Convert DAC output to time
%   Take the output of the 8 converters on the DAC and converts them each to
%   a digit before combining them into a single digit. input is an array of
%   the DAC outputs. Output is a char array of the time in milliseconds and 
%   seconds if flag is set to true or just the assembled interger if false.
%   If not true/false flag specified, assume false.

digit = [];

if nargin == 1
    flag = false;
end

for r = 1:1:8
    
    t = time(r);
    
    if t < 200
        digit(r) = 0;
    elseif t >= 200 && t < 500
        digit(r) = 1;
    elseif t >= 500 && t < 900 
        digit(r) = 2;
    elseif t >= 900 && t < 1300
        digit(r) = 3;
    elseif t >= 1300 && t < 1650
        digit(r) = 4;
    elseif t >= 1650 && t < 2000
        digit(r) = 5;
    elseif t >= 2000 && t < 2350
        digit(r) = 6;
    elseif t >= 2350 && t < 2750
        digit(r) = 7;
    elseif t >= 2750 && t < 3100
        digit(r) = 8;
    elseif t >= 3100 && t < 3500
        digit(r) = 9;
    elseif t >= 3500
        digit(r) = 100;
    else
        error(sprintf('Intermediate value: %d (record %d)! Readjust scale.',time(r),r));
    end
end

digit = sprintf('%d%d%d%d%d%d%d%d', digit(1), digit(2), digit(3), digit(4), digit(5), digit(6), digit(7), digit(8));

if flag == false
    digit = str2double(digit);
end

end

