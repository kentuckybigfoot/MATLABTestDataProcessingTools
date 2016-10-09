format long

ProcessFilePath              = 'C:\Users\clk0032\Dropbox\Friction Connection Research\Full Scale Test Data\FS Testing -ST3 - 08-24-16\';
ProcessFileName              = 'FS Testing - ST3 - Test 2 - 08-24-16';

ProcessFileName = fullfile(ProcessFilePath, sprintf('[Filter]%s.mat',ProcessFileName));
%{
load(ProcessFileName,'wp','NormTime','moment','beamRotation')

wp = downsample(wp,4);
NormTime = downsample(NormTime,4);
moment = downsample(moment(:,7),4);
beamRotation = downsample(beamRotation(:,13),4);
%}
[aMaxTabDisp aMinTabDisp] = peakdet(wp(:,15), 0.0625);

%Straight Line Portions
%figure
%hold on

for r = 1:1:size(aMaxTabDisp,1)
    if r < size(aMaxTabDisp,1)
        rangeDown(r,1) = aMaxTabDisp(r,1);
        rangeDown(r,2) = aMinTabDisp(r,1);
    else
        rangeDown(r,1) = aMaxTabDisp(r,1);
        rangeDown(r,2) = size(NormTime,1);
    end
    
    if r > 1
        rangeUp(r,1)  = aMinTabDisp(r-1,1);
        rangeUp(r,2)  = aMaxTabDisp(r,1);
    else
        rangeUp(r,1)  = 1;
        rangeUp(r,2)  = aMaxTabDisp(r,1);
    end
    
    %plot(beamRotation(rangeDown(r,1):rangeDown(r,2),13), moment(rangeDown(r,1):rangeDown(r,2),7));
    %plot(beamRotation(rangeUp(r,1):rangeUp(r,2),13), moment(rangeUp(r,1):rangeUp(r,2),7));
end

r = 0;

rangeScanTemp = [rangeDown; rangeUp];

[rangeScan rangeScanIndex] = sort(rangeScanTemp(:,1));

rangeScan = [rangeScan rangeScanTemp(rangeScanIndex,2)];

for r = 1:1:size(rangeScan,1)
    %Section loop
    for s = 1:1:rangeScan(r,2)-rangeScan(r,1);
        for t = 1:1:rangeScan(r,2)-(rangeScan(r,1)-1)
            break;
        end
    end
end

%{
allocationSize = (((finish-start)-1000)*(((finish-start)-1000)+1))/2;
counterInfo    = zeros(allocationSize,3);
h = 1;

for r = 1:1:1
    %Allocate room for memory
    for s = 1:1:(finish-start)
        for t = start+(s-1):1:finish
            %This is technically counting what you should count to from where you
            %are
            counterInfo(h, 1) = r;
            counterInfo(h, 2) = s;
            counterInfo(h, 3) = t;
            
            h = h + 1;
            if t+1000 >= finish
                break;
            end
        end
    end
end
%}
%Create file
%{
allPointLists = zeros(size(rangeScan,1),3);
pointList = [];

save('F:/mycopy.mat','-v7.3','pointList', 'allPointLists');

m = matfile('F:/mycopy.mat','Writable',true);

totalAllocationSize = 0;
for l = 1:1:size(rangeScan,1)
    l
    allocate = (rangeScan(r,2)-rangeScan(r,1)) - 9;
    allocationSize =  allocate*(allocate+1)/2;
    totalAllocationSize = totalAllocationSize + allocationSize;
    
     [nrows, ncols] = size(m,'pointList');
     
    if r == 1
        pointListStart = 1;
        pointListEnd   = allocationSize;
    else
        pointListStart = nrows+1;
        pointListEnd   = pointListStart+allocationSize-1;
    end
    
    m.pointList(pointListStart:pointListEnd,1:6) = 0;
end


for r = 1:1:size(rangeScan,1)
    r
    start = rangeScan(r,1);
    finish = rangeScan(r,2);
    
    allocate = (finish-start) - 9;
    allocationSize =  allocate*(allocate+1)/2;
    h = 1;
    pointList = [];
    pointList = zeros(allocationSize,3);
        
    for s = 0:1:(finish-start)
        if start+s+10 > finish
            break;
        end
        
        amount = (start+s+10:1:finish).';
        sizeAmount = size(amount,1);
        
        pointList(h:(h-1)+sizeAmount, 1:3) = [repmat(r,sizeAmount,1), repmat(start+s,sizeAmount,1), amount];
        
        h = h + sizeAmount;
    end
    
    [nrows, ~] = size(m,'pointList');
    
    if r == 1
        pointListStart = 1;
        pointListEnd   = allocationSize;
    else
        pointListStart = nrows+1;
        pointListEnd   = pointListStart+allocationSize-1;
    end
    
    m.pointList(pointListStart:pointListEnd,1:3) = pointList;
    m.allPointLists(r,1:3) = [pointListStart, pointListEnd, allocationSize];
end
%}
disp('DO ACTUAL WORK');

[nrows, ncols] = size(m, 'pointList');

for o = 0:10000:nrows-mod(nrows,10000)
    
    if o == nrows-mod(nrows,10000)
        flag = mod(nrows,10000);
    else 
        flag = 0;
    end 
    
    pointListStack1 = zeros(10000+flag,1);
    pointListStack2 = zeros(10000+flag,1);
    pointListStack3 = zeros(10000+flag,1);
    pointListStack4 = zeros(10000+flag,1);
    pointListStack5 = zeros(10000+flag,1);
    
    pointListStack1(:,1) = m.pointList(o+1:o+10000+flag,2);
    pointListStack2(:,1) = m.pointList(o+1:o+10000+flag,3);
    %{
    parfor p = 1:1:size(pointListStack1,1)
        y = moment(pointListStack1(p):pointListStack2(p));
        x = beamRotation(pointListStack1(p):pointListStack2(p));
        X = [ones(length(x),1) x];
        regre = X\y;
        pointListStack3(p) = regre(1);
        pointListStack4(p) = regre(2);
        pointListStack5(p) = 1 - sum((y - X*regre).^2)/sum((y - mean(y)).^2);
    end
    
    m.pointList(o+1:o+10000,4:6) = [pointListStack3 pointListStack4 pointListStack5];
    %}
end
%}    

%%%%%%%%% WORKS FOR FIRST
%{
%Total records minus removal of last 1000
allocationSize = (((finish-start)*((finish-start)+1))/2) - (999*(999+1))/2;
%counterInfo    = zeros(allocationSize,3);
h = 1;

for r = 2:1:2%size(rangeScan,1)

    %Allocate room for memory
    start = rangeScan(r,1);
    finish = rangeScan(r,2);
    
    for s = 1:1:(finish-start)
        
        if s+1000 > finish
            break;
        end
        
        amount = (start+s:1:finish).';
        sizeAmount = size(amount,1);
        
        counterInfo(h:(h-1)+sizeAmount, 1:3) = [repmat(r,sizeAmount,1), repmat(s,sizeAmount,1), amount];
        
        h = h + sizeAmount;
    end
end
%}
%%%%%%%%%%%%%%%%%%%%%
%{
allocationSize = (((finish-start)-1000)*(((finish-start)-1000)+1))/2;
counterInfo    = zeros(allocationSize,6);
h = 1;


for r = 1:1:1
    %Allocate room for memory
    for s = 1:1:(finish-start)
        for t = start+(s-1):1:finish
            %This is technically counting what you should count to from where you
            %are

            X = [ones(length(beamRotation(t:finish, 13)),1) beamRotation(t:finish, 13)];
            b = X\moment(t:finish,7);
            yCalc2 = X*b;
            Rsq2 = 1 - sum((moment(t:finish,7) - yCalc2).^2)/sum((moment(t:finish,7) - mean(moment(t:finish,7))).^2);
            
             counterInfo(h, 1:6) = [r s t b(1) b(2) Rsq2];
            
            h = h + 1;
            if t+1000 >= finish
                break;
            end
        end
    end
end
%}

%h = 1;
%{
aa   = zeros(allocationSize,1);
for r = 1:1:1
    %Allocate room for memory
    for s = 1:1:(finish-start)
        parfor t = start+(s-1):1:finish
            
            aa(t) = 1;
        end
    end
end
%}