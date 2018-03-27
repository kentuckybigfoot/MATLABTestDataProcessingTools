sizeOfLCRecord = size(m, 'LC1');
m.lc(sizeOfLCRecord(1),1:7) = 0;

m.lc(:,1) = m.LC1(:,1);
m.lc(:,2) = m.LC2(:,1);
m.lc(:,3) = m.LC3(:,1);
m.lc(:,4) = m.LC4(:,1);
m.lc(:,5) = m.MTSLC(:,1);

%If beam is in contact with LC at the beginning of the test a
%compressive force is occuring that can sway data if not handled
%properly. To account for this we find the peak of the LC data (which
%occurs when the beam is not in contact with the the LC) and offset
%data
[maxtab1 mintab1] = peakdet(m.lc(:,1), 25);
[maxtab2 mintab2] = peakdet(m.lc(:,2), 25);
[maxtab3 mintab3] = peakdet(m.lc(:,3), 25);
[maxtab4 mintab4] = peakdet(m.lc(:,4), 25);

m.lc(:,6) = (m.LC1(:,1)-m.LC1(maxtab1(1,1),1))+(m.LC2(:,1)-m.LC2(maxtab2(1,1),1));
m.lc(:,7) = (m.LC3(:,1)-m.LC3(maxtab3(1,1),1))+(m.LC4(:,1)-m.LC4(maxtab4(1,1),1));

clearvars sizeOfLCRecord maxtab1 mintab1 maxtab2 mintab2 maxtab3 mintab3 maxtab4 mintab4;