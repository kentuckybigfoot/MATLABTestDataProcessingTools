% First check if individual SG variables still exist, if they do not, do
% not run the script.
% Note: this is dangerous if the dataset is incomplete. No failsafes. No
% need when the function is specific and I am tayloring data input.
if ~exist('sg1', 'var') & ~exist('sg2', 'var') & ~exist('sg3', 'var') & ...
   ~exist('sg4', 'var') & ~exist('sg5', 'var') & ~exist('sg6', 'var') & ...
   ~exist('sg7', 'var') & ~exist('sg8', 'var') & ~exist('sg9', 'var') & ...
   ~exist('sg10', 'var') & ~exist('sg11', 'var') & ~exist('sg12', 'var') & ...
   ~exist('sg13', 'var') & ~exist('sg14', 'var') & ~exist('sg15', 'var') & ...
   ~exist('sg16', 'var') & ~exist('sg17', 'var') & ~exist('sg18', 'var') & ...
   ~exist('sg19', 'var') & ~exist('sg20', 'var') & ~exist('sg21', 'var') & ...
   ~exist('sg22', 'var')
    ProcessConsolidateSGs = false;
end

if ~exist('sg', 'var') & ProcessConsolidateSGs == false
    error('Strain gauge data possibly corrupt. Check data');
end

if ProcessConsolidateSGs == true
    %   Consolidates the many strain gauge variables into a signal array
    %   variable for output.
    %   ST1 -> sg(:,1:3)=ST1, sg(:,4)=BFFD, sg(:,5)=Bolt, sg(:,6:9)=flanges
    %   ST3 -> sg(:,1:3)=ST3, sg(:,4)=BFFD, sg(:,5)=Bolt, sg(:,6:9)=flanges
    %   ST2 -> sg(:,1:4)=ST2, sg(:,5)=BFFD, sg(:,6)=Bolt, sg(:,7:10)=flanges
    %   ST4 -> sg(:,1:4)=ST4, sg(:,5)=BFFD, sg(:,6)=Bolt, sg(:,7:10)=flanges

    %Shear tab and CFFD strain gauges
    if ProcessShearTab == '1'
        sg(:,1) = sg1(:,1);
        sg(:,2) = sg2(:,1);
        sg(:,3) = sg3(:,1);
        sg(:,4) = sg4(:,1);
    elseif ProcessShearTab == '2'
        sg(:,1) = sg5(:,1);
        sg(:,2) = sg6(:,1);
        sg(:,3) = sg7(:,1);
        sg(:,4) = sg8(:,1);
        sg(:,5) = sg9(:,1);
    elseif ProcessShearTab == '3'
        sg(:,1) = sg10(:,1);
        sg(:,2) = sg11(:,1);
        sg(:,3) = sg12(:,1);
        sg(:,4) = sg13(:,1);
    else
        sg(:,1) = sg14(:,1);
        sg(:,2) = sg15(:,1);
        sg(:,3) = sg16(:,1);
        sg(:,4) = sg17(:,1);
        sg(:,5) = sg18(:,1);
    end
    
    endSize = size(sg,2);
    
    %Bolt strain gauge
    sg(:,endSize+1) = sgBolt(:,1);
    
    %Inner column strain gauges
    sg(:,endSize+2) = sg19(:,1);
    sg(:,endSize+3) = sg20(:,1);
    sg(:,endSize+4) = sg21(:,1);
    sg(:,endSize+5) = sg22(:,1);
    
    clearvars sg1 sg2 sg3 sg4 sg5 sg6 sg7 sg8 sg9 sg10 sg11 sg12 sg13 ...
              sg14 sg15 sg16 sg17 sg18 sg19 sg20 sg21 sg22 sgBolt;
    
    RemoveVariableFromMatFile(ProcessFileName,'sg1');
    RemoveVariableFromMatFile(ProcessFileName,'sg2');
    RemoveVariableFromMatFile(ProcessFileName,'sg3');
    RemoveVariableFromMatFile(ProcessFileName,'sg4');
    RemoveVariableFromMatFile(ProcessFileName,'sg5');
    RemoveVariableFromMatFile(ProcessFileName,'sg6');
    RemoveVariableFromMatFile(ProcessFileName,'sg7');
    RemoveVariableFromMatFile(ProcessFileName,'sg8');
    RemoveVariableFromMatFile(ProcessFileName,'sg9');
    RemoveVariableFromMatFile(ProcessFileName,'sg10');
    RemoveVariableFromMatFile(ProcessFileName,'sg11');
    RemoveVariableFromMatFile(ProcessFileName,'sg12');
    RemoveVariableFromMatFile(ProcessFileName,'sg13');
    RemoveVariableFromMatFile(ProcessFileName,'sg14');
    RemoveVariableFromMatFile(ProcessFileName,'sg15');
    RemoveVariableFromMatFile(ProcessFileName,'sg16');
    RemoveVariableFromMatFile(ProcessFileName,'sg17');
    RemoveVariableFromMatFile(ProcessFileName,'sg18');
    RemoveVariableFromMatFile(ProcessFileName,'sg19');
    RemoveVariableFromMatFile(ProcessFileName,'sg20');
    RemoveVariableFromMatFile(ProcessFileName,'sg21');
    RemoveVariableFromMatFile(ProcessFileName,'sg22');
    RemoveVariableFromMatFile(ProcessFileName,'sgBolt');
end