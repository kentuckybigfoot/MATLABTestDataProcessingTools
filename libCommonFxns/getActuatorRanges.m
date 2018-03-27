function [ ranges, MMI ] = getActuatorRanges( wp, increment )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%Get local maxima/minima of the MTS actuator LVDT. 0.1 increment because we
%know that the typical increment in cyclic tests is 1/8th of an inch

if nargin == 1
    increment = 0.1;
end

[maxtab, mintab] = peakdet(wp, increment);

maxtab(:,3) = 1;
mintab(:,3) = 0;

MMITemp = [maxtab; mintab];

[MMI MMMIindex] = sort(MMITemp(:,1));

%Location, value, and whether min or max (0 or 1, respectively)
MMI = [MMI MMITemp(MMMIindex,2) MMITemp(MMMIindex,3)];

SizeOfMMI = size(MMI,1);

ranges = zeros(SizeOfMMI, 4);

ranges(1,1) = 1;

for r = 1:1:SizeOfMMI
    if r == 1
        ranges(1,1) = 1;
        ranges(1,2) = MMI(r,1);
    elseif r == SizeOfMMI
        ranges(r,1) = MMI(r-1,1);
        ranges(r,2) = MMI(end,1);
    else
        ranges(r,1) = MMI(r-1,1);
        ranges(r,2) = MMI(r,1);
    end
end

sizeOfRanges = size(ranges, 1);
for s = 1:1:sizeOfRanges
    if s == 1
        ranges(s,3) = knnsearch(wp(ranges(s,1):ranges(s,2),1),0);
    else
        ranges(s,3) = ranges(s,1) + knnsearch(wp(ranges(s,1):ranges(s,2),1),0);
    end
end

for t = 1:1:sizeOfRanges
    if t == sizeOfRanges
        ranges(t,4) = size(wp,1);
    else
        ranges(t,4) = ranges(t+1,3);
    end
end

end