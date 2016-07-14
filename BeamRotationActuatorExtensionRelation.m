%Relate beam rotation back to actuator piston extension
clear
close all

%make matfile object due to huge file sizes
genDir = 'C:\Users\clk0032\Dropbox\Friction Connection Research\Full Scale Test Data\';
dir1 = 'FS Testing -ST1 - 06-27-16';

m1 = matfile(fullfile(genDir,dir1,'[Filter]FS Testing - ST1 - Test 6 - 06-27-16.mat'));

%Load NormTime into memory so we do not have problems with descritizing.
NormTime = m1.NormTime;

%Mean of beam rotations
beamRotationMean = mean(m1.beamRotation(:,13));

%Actuator min/max ranges
[ranges MMI] = getActuatorRanges(m1.wp(:,15));

%Beam Rotation min/max ranges
[ranges2 MMI2] = getActuatorRanges((m1.beamRotation(:,13)-beamRotationMean)*(pi/180), 0.0001);

%Actuator Extension with min/max overlayed
figure
plot(NormTime, m1.wp(:,15))
hold on
scatter(NormTime(MMI(:,1)), MMI(:,2))

%Beam rotation with min/max overlayed
figure
plot(NormTime, (m1.beamRotation(:,13)-beamRotationMean)*(pi/180))
hold on
scatter(NormTime(MMI2(:,1)), MMI2(:,2))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get beam rotation related to actuator extension
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for s = 1:1:size(MMI,1)
    %Value index, actuator extension, beam rotation
    rel1(s,:) = [MMI(s,1) MMI(s,2) m1.beamRotation(MMI(s,1),13)*(pi/180)];
end

%Polyfit the relationship. First pad with zeros for easier copying to
%excel, then add polyfit to array, then generate R2 and append to beginning
rel1Poly = zeros(6,8);
for s2 = 1:6
    %Actualy polyfit
    [pp, ss] = polyfit(rel1(:,2),rel1(:,3),s2);
    %Coefficient of determination (R^2)
    rel1Poly(s2,1) = 1 - (ss.normr^2 / norm(rel1(:,3)-mean(rel1(:,3)))^2);
    %Polynomial coefficients
    rel1Poly(s2,2:s2+2) = fliplr(pp);
end

%Scatter beam rotation values at maxima/minima actuator extension values
%over beam rotation vs. time.
figure
plot(NormTime, (m1.beamRotation(:,13)-beamRotationMean)*(pi/180))
hold on

for x = 1:size(MMI,1)
    tempVar(x,1) = m1.beamRotation(MMI(x,1),13)-beamRotationMean;
end

scatter(NormTime(MMI(:,1)), tempVar*(pi/180))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Get beam rotation and actuator piston extension related to beam rotation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for t = 1:1:size(MMI2,1)
    %Value index, actuator extension, beam rotation
    rel2(t,:) = [MMI2(t,1) m1.wp(MMI2(t,1),15) MMI2(t,2)];
end

%Polyfit the relationship. First pad with zeros for easier copying to
%excel, then add polyfit to array, then generate R2 and append to beginning
rel2Poly = zeros(6,8);
for t2 = 1:6
    %Actualy polyfit
    [pp2, ss2] = polyfit(rel2(:,2),rel2(:,3),t2);
    %Coefficient of determination (R^2)
    rel2Poly(t2,1) = 1 - (ss2.normr^2 / norm(rel2(:,3)-mean(rel2(:,3)))^2);
    %Polynomial coefficients
    rel2Poly(t2,2:t2+2) = fliplr(pp2);
end

%Scatter actuator extension values at maxima/minima beam rotation values
%over actuator extenion vs. time.
figure
plot(NormTime, m1.wp(:,15))
hold on

for x2 = 1:size(MMI2,1)
    tempVar2(x2,1) = m1.wp(MMI2(x2,1),15);
end

scatter(NormTime(MMI2(:,1)), tempVar2)

%Overlay scatter of min/max over actuator extension lengths and beam
%rotation amounts, respectively
figure;
plot(NormTime, m1.wp(:,15));
hold on
scatter(NormTime(MMI(:,1)), rel1(:,2))

figure;
plot(NormTime, m1.beamRotation(:,13)*(pi/180));
hold on
scatter(NormTime(MMI2(:,1)), rel2(:,3))
