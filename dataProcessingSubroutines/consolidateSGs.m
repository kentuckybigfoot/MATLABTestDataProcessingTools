%Consolidates the many strain gauge variables into a signal array
%variable for output.
%   ST1 -> sg(:,1:3)=ST1, sg(:,4)=BFFD, sg(:,5)=Bolt, sg(:,6:9)=flanges
%   ST3 -> sg(:,1:3)=ST3, sg(:,4)=BFFD, sg(:,5)=Bolt, sg(:,6:9)=flanges
%   ST2 -> sg(:,1:4)=ST2, sg(:,5)=BFFD, sg(:,6)=Bolt, sg(:,7:10)=flanges
%   ST4 -> sg(:,1:4)=ST4, sg(:,5)=BFFD, sg(:,6)=Bolt, sg(:,7:10)=flanges

sizeOfSGRecord = size(m, 'sg1');

%Shear tab and CFFD strain gauges
switch ProcessShearTab
    case 1
        m.sg(sizeOfSGRecord(1),1:9) = 0;
        m.sg(:,1) = m.sg1(:,1);
        m.sg(:,2) = m.sg2(:,1);
        m.sg(:,3) = m.sg3(:,1);
        m.sg(:,4) = m.sg4(:,1);
        %Bolt strain gauge
        m.sg(:,5) = m.sgBolt(:,1);
        %Inner column strain gauges
        m.sg(:,6) = m.sg19(:,1);
        m.sg(:,7) = m.sg20(:,1);
        m.sg(:,8) = m.sg21(:,1);
        m.sg(:,9) = m.sg22(:,1);
    case 2
        m.sg(sizeOfSGRecord(1),1:10) = 0;
        m.sg(:,1) = m.sg5(:,1);
        m.sg(:,2) = m.sg6(:,1);
        m.sg(:,3) = m.sg7(:,1);
        m.sg(:,4) = m.sg8(:,1);
        m.sg(:,5) = m.sg9(:,1);
        %Bolt strain gauge
        m.sg(:,6) = m.sgBolt(:,1);
        %Inner column strain gauges
        m.sg(:,7) = m.sg19(:,1);
        m.sg(:,8) = m.sg20(:,1);
        m.sg(:,9) = m.sg21(:,1);
        m.sg(:,10) = m.sg22(:,1);
    case 3
        m.sg(sizeOfSGRecord(1),1:9) = 0;
        m.sg(:,1) = m.sg10(:,1);
        m.sg(:,2) = m.sg11(:,1);
        m.sg(:,3) = m.sg12(:,1);
        m.sg(:,4) = m.sg13(:,1);
        %Bolt strain gauge
        m.sg(:,5) = m.sgBolt(:,1);
        %Inner column strain gauges
        m.sg(:,6) = m.sg19(:,1);
        m.sg(:,7) = m.sg20(:,1);
        m.sg(:,8) = m.sg21(:,1);
        m.sg(:,9) = m.sg22(:,1);
    case 4
        m.sg(sizeOfSGRecord(1),1:10) = 0;
        m.sg(:,1) = m.sg14(:,1);
        m.sg(:,2) = m.sg15(:,1);
        m.sg(:,3) = m.sg16(:,1);
        m.sg(:,4) = m.sg17(:,1);
        m.sg(:,5) = m.sg18(:,1);
        %Bolt strain gauge
        m.sg(:,6) = m.sgBolt(:,1);
        %Inner column strain gauges
        m.sg(:,7) = m.sg19(:,1);
        m.sg(:,8) = m.sg20(:,1);
        m.sg(:,9) = m.sg21(:,1);
        m.sg(:,10) = m.sg22(:,1);
    otherwise
        error('Unable to determine connection in data record.')
end

clearvars sizeOfSGRecord;