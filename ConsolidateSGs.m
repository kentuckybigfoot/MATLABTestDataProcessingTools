function [ sg ] = ConsolidateSGs( ShearTab, filename )
%UNTITLED2 Summary of this function goes here
%   Consolidates the many strain gauge variables into a signal array
%   variable for output.
%   ST1 -> sg(:,1:3)=ST1, sg(:,4)=BFFD, sg(:,5)=Bolt, sg(:,6:9)=flanges
%   ST3 -> sg(:,1:3)=ST3, sg(:,4)=BFFD, sg(:,5)=Bolt, sg(:,6:9)=flanges
%   ST2 -> sg(:,1:4)=ST2, sg(:,5)=BFFD, sg(:,6)=Bolt, sg(:,7:10)=flanges
%   ST4 -> sg(:,1:4)=ST4, sg(:,5)=BFFD, sg(:,6)=Bolt, sg(:,7:10)=flanges

%Shear tab and CFFD strain gauges
    if ShearTab == '1'
        load(filename, 'sg1', 'sg2', 'sg3', 'sg4', 'sgBolt', 'sg19', 'sg20', 'sg21', 'sg22');
        sg(:,1) = sg1(:,1);
        sg(:,2) = sg2(:,1);
        sg(:,3) = sg3(:,1);
        sg(:,4) = sg4(:,1);
    elseif ShearTab == '2'
        load(filename, 'sg5', 'sg6', 'sg7', 'sg8', 'sg9', 'sgBolt', 'sg19', 'sg20', 'sg21', 'sg22');
        sg(:,1) = sg5(:,1);
        sg(:,2) = sg6(:,1);
        sg(:,3) = sg7(:,1);
        sg(:,4) = sg8(:,1);
        sg(:,5) = sg9(:,1);
    elseif ShearTab == '3'
        load(filename, 'sg10', 'sg11', 'sg12', 'sg13', 'sgBolt', 'sg19', 'sg20', 'sg21', 'sg22');
        sg(:,1) = sg10(:,1);
        sg(:,2) = sg11(:,1);
        sg(:,3) = sg12(:,1);
        sg(:,4) = sg13(:,1);
    else
        load(filename, 'sg14', 'sg15', 'sg16', 'sg17', 'sg18', 'sgBolt', 'sg19', 'sg20', 'sg21', 'sg22');
        sg(:,1) = sg14(:,1);
        sg(:,2) = sg15(:,1);
        sg(:,3) = sg16(:,1);
        sg(:,4) = sg17(:,1);
        sg(:,5) = sg18(:,1);
    end
    
    %Bolt strain gauge
    sg(:,size(sg,2)+1) = sgBolt(:,1);
    
    %Inner column strain gauges
    sg(:,size(sg,2)+1) = sg19(:,1);
    sg(:,size(sg,2)+1) = sg20(:,1);
    sg(:,size(sg,2)+1) = sg21(:,1);
    sg(:,size(sg,2)+1) = sg22(:,1);

end

