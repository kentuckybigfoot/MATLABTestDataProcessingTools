function [  ] = smartPlot( x, y, plotName, plotXlabel, plotYlabel, varargin)
%smartPlot Power-user plot function to spare repetitive code
%   Specify x and y as either a variable or array of variables. Required
%   for operation is a plot title, xlabel title, and ylabel title. Can plot
%   multiple y values against a single x value. Accepts the following
%   additional commands:
%
%   - 'visible' - Turns off the visibility of the plot/figure
%   - 'grid'    - Adds major and minor grids to plot
%   - 'legend'  - Adds legend to the graph is posistion that covers least
%                 amount of data. Parameter immedietly following 'legend'
%                 should be the legend contents.
%   - 'ticks'   - Removes scientific notation from axis but breaks
%                 automatic tick mark labelling when zooming/panning. see
%                 http://goo.gl/1w2tkf for more information.
%   - 'save'    - Saves plot in PNG and SVG file format. Parameter
%                 immedietly following the 'save' parameter should be the 
%                 file name.
%   - 'details' - Displays completion message when smartPlot fxn finishes.

%Pick up naming information without cluttering up fxn parameters
global ProcessRealName
global ProcessCodeName

numArg = nargin;
legendOn = false;
savePlot = false;
savePlotName = '';
showDetails = false;

if numArg < 5
    disp('Not enough input variables');
    return
end

%Most commonly plotting against time so this replaces having to type a
%variable for time when plotting multiple things on one figure.
sizex = size(x);

if sizex(2) < size(y,2) && sizex(2) == 1
    x = repmat(x, 1, sizex(2));
end

h = figure();
plot(x,y);
title({ProcessRealName,plotName});
xlabel(plotXlabel);
ylabel(plotYlabel);

if nargin > 5
    for r = 1:1:size(varargin,2)
        
        if savePlot == true && r == (savePlotr + 1) || legendOn == true && r == (legendr + 1)
            continue %So we don't try and process the filename as a param
        end
        
        switch varargin{r}
            case 'visible'
                h.Visible = 'off';
            case 'grid'
                grid on
                grid minor
            case 'legend'
                legendOn = true;
                legendr = r;
                legend(varargin{r+1}, 'Location', 'best');
            case 'ticks'
                set(gca,'XTickLabel',num2str(get(gca,'XTick').'))
                set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
            case 'save'
                %Make plot as large as monitor so as to not save a tiny
                %plot
                h.Units = 'normalized';
                h.Position = [0,0,1,1];
                %Save flags
                savePlot     = true;
                savePlotName = varargin{r+1};
                savePlotr    = r;
            case 'details'
                showDetails = true;
            otherwise
                disp(sprintf('Unknown option %s',varargin{r}));
        end
    end
end

%Push saving till the end incase save is called before other options in
%function. This prevents plot from saving before all requested features are
%present
if savePlot == true
    saveas(gcf, fullfile('..\',ProcessCodeName,savePlotName), 'png')
    saveas(gcf, fullfile('..\',ProcessCodeName,savePlotName), 'svg')
end

%Status function. Saving a plot can take some time therefore it's good to
%have some information on when the save is complete.
if showDetails == true
    disp(sprintf('%s sucessfully expedited', plotName));
end

end

