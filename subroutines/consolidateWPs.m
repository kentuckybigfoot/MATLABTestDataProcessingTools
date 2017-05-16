% First check if individual WP variables still exist, if they do not, do
% not run the script.
% Note: this is dangerous if the dataset is incomplete. No failsafes. No
% need when the function is specific and I am tayloring data input.
if ~exist('wp11', 'var') & ~exist('wp12', 'var') & ~exist('wp21', 'var') & ...
   ~exist('wp22', 'var') & ~exist('wp31', 'var') & ~exist('wp32', 'var') & ...
   ~exist('wp41', 'var') & ~exist('wp42', 'var') & ~exist('wp51', 'var') & ...
   ~exist('wp52', 'var') & ~exist('wp61', 'var') & ~exist('wp62', 'var') & ...
   ~exist('wp71', 'var') & ~exist('wp72', 'var') & ~exist('MTSLVDT', 'var')
    ProcessConsolidateWPs = false;
end

if ~exist('wp', 'var') & ProcessConsolidateWPs == false
    error('Wire pot data possibly corrupt. Check data');
end

% Slightly faster to use cat(), but this provides us with a handy name 
% chart at minimal performance expense.
if ProcessConsolidateWPs == true
    wp(:,1)  = wp11(:,1);
    wp(:,2)  = wp12(:,1);
    wp(:,3)  = wp21(:,1);
    wp(:,4)  = wp22(:,1);
    wp(:,5)  = wp31(:,1);
    wp(:,6)  = wp32(:,1);
    wp(:,7)  = wp41(:,1);
    wp(:,8)  = wp42(:,1);
    wp(:,9)  = wp51(:,1);
    wp(:,10) = wp61(:,1);
    wp(:,11) = wp62(:,1);
    wp(:,12) = wp71(:,1);
    wp(:,13) = wp72(:,1);
    wp(:,14) = wp52(:,1);
    wp       = wp + 2.71654;
    wp(:,15) = MTSLVDT(:,1);
    
    clearvars wp11 wp12 wp21 wp22 wp31 wp32 wp41 wp42 wp51 wp61 wp62 ...
              wp71 wp72 MTSLVDT;
    
    RemoveVariableFromMatFile(ProcessFileName,'wp11');
    RemoveVariableFromMatFile(ProcessFileName,'wp12');
    RemoveVariableFromMatFile(ProcessFileName,'wp21');
    RemoveVariableFromMatFile(ProcessFileName,'wp22');
    RemoveVariableFromMatFile(ProcessFileName,'wp31');
    RemoveVariableFromMatFile(ProcessFileName,'wp32');
    RemoveVariableFromMatFile(ProcessFileName,'wp41');
    RemoveVariableFromMatFile(ProcessFileName,'wp42');
    RemoveVariableFromMatFile(ProcessFileName,'wp51');
    RemoveVariableFromMatFile(ProcessFileName,'wp52');
    RemoveVariableFromMatFile(ProcessFileName,'wp61');
    RemoveVariableFromMatFile(ProcessFileName,'wp62');
    RemoveVariableFromMatFile(ProcessFileName,'wp71');
    RemoveVariableFromMatFile(ProcessFileName,'wp72');
    RemoveVariableFromMatFile(ProcessFileName,'MTSLVDT');
end