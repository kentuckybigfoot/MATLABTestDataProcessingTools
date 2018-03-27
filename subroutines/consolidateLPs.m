sizeOfLPRecord = size(m,'LP1');
m.lp(sizeOfLPRecord(1),4) = 0;

m.lp(:,1)  = m.LP1(:,1);
m.lp(:,2)  = m.LP2(:,1);
m.lp(:,3)  = m.LP3(:,1);
m.lp(:,4)  = m.LP4(:,1);

%m.lp(:,5)  = (offset(m.LP1(:,1)) + offset(m.LP3(:,1)))/2;
%m.lp(:,6)  = (offset(m.LP2(:,1)) + offset(m.LP4(:,1)))/2;

clearvars sizeOfLPRecord;