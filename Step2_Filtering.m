close all
clear
clc

filename = '[Filter]FS Testing - ST2 - Test 1 - 01-25-16.mat';
names = {'NormTime','run','sg1','sg2','sg3','sg4','sg5','sg6','sg7','sg8','sg9','sg10','sg11','sg12','sg13','sg14','sg15','sg16','sg17','sg18','sg19','sg20','sg21','sg22','wp11','wp12','wp21','wp22','wp31','wp32','wp41','wp42','wp51','sgBolt','wp61','wp62','LC1','LC2','LC3','LC4','MTSLC','MTSLVDT'};
variableToFilter = 'LC1';

load(filename, 'NormTime', variableToFilter);

fs = 100;             % Sampling frequency
t = NormTime;         % Sample Time
L = length(t);        % Length of signal
Fpass = 0.0028*2*(1/fs);
Fstop = 0.00857*2*(1/fs);
Ap    = 0.00000001;
Ast   = 0.0000001;

%What almost all of the sgs were saved using
%Fpass = 0.00158*2*(1/fs);
%Fstop = 0.00316*2*(1/fs);
%Ap    = 0.00000001;
%Ast   = 0.0000001;
%saveFilteredData('[Filter]FS Testing - ST2 - Test 1 - 01-15-16.mat', 'sg7', F, '[Fpass; Fstop; Ap; Ast]')

%filterPlotModify('-add', 'h', NormTime, '', sg5, 0.00158*2*(1/fs), 0.00316*2*(1/fs), 0.00000001, 0.0000001, 'wiene')
%filterPlotModify('-add', 'h', NormTime, '', sg5, 0.00158*2*(1/fs), 0.00316*2*(1/fs), 0.0000000001, 0.000000001, 'wiene')

%{
wp31F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];
wp32F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];
wp41F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];
wp41F = [0.001753*2*(1/fs) 0.005259*2*(1/fs) 0.00001 0.0001];
wp42F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];
wp42F = [0.001753*2*(1/fs) 0.005259*2*(1/fs) 0.00001 0.0001];
sg5F  = [0.001753*2*(1/fs) 0.005259*2*(1/fs) 0.000000001 0.00000001];
sg6F  = [0.001753*2*(1/fs) 0.005259*2*(1/fs) 0.00000001 0.0000001];
sg7F  = [0.001753*2*(1/fs) 0.005259*2*(1/fs) 0.0000001 0.000001];
sg8F  = [0.001753*2*(1/fs) 0.005259*2*(1/fs) 0.000000001 0.00000001];
sg9F  = [0.005259*2*(1/fs) 0.01052*2*(1/fs) 0.00001 0.0001];
%}

%load(filename);
%Run Fast Fourier Transform
fftRun = fft(eval(variableToFilter));

%Calculate power spectral density
psd = fftRun.*conj(fftRun)/L;

%Calculate normalized frequency and then multiply by number of samples to get frequency range. Halved due to nyquist (mirrors after half)
f = (fs/L)*(0:ceil(L/2)-1);

% plot(f(1,1:ceil(L/2)), psd(1:ceil(L/2),1));
%title(sprintf('Power spectral density %s', variableToFilter))
%xlabel('Frequencies (Hz)')

%figure()
%stem(f(1,1:ceil(L/2)), psd(1:ceil(L/2),1));
%title(sprintf('Power spectral density %s', variableToFilter))
%xlabel('Frequencies (Hz)')

figure();
plot(f(1,2:ceil(L/2)), psd(2:ceil(L/2),1));
title(sprintf('Power spectral density %s (zoomed)', variableToFilter))
xlim([0 0.1]);
xlabel('Frequencies (Hz)')

figure();
stem(f(1,2:ceil(L/2)), psd(2:ceil(L/2),1));
title(sprintf('Power spectral density %s (zoomed)', variableToFilter))
xlim([0 0.1]);
xlabel('Frequencies (Hz)')


d = designfilt('lowpassiir', 'PassbandFrequency', Fpass, ...
               'StopbandFrequency', Fstop, 'PassbandRipple', Ap, ...
               'StopbandAttenuation', Ast, 'DesignMethod', 'butter' ...
               );
           
F = filtfilt(d,eval(variableToFilter));

figure();
hold on
h1 = plot(NormTime, eval(variableToFilter));
h2 = plot(NormTime, F);
%filterPlotModify('-add', 'h', NormTime, '', wp32, 0.003506*2*(1/fs), 0.01052*2*(1/fs), 0.01, 0.1, 'wiene')
wp31F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];
wp32F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];
wp41F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];
wp42F = [0.001753*2*(1/fs) 0.008765*2*(1/fs) 0.01 0.1];

