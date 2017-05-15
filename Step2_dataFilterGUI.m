function filterGUI

filename = 'I:\FS Testing -ST3 - 08-18-16\[Filter]FS Testing - ST3 - Test 9 - 08-18-16.mat';

d1 = load(filename, 'NormTime');

sensorNames       = {'NormTime','run','sg1','sg2','sg3','sg4','sg5','sg6','sg7','sg8','sg9','sg10','sg11','sg12','sg13','sg14','sg15','sg16','sg17','sg18','sg19','sg20','sg21','sg22','wp11','wp12','wp21','wp22','wp31','wp32','wp41','wp42','wp51','wp52','sgBolt','wp61','wp62','wp71','wp72','LC1','LC2','LC3','LC4','MTSLC','MTSLVDT','A','B','C','D','E','F','G','H','LP1','LP2','LP3','LP4'};

%Allocate variables that describe variable to be filtered
filterVariable = [];
filterVariableName = '';
filterVariableKey = '';
dataToSave = '';

%Allocate active filter plot
filterVariableFocus = '1';

%Filter Options
recFreq = [];
recStr  = [];

%Initial values.
t     = d1.NormTime;                 % Sample Time
L     = length(t);                  % Length of signal
fs    = 1/(t(2)-t(1));              % Sampling frequency
Fpass = 0;%0.0028*2*(1/fs);
Fstop = 0;%0.00857*2*(1/fs);
Ap    = 0;%0.00000001;0
Ast   = 0;%0.0000001;

%,'outerposition', [0 0 1 1]2
filterGUIFFTFig = figure('Visible','on','Position',[0 0 1400 1000], 'CloseRequestFcn', @clearData);
filterGUIFig = figure('Visible','off', 'Position', [0 0 1400 1000], 'CloseRequestFcn', @clearData);

%Generate Axes to control location and focus. Also turn on grids here.
%Note that position always works: [left bottom width height]
FFTAxes1 = axes('Parent', filterGUIFFTFig, 'Units', 'pixels', 'Position', [50,425,1200,575]);
FFTAxes2 = axes('Parent', filterGUIFFTFig, 'Units', 'pixels', 'Position', [50,75,1200,250]);
filterDataFilteredAxes = axes('Parent', filterGUIFig, 'Units', 'pixels', 'Position', [50,75,1000,800]);

%"hold on" stops MATLAB from destroying my filtered data handles while the
%zeroes generated are to prepopulate the plots so they can be updated
%without warning later.
hold on;
fakeData = zeros(size(t,1),size(t,2));

%Pre-create graphs so they are global and can be populated from functions
fftStem1 = stem(1, 1, 'Parent', FFTAxes1);
fftStem2 = stem(1, 1, 'Parent', FFTAxes2);
filterDataOriginal = plot(fakeData, fakeData, 'Parent', filterDataFilteredAxes);
filterDataFiltered1 = plot(fakeData, fakeData, 'Parent', filterDataFilteredAxes, 'Visible', 'off');
filterDataFiltered2 = plot(fakeData, fakeData, 'Parent', filterDataFilteredAxes, 'Visible', 'off');
filterDataFiltered3 = plot(fakeData, fakeData, 'Parent', filterDataFilteredAxes, 'Visible', 'off');
filterDataFiltered4 = plot(fakeData, fakeData, 'Parent', filterDataFilteredAxes, 'Visible', 'off');
filterDataFiltered5 = plot(fakeData, fakeData, 'Parent', filterDataFilteredAxes, 'Visible', 'off');

%Add FFT GUI components
fftDataSelectText  = uicontrol('Parent', filterGUIFFTFig, 'Style','text','String','Select Data for FFT',...
    'Position',[1300,985,100,15]);
fftDataSelect = uicontrol('Parent', filterGUIFFTFig, 'Style','popupmenu',...
    'String',sensorNames,...
    'Position',[1300,960,100,25],...
    'Callback',@FFTPlot);
fftNextButton = uicontrol('Parent', filterGUIFFTFig ,'String','Next >>',...
    'Position',[1300 400 50 25],...
    'Callback',@dataFiltering);

%Add filter GUI components
filterControlText  = uicontrol('Parent', filterGUIFig, 'Style','text','String','Plotting Controls (On, Off, Focus)', 'Position',[1050,860,100,15]);
filterControlTextG0  = uicontrol('Parent', filterGUIFig, 'Style', 'text', 'String', 'Original', 'Position',[1050,840,60,15]);
filterDataFilteredG0 = uibuttongroup('Parent', filterGUIFig, 'Tag', '0', 'BorderType', 'None', 'Units', 'pixels', 'Position', [1115 840 225 17], 'SelectionChangedFcn', @filterChangeDisplay);
r1G0 = uicontrol(filterDataFilteredG0,'Style', 'radiobutton', 'String','On', 'Position',[0 0 50 15], 'HandleVisibility','off');
r2G0 = uicontrol(filterDataFilteredG0,'Style', 'radiobutton', 'String', 'Off', 'Position', [50 0 50 15], 'HandleVisibility','off');
c1G0 = uicontrol(filterDataFilteredG0,'Style', 'checkbox', 'String', 'Active', 'Tag', '0', 'Position', [100 0 50 15], 'HandleVisibility', 'off', 'callback', @filterChangeFocus);
b1G0 = uicontrol(filterDataFilteredG0 ,'String', 'Save', 'Position', [165, 0 50 15], 'Callback', @saveData);

filterControlTextG1  = uicontrol('Parent', filterGUIFig, 'Style','text','String','Group 1', 'Position',[1050,810,60,15]);
filterDataFilteredG1 = uibuttongroup('Parent', filterGUIFig, 'Tag', '1', 'BorderType', 'None', 'Units', 'pixels', 'Position', [1115 810 200 17], 'SelectionChangedFcn', @filterChangeDisplay);
r1G1 = uicontrol(filterDataFilteredG1,'Style', 'radiobutton', 'String','On', 'Position', [0 0 50 15], 'HandleVisibility','off');
r2G1 = uicontrol(filterDataFilteredG1,'Style', 'radiobutton', 'String', 'Off', 'Value', 1, 'Position', [50 0 50 15], 'HandleVisibility','off');
c1G1 = uicontrol(filterDataFilteredG1,'Style', 'checkbox', 'String', 'Active', 'Tag', '1', 'Position', [100 0 50 15], 'HandleVisibility','off', 'callback', @filterChangeFocus);
              
filterControlTextG2  = uicontrol('Parent', filterGUIFig, 'Style','text','String','Group 2', 'Position',[1050,780,60,15]);
filterDataFilteredG2 = uibuttongroup('Parent', filterGUIFig, 'Tag', '2', 'BorderType', 'None', 'Units', 'pixels', 'Position', [1115 780 200 17], 'SelectionChangedFcn', @filterChangeDisplay);
r1G2 = uicontrol(filterDataFilteredG2,'Style', 'radiobutton', 'String', 'On', 'Position',[0 0 50 15], 'HandleVisibility', 'off');
r2G2 = uicontrol(filterDataFilteredG2,'Style', 'radiobutton', 'String', 'Off', 'Value', 1, 'Position',[50 0 50 15], 'HandleVisibility', 'off');
c1G2 = uicontrol(filterDataFilteredG2,'Style', 'checkbox', 'String', 'Active', 'Tag', '2', 'Position',[100 0 50 15], 'HandleVisibility', 'off', 'callback', @filterChangeFocus);

filterControlTextG3  = uicontrol('Parent', filterGUIFig, 'Style','text','String','Group 3', 'Position',[1050,750,60,15]);
filterDataFilteredG3 = uibuttongroup('Parent', filterGUIFig, 'Tag', '3', 'BorderType', 'None', 'Units', 'pixels', 'Position', [1115 750 200 17], 'SelectionChangedFcn', @filterChangeDisplay);
r1G3 = uicontrol(filterDataFilteredG3,'Style', 'radiobutton', 'String','On', 'Position',[0 0 50 15], 'HandleVisibility', 'off');
r2G3 = uicontrol(filterDataFilteredG3,'Style', 'radiobutton', 'String', 'Off', 'Value', 1, 'Position',[50 0 50 15], 'HandleVisibility', 'off');
c1G3 = uicontrol(filterDataFilteredG3,'Style', 'checkbox', 'String', 'Active', 'Tag', '3', 'Position',[100 0 50 15], 'HandleVisibility', 'off', 'callback', @filterChangeFocus);

filterControlTextG4  = uicontrol('Parent', filterGUIFig, 'Style','text','String','Group 4', 'Position',[1050,720,60,15]);
filterDataFilteredG4 = uibuttongroup('Parent', filterGUIFig, 'Tag', '4', 'BorderType', 'None', 'Units', 'pixels', 'Position', [1115 720 200 17], 'SelectionChangedFcn', @filterChangeDisplay);
r1G4 = uicontrol(filterDataFilteredG4,'Style', 'radiobutton', 'String','On', 'Position',[0 0 50 15], 'HandleVisibility', 'off');
r2G4 = uicontrol(filterDataFilteredG4,'Style', 'radiobutton', 'String', 'Off', 'Value', 1, 'Position',[50 0 50 15], 'HandleVisibility', 'off');
c1G4 = uicontrol(filterDataFilteredG4,'Style', 'checkbox', 'String','Active', 'Tag', '4', 'Position',[100 0 50 15], 'HandleVisibility', 'off', 'callback', @filterChangeFocus);

filterControlTextG5  = uicontrol('Parent', filterGUIFig, 'Style','text','String','Group 5', 'Position',[1050,690,60,15]);
filterDataFilteredG5 = uibuttongroup('Parent', filterGUIFig, 'Tag', '5', 'BorderType', 'None', 'Units', 'pixels', 'Position', [1115 690 200 17], 'SelectionChangedFcn', @filterChangeDisplay);
r1G5 = uicontrol(filterDataFilteredG5,'Style', 'radiobutton', 'String', 'On', 'Position',[0 0 50 15], 'HandleVisibility', 'off');
r2G5 = uicontrol(filterDataFilteredG5,'Style', 'radiobutton', 'String', 'Off', 'Value', 1, 'Position',[50 0 50 15], 'HandleVisibility', 'off');
c1G5 = uicontrol(filterDataFilteredG5,'Style', 'checkbox', 'String','Active', 'Tag', '5', 'Position',[100 0 50 15], 'HandleVisibility', 'off', 'callback', @filterChangeFocus);

filterControlText1  = uicontrol('Parent', filterGUIFig, 'Style', 'text', 'String', 'FPass', 'Position', [1050,650,60,15]);
filterFPassBox = uicontrol('Parent', filterGUIFig, 'Tag', 'Fpass', 'Style', 'edit', 'String', '0', 'Position', [1115,650,125,15], 'keyPressFcn', @modifyFilter, 'KeyReleaseFcn', @modifyFilter);

filterControlText2  = uicontrol('Parent', filterGUIFig, 'Style', 'text', 'String', 'FStop', 'Position',[1050,610,60,15]);
filterFStopBox = uicontrol('Parent', filterGUIFig, 'Tag', 'Fstop', 'Style', 'edit', 'String', '0', 'Position', [1115,610,125,15], 'keyPressFcn', @modifyFilter, 'KeyReleaseFcn', @modifyFilter);

filterControlText3  = uicontrol('Parent', filterGUIFig, 'Style', 'text', 'String', 'Ap', 'Position',[1050,570,60,15]);
filterFApBox = uicontrol('Parent', filterGUIFig, 'Tag', 'Ap', 'Style', 'edit', 'String', '0', 'Position', [1115,570,125,15], 'keyPressFcn', @modifyFilter, 'KeyReleaseFcn', @modifyFilter);

filterControlText4  = uicontrol('Parent', filterGUIFig, 'Style', 'text', 'String', 'Ast', 'Position',[1050,530,60,15]);
filterFAstBox = uicontrol('Parent', filterGUIFig, 'Tag', 'Ast', 'Style', 'edit', 'String', '0', 'Position', [1115,530,125,15], 'keyPressFcn', @modifyFilter, 'KeyReleaseFcn', @modifyFilter);

filterTable  = uicontrol('Parent', filterGUIFig, 'Style', 'text', 'String', 'Reccomended Frequencies from FFT', 'Position',[1050,500,200,15]);
filterTableElements = uitable('Parent', filterGUIFig, 'Position', [1060,275,185,202],...
    'rowName', {'1','2','3','4','5','6','7','8','9','10'},...
    'columnName', {'Freq (Hz)', 'PSD'},...
    'columnEditable',[true true]);

filterControlText1.Units = 'Normalized';
filterFPassBox.Units = 'Normalized';
filterControlText2.Units = 'Normalized';
filterFStopBox.Units = 'Normalized';
filterControlText3.Units = 'Normalized';
filterFApBox.Units = 'Normalized';
filterControlText4.Units = 'Normalized';
filterFAstBox.Units = 'Normalized';
filterTable.Units = 'Normalized';
filterTableElemnts.Units = 'Normalized';

%Turn on major and minor X-Y grids in axes.
FFTAxes1.XGrid = 'on';
FFTAxes1.YGrid = 'on';
FFTAxes1.XMinorGrid = 'on';
FFTAxes1.YMinorGrid = 'on';
FFTAxes2.XGrid = 'on';
FFTAxes2.YGrid = 'on';
FFTAxes2.XMinorGrid = 'on';
FFTAxes2.YMinorGrid = 'on';
filterDataFilteredAxes.XGrid = 'on';
filterDataFilteredAxes.YGrid = 'on';
filterDataFilteredAxes.XMinorGrid = 'on';
filterDataFilteredAxes.YMinorGrid = 'on';

%Add titles and other properties for FFT stem plots
title(FFTAxes1, 'Power spectral density plot Zoomed)');
xlim(FFTAxes1, [0 0.1]);
xlabel(FFTAxes1, 'Frequencies (Hz)')
title(FFTAxes2, 'Power spectral density plot');
xlabel(FFTAxes2, 'Frequencies (Hz)')

%Now that axes() has been used to set initial position of plots and the
%positions of the UI elements have been defined, set units to 'normalized'
%to allow graphs and UI elements to adjust to different window sizes.
% % General % %
filterGUIFFTFig.Units = 'normalized';
filterGUIFig.Units = 'normalized';
% % FFT Components % %
FFTAxes1.Units = 'normalized';
FFTAxes2.Units = 'normalized';
% % FFT Components % %
fftDataSelectText.Units = 'normalized';
fftDataSelect.Units = 'normalized';
%fftTableSelection.Units = 'normalized';
%fftTableElements.Units = 'normalized';
fftNextButton.Units = 'normalized';
% % Filter Components  % %
filterDataFilteredAxes.Units = 'normalized';
filterControlText.Units = 'normalized';
filterControlTextG0.Units = 'normalized';
filterDataFilteredG0.Units = 'normalized';
r1G0.Units = 'normalized';
r2G0.Units = 'normalized';
c1G0.Units = 'normalized';
filterControlTextG1.Units = 'normalized';
filterDataFilteredG1.Units = 'normalized';
r1G1.Units = 'normalized';
r2G1.Units = 'normalized';
c1G1.Units = 'normalized';
filterControlTextG2.Units = 'normalized';
filterDataFilteredG2.Units = 'normalized';
r1G2.Units = 'normalized';
r2G2.Units = 'normalized';
c1G2.Units = 'normalized';
filterControlTextG3.Units = 'normalized';
filterDataFilteredG3.Units = 'normalized';
r1G3.Units = 'normalized';
r2G3.Units = 'normalized';
c1G3.Units = 'normalized';
filterControlTextG4.Units = 'normalized';
filterDataFilteredG4.Units = 'normalized';
r1G4.Units = 'normalized';
r2G4.Units = 'normalized';
c1G4.Units = 'normalized';
filterControlTextG5.Units = 'normalized';
filterDataFilteredG5.Units = 'normalized';
r1G5.Units = 'normalized';
r2G5.Units = 'normalized';
c1G5.Units = 'normalized';

%set(findobj(filterGUIFFTFig),'Units','Normalized')
%set(findobj(filterGUIFig),'Units','Normalized')

    function FFTPlot(source,eventData)
        d = load(filename, sensorNames{source.Value});
        filterVariable = d.(sensorNames{source.Value});
        filterVariableName = source.String{source.Value};
        filterVariableKey = source.Value;
        
        %Run Fast Fourier Transform
        fftRun = fft(filterVariable);
        
        %Calculate power spectral density
        psd = fftRun.*conj(fftRun)/L;
        
        %Calculate normalized frequency and then multiply by number of samples to get frequency range. Halved due to nyquist (mirrors after half)
        f = (fs/L)*(0:ceil(L/2)-1);
        
        %Update Stem plot data
        fftStem1.XData = f(1,1:ceil(L/2));
        fftStem1.YData = psd(1:ceil(L/2),1);
        fftStem2.XData = f(1,1:ceil(L/2));
        fftStem2.YData = psd(1:ceil(L/2),1);
        
        recFreq = f(1,1:25);
        recStr  = psd(1:25,1);
        
        filterTableElements.Data = [recFreq' recStr];
        
        %Update stem plot title
        title(FFTAxes1, sprintf('Power Spectral Density Plot of %s (Zoomed)', filterVariableName));
        title(FFTAxes2, sprintf('Power Spectral Density Plot of %s (Full view)', filterVariableName));
    end

    function dataFiltering(source,eventData)
        filterGUIFFTFig.Visible = 'off';
        filterGUIFig.Visible = 'on';
        
        filterDataOriginal.XData = d1.NormTime;
        filterDataOriginal.YData = filterVariable;
        
        %Update axis and titles
        if ~isempty(strfind(filterVariableName,'sg'))
            yLabelString = 'Strain Gauge Reading (uStrain)';
        elseif ~isempty(strfind(filterVariableName,'wp')) || ~isempty(strfind(filterVariableName,'LVDT'))
            yLabelString = 'Displacement Reading (inches)';
        elseif ~isempty(strfind(filterVariableName,'LC')) && strcmp(filterVariableName,'MTSLC')
            yLabelString = 'Load Cell Reading (lbf)';
        else 
            yLabelString = 'Load Cell Reading (kip)';
        end
            
        title(filterDataFilteredAxes, sprintf('Plot of %s vs. Normal Time', filterVariableName));
        xlabel(filterDataFilteredAxes, 'Time (sec)')
        ylabel(filterDataFilteredAxes, yLabelString)
        
        filterDataOriginal.Visible = 'On';
        
        filterDataFFTAxes = axes('Parent', filterGUIFig, 'Units', 'pixels', 'Position', [1075,65,200,200]);
        filterDataFFTPlot = stem(recFreq, recStr, 'Parent', filterDataFFTAxes);
        
        filterDataFFTAxes.Units = 'Normalized';
        filterDataFFTPlot = 'Normalized';
    end

    function filterChangeDisplay(source, eventData)
        switch source.Tag
            case '0'
                if strcmp(eventData.NewValue.String, 'On')
                    filterDataOriginal.Visible = 'On';
                else
                   filterDataOriginal.Visible = 'Off';
                end
            case '1'
                if strcmp(eventData.NewValue.String, 'On')
                    filterDataFiltered1.Visible = 'On';
                else
                    filterDataFiltered1.Visible = 'Off';
                end
            case '2'
                if strcmp(eventData.NewValue.String, 'On')
                    filterDataFiltered2.Visible = 'On';
                else
                    filterDataFiltered2.Visible = 'Off';
                end
           case '3'
                if strcmp(eventData.NewValue.String, 'On')
                    filterDataFiltered3.Visible = 'On';
                else
                    filterDataFiltered3.Visible = 'Off';
                end
          case '4'
                if strcmp(eventData.NewValue.String, 'On')
                    filterDataFiltered4.Visible = 'On';
                else
                    filterDataFiltered4.Visible = 'Off';
                end
          case '5'
                if strcmp(eventData.NewValue.String, 'On')
                    filterDataFiltered5.Visible = 'On';
                else
                    filterDataFiltered5.Visible = 'Off';
                end
        end
    end

    function filterChangeFocus(source, eventData)
        filterVariableFocus = source.Tag;
        
        switch filterVariableFocus
            case '0'
                c1G0.Value = 1;
                c1G1.Value = 0;
                c1G2.Value = 0;
                c1G3.Value = 0;
                c1G4.Value = 0;
                c1G5.Value = 0;
            case '1'
                c1G1.Value = 1;
                c1G0.Value = 0;
                c1G2.Value = 0;
                c1G3.Value = 0;
                c1G4.Value = 0;
                c1G5.Value = 0;
            case '2'
                c1G2.Value = 1;
                c1G0.Value = 0;
                c1G1.Value = 0;
                c1G3.Value = 0;
                c1G4.Value = 0;
                c1G5.Value = 0;
            case '3'
                c1G3.Value = 1;
                c1G0.Value = 0;
                c1G1.Value = 0;
                c1G2.Value = 0;
                c1G4.Value = 0;
                c1G5.Value = 0;
            case '4'
                c1G4.Value = 1;
                c1G0.Value = 0;
                c1G1.Value = 0;
                c1G2.Value = 0;
                c1G3.Value = 0;
                c1G5.Value = 0;
            case '5'
                c1G5.Value = 1;
                c1G0.Value = 0;
                c1G1.Value = 0;
                c1G2.Value = 0;
                c1G3.Value = 0;
                c1G4.Value = 0;
        end         
    end

    function modifyFilter(source, eventData)
        if ~strcmp(eventData.Key, 'return')
            return;
        end
        
        switch source.Tag
            case 'Fpass'
                Fpass = str2num(source.String)*2*(1/fs);
            case 'Fstop'
                Fstop = str2num(source.String)*2*(1/fs);
            case 'Ap'
                Ap = str2num(source.String);
            case 'Ast'
                Ast = str2num(source.String);
        end

        if Fpass ~= 0 && Fstop ~= 0 && Ap ~= 0 && Ast ~= 0
            dF = designfilt('lowpassiir', 'PassbandFrequency', Fpass, ...
               'StopbandFrequency', Fstop, 'PassbandRipple', Ap, ...
               'StopbandAttenuation', Ast, 'DesignMethod', 'butter' ...
               );
           
               F = filtfilt(dF,filterVariable);
                
               switch filterVariableFocus
                   case '1'
                       filterDataFiltered1.XData = t;
                       filterDataFiltered1.YData = F;
                   case '2'
                       filterDataFiltered2.XData = t;
                       filterDataFiltered2.YData = F;
                   case '3'
                       filterDataFiltered3.XData = t;
                       filterDataFiltered3.YData = F;
                   case '4'
                       filterDataFiltered4.XData = t;
                       filterDataFiltered4.YData = F;
                   case '5'
                       filterDataFiltered5.XData = t;
                       filterDataFiltered5.YData = F;
               end
            end
    end
   
    function saveData(source, eventData)
        switch filterVariableFocus
            case '1'
                dataToSave = filterDataFiltered1.YData;
            case '2'
                dataToSave = filterDataFiltered2.YData;
            case '3'
                dataToSave = filterDataFiltered3.YData;
            case '4'
                dataToSave = filterDataFiltered4.YData;
            case '5'
                dataToSave = filterDataFiltered5.YData;
        end
        
        saveFilteredData(filename, sensorNames{filterVariableKey}, dataToSave', [Fpass Fstop Ap Ast])
    end

     function clearData(source, eventData)
         delete(filterGUIFFTFig);
         delete(filterGUIFig);
         clear;
     end
end