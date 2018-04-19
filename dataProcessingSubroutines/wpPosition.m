%wpPosition Provides wirepot positions based on filename
%   With the change in position of wire-pots and other components between
%   testing configurations it is necessary to know what file is being
%   loaded in order to provide the correct position of sensors for
%   calculations.
%
%    The very end where the pivot rests serves as reference for all
%    measurements. All measurements are assumed to start at the extreme
%    end of the column below the pivot point in the center of the web.
%    Dimensions are given in (x,y)and represent the center of the hook at
%    the end of the wire. Dimensions for the wire pots can be found in
%    Fig. 2 of page 68 (WDS-...-P60-CR-P) of
%    http://www.micro-epsilon.com/download/manuals/man--wireSENSOR-P60-P96-P115--de-en.pdf
%
%   Order:
%       WPPos(1,:)  = wp11Pos
%       WPPos(2,:)  = wp12Pos
%       WPPos(3,:)  = wp21Pos
%       WPPos(4,:)  = wp22Pos
%       WPPos(5,:)  = wp31Pos
%       WPPos(6,:)  = wp32Pos
%   	WPPos(7,:)  = wp41Pos
%       WPPos(8,:)  = wp42Pos
%       WPPos(9,:)  = wp51Pos
%       WPPos(10,:) = wp52Pos
%       WPPos(11,:) = wp61Pos
%       WPPos(12,:) = wp62Pos
%       WPPos(13,:) = wp71Pos
%       WPPos(14,:) = wp72Pos

%Actual order of shear tab tests: 2, 1, 4, and 3.
switch ProcessShearTab
    case 1
        WPPos(1,:) = [13.8125+0.39 (48.5+2.175+28.4375)-(5.07-2.71654)];
        WPPos(2,:) = [13.8125+0.39 48.5+2.175+(5.07-2.71654)];
        WPPos(3,:) = [0.125+(5.07-2.71654) 48.25+9.5+13.21875+0.39];  %Same as WP4-1 in theory
        WPPos(4,:) = [0.125+(5.07-2.71654) 48.25+9.5+0.39];           %Same as WP4-2 in theory
        WPPos(5,:) = [0 0];
        WPPos(6,:) = [0 0];
        WPPos(7,:) = [0.125+(5.07-2.71654) 48.25+9.5+13.21875+0.39];
        WPPos(8,:) = [0.125+(5.07-2.71654) 48.25+9.5+0.39];
        WPPos(9,:) = [(3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
        WPPos(10,:) = [(3.9375+3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
        WPPos(11,:) = [0 0];
        WPPos(12,:) = [0 0];
        WPPos(13,:) = [13.8125+0.39 (48.5+2.175+28.4375)-(5.07-2.71654)]; %Same as WP1-1 in theory
        WPPos(14,:) = [13.8125+0.39 48.5+2.175+(5.07-2.71654)];           %Same as WP1-2 in theory
    case 2
        %x = dist to outside of op flange, y = dist to outside of wp12 angle to
        % nearest face of wp11 angle minus the block, WP, and hook.
        WPPos(1,:) = [13.875+0.39 (21.1875+34.75)-(0.175+(5.07-2.71654))];
        %x = dist to outside op flange, y = dist from edge + angle + plate + wp-hook
        WPPos(2,:) = [(13.8125+0.39) ((21+(3/16))+2+0.175+(5.07-2.71654))];
        WPPos(3,:) = [(0.125+(5.07-2.71654)) (32.3125+2+13.875+0.39)];  %Same as WP4-1 in theory
        WPPos(4,:) = [(0.125+(5.07-2.71654)) (32.3125+0.39)];           %Same as WP4-2 in theory
        WPPos(5,:) = [0 0];
        WPPos(6,:) = [0 0];
        %x = block + unit - hook, y = dist to wp42 + angle + dist b/t 41 & 42 + hole
        WPPos(7,:) = [(0.125+(5.07-2.71654)) (32.3125+2+13.875+0.39)];
        %x = block + unit - hook, y = dist from edge to unit + hole.
        WPPos(8,:) = [(0.125+(5.07-2.71654)) (32.3125+0.39)];
        WPPos(9,:) = [0 0];
        WPPos(10,:) = [0 0];
        WPPos(11,:) = [0 0];
        WPPos(12,:) = [0 0];
        WPPos(13,:) = [13.875+0.39 (21.1875+2+34.75)-(0.175+(5.07-2.71654))]; %Same as WP1-1 in theory
        WPPos(14,:) = [(13.8125+0.39) ((21+(3/16))+2+0.175+(5.07-2.71654))];  %Same as WP1-2 in theory
    case 3
        WPPos(1,:) = [-0.39 (48.25+2.175+29.625)-((5.07-2.71654)+0.125)]; %
        WPPos(2,:) = [-0.39 48.25+2.175+(5.07-2.71654)]; %
        WPPos(3,:) = [13.875-(0.125+(5.07-2.71654)) 57+14.875+0.39];  %Same as WP4-1 in theory
        WPPos(4,:) = [13.875-(0.125+(5.07-2.71654)) 57+0.39];           %Same as WP4-2 in theory
        WPPos(5,:) = [0 0];
        WPPos(6,:) = [0 0];
        WPPos(7,:) = [13.875-(0.125+(5.07-2.71654)) 57+14.875+0.39]; %
        WPPos(8,:) = [13.875-(0.125+(5.07-2.71654)) 57+0.39]; %
        WPPos(9,:) = [(3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
        WPPos(10,:) = [(3.9375+3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
        WPPos(11,:) = [0 0];
        WPPos(12,:) = [0 0];
        WPPos(13,:) = [-0.39 (48.25+2.175+29.625)-((5.07-2.71654)+0.125)]; %Same as WP1-1 in theory
        WPPos(14,:) = [-0.39 48.25+2.175+(5.07-2.71654)];         %Same as WP1-2 in theory
    case 4
        WPPos(1,:) = [0.39 (21.25+2.175+34.75)-(5.07-2.71654)]; %
        WPPos(2,:) = [0.39 21.25+2.175+(5.07-2.71654)]; %
        WPPos(3,:) = [13.875+0.125+(5.07-2.71654) 32.125+16.375+0.39];  %Same as WP4-1 in theory
        WPPos(4,:) = [13.875+0.125+(5.07-2.71654) 32.125+0.39];           %Same as WP4-2 in theory
        WPPos(5,:) = [0 0];
        WPPos(6,:) = [0 0];
        WPPos(7,:) = [13.875+0.125+(5.07-2.71654) 32.125+16.375+0.39]; %
        WPPos(8,:) = [13.875+0.125+(5.07-2.71654) 32.125+0.39]; %
        WPPos(9,:) = [(3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
        WPPos(10,:) = [(3.9375+3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
        WPPos(11,:) = [0 0];
        WPPos(12,:) = [0 0];
        WPPos(13,:) = [0.39 (21.25+2.175+34.75)-(5.07-2.71654)]; %Same as WP1-1 in theory
        WPPos(14,:) = [0.39 21.25+2.175+(5.07-2.71654)];           %Same as WP1-2 in theory
end