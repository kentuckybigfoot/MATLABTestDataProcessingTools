function [ ] = formatObjectVariableNames( p, default, lookFor )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

    for r = 1:length(p)

        p(r).Name = deblank(string(p(r).Name));

        for s = 1:size(p(r).Name,1)

            splits = strsplit(p(r).Name(s,:),{'(',')'},'CollapseDelimiters',false);

            %Catches unamed channels present in old or incorrectly configured test configurations.
            %If unknown channel is found, special characters are removed to
            %allow for it to be saved in mat file for later review.
            if size(splits,2) < 4
                %Removes special characters, if present, from unknown channel,
                %and in a messy manner.
                locateInvalidCharacters = isstrprop(char(p(r).Name(s,:)),'alphanum');
                tempName = char(p(r).Name(s,:));
                tempName = string(tempName(1,locateInvalidCharacters));
                p(r).Name(s,:) = tempName;

                %Carry on, soldier!
                continue
            end

            p(r).Name(s,:) = splits(1,4);

            [row, ~] = find(ismember(lookFor, p(r).Name(s,:)) == 1);

            p(r).Name(s,:) = default(row,1);
        end
    end
end