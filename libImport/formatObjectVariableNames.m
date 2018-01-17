function [ ] = formatObjectVariableNames( p, default, lookFor )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

for r = 1:length(p)
    p(r).Name = deblank(string(p(r).Name));
    for s = 1:size(p(r).Name,1)
        splits = strsplit(p(r).Name(s,:),{'(',')'},'CollapseDelimiters',false);
        p(r).Name(s,:) = splits(1,4);
        [row, ~] = find(ismember(lookFor, p(r).Name(s,:)) == 1);
        p(r).Name(s,:) = default(s,1);
    end
end
end

