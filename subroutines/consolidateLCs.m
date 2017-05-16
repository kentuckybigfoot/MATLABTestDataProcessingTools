% First check if individual LC variables still exist, if they do not, do
% not run the script.
% Note: this is dangerous if the dataset is incomplete. No failsafes. No
% need when the function is specific and I am tayloring data input.
if ~exist('LC1', 'var') & ~exist('LC2', 'var') & ~exist('LC3', 'var') & ...
   ~exist('LC4', 'var') & ~exist('MTSLC', 'var')
    ProcessConsolidateLCs = false;
end

if ~exist('lc', 'var') & ProcessConsolidateLCs == false
    error('Load cell data possibly corrupt. Check data');
end

if ProcessConsolidateLCs == true
    lc(:,1) = LC1(:,1);
    lc(:,2) = LC2(:,1);
    lc(:,3) = LC3(:,1);
    lc(:,4) = LC4(:,1);
    lc(:,5) = MTSLC(:,1);
    
    %If beam is in contact with LC at the beginning of the test a
    %compressive force is occuring that can sway data if not handled
    %properly. To account for this we find the peak of the LC data (which
    %occurs when the beam is not in contact with the the LC) and offset
    %data
    [maxtab1 mintab1] = peakdet(lc(:,1), 25);
    [maxtab2 mintab2] = peakdet(lc(:,2), 25);
    [maxtab3 mintab3] = peakdet(lc(:,3), 25);
    [maxtab4 mintab4] = peakdet(lc(:,4), 25);
    
    lc(:,6) = (LC1(:,1)-LC1(maxtab1(1,1)))+(LC2(:,1)-LC2(maxtab2(1,1)));
    lc(:,7) = (LC3(:,1)-LC3(maxtab3(1,1)))+(LC4(:,1)-LC4(maxtab4(1,1)));
    
    clearvars LC1 LC2 LC3 LC4 MTSLC maxtab1 mintab1 maxtab2 mintab2 ...
              maxtab3 mintab3 maxtab4 mintab4;
          
    RemoveVariableFromMatFile(ProcessFileName,'LC1');
    RemoveVariableFromMatFile(ProcessFileName,'LC2');
    RemoveVariableFromMatFile(ProcessFileName,'LC3');
    RemoveVariableFromMatFile(ProcessFileName,'LC4');
    RemoveVariableFromMatFile(ProcessFileName,'MTSLC');
end