% First check if individual WP variables still exist, if they do not, do
% not run the script.
% Note: this is dangerous if the dataset is incomplete. No failsafes. No
% need when the function is specific and I am tayloring data input.
if ~exist('LP1', 'var') & ~exist('LP2', 'var') & ~exist('LP3', 'var') & ...
   ~exist('LP4', 'var')
    ProcessConsolidateLPs = false;
end

if ~exist('lp', 'var') & ProcessConsolidateLPs == false
    error('LP data possibly corrupt. Check data');
end

if ProcessConsolidateLPs == true
    lp(:,1)  = LP1(:,1);
    lp(:,2)  = LP2(:,1);
    lp(:,3)  = LP3(:,1);
    lp(:,4)  = LP4(:,1);
    
    lp(:,5)  = (offset(LP1(:,1)) + offset(LP3(:,1)))/2;
    lp(:,6)  = (offset(LP2(:,1)) + offset(LP4(:,1)))/2;
    
    clearvars LP1 LP2 LP3 LP4;
    
    RemoveVariableFromMatFile(ProcessFileName,'LP1');
    RemoveVariableFromMatFile(ProcessFileName,'LP2');
    RemoveVariableFromMatFile(ProcessFileName,'LP3');
    RemoveVariableFromMatFile(ProcessFileName,'LP4');

end