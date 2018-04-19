% First check if individual WP variables still exist, if they do not, do
% not run the script.
% Note: this is dangerous if the dataset is incomplete. No failsafes. No
% need when the function is specific and I am tayloring data input.
%{
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
%}
%Pre-allocate WP variable
lengthOfWPRecord = size(m, 'wp11');

m.wp = zeros(lengthOfWPRecord(1), 15);

m.wp(:,1)  = m.wp11(:,1) + 2.71654;
m.wp(:,2)  = m.wp12(:,1) + 2.71654;
m.wp(:,3)  = m.wp21(:,1) + 2.71654;
m.wp(:,4)  = m.wp22(:,1) + 2.71654;
m.wp(:,5)  = m.wp31(:,1) + 2.71654;
m.wp(:,6)  = m.wp32(:,1) + 2.71654;
m.wp(:,7)  = m.wp41(:,1) + 2.71654;
m.wp(:,8)  = m.wp42(:,1) + 2.71654;
m.wp(:,9)  = m.wp51(:,1) + 2.71654;
m.wp(:,10) = m.wp61(:,1) + 2.71654;
m.wp(:,11) = m.wp62(:,1) + 2.71654;
%ST2 did not include WP5-2, WP7-1, or WP7-2
if ProcessShearTab ~= 2
    m.wp(:,12) = m.wp71(:,1) + 2.71654;
    m.wp(:,13) = m.wp72(:,1) + 2.71654;
    m.wp(:,14) = m.wp52(:,1) + 2.71654;
end
m.wp(:,15) = m.MTSLVDT(:,1);