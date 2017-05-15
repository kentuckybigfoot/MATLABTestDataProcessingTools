function [ wpPos ] = wpPosition ( ProcessFileName )
%wpPosition Provides wirepot positions based on filename
%   With the change in position of wire-pots and other components between
%   testing configurations it is neccessary to know what file is being
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


list1 = {'FS Testing -ST2 - 05-09-16', 'FS Testing -ST2 - 05-16-16', ...
         'FS Testing -ST2 - 05-19-16', 'FS Testing -ST2 - 05-20-16', ...
         'FS Testing -ST2 - 05-23-16', 'FS Testing -ST2 - 05-25-16', ...
         'FS Testing -ST2 - 05-26-16', 'FS Testing -ST2 - 05-27-16', ...
         'FS Testing -ST2 - 05-31-16', 'FS Testing -ST2 - 05-06-16'};
     
list2 = {'FS Testing -ST2 - 06-13-16', 'FS Testing -ST1 - 06-15-16', ...
         'FS Testing -ST1 - 06-17-16', 'FS Testing -ST1 - 06-22-16', ...
         'FS Testing -ST1 - 06-27-16', 'FS Testing -ST1 - 07-01-16', ...
         'FS Testing -ST1 - 07-03-16', 'FS Testing -ST1 - 07-05-16', ...
         'FS Testing -ST1 - 07-07-16'};
     
list3 = {'FS Testing -ST4 - 07-12-16', 'FS Testing -ST4 - 07-14-16', ...
         'FS Testing -ST4 - 07-20-16', 'FS Testing -ST4 - 07-21-16'};
     
list4 = {'FS Testing -ST3 - 07-29-16', 'FS Testing -ST3 - 08-11-16', ...
         'FS Testing -ST3 - 08-14-16', 'FS Testing -ST3 - 08-18-16', ...
         'FS Testing -ST3 - 08-24-16', 'FS Testing -ST3 - 09-07-16', ...
         };
     
if any(cell2mat(regexp(ProcessFileName,list1)))
    %x = dist to outside of op flange, y = dist to outside of wp12 angle to
    % nearest face of wp11 angle minus the block, WP, and hook.
    wp11Pos = [13.875+0.39 (21.1875+34.75)-(0.175+(5.07-2.71654))]; 
    %x = dist to outside op flange, y = dist from edge + angle + plate + wp-hook
    wp12Pos = [(13.8125+0.39) ((21+(3/16))+2+0.175+(5.07-2.71654))];
    wp21Pos = [(0.125+(5.07-2.71654)) (32.3125+2+13.875+0.39)];  %Same as WP4-1 in theory
    wp22Pos = [(0.125+(5.07-2.71654)) (32.3125+0.39)];           %Same as WP4-2 in theory
    wp31Pos = [0 0];
    wp32Pos = [0 0];
    %x = block + unit - hook, y = dist to wp42 + angle + dist b/t 41 & 42 +
    %hole
    wp41Pos = [(0.125+(5.07-2.71654)) (32.3125+2+13.875+0.39)];
    %x = block + unit - hook, y = dist from edge to unit + hole.
    wp42Pos = [(0.125+(5.07-2.71654)) (32.3125+0.39)];
    wp51Pos = [0 0];
    wp52Pos = [0 0];
    wp61Pos = [0 0];
    wp62Pos = [0 0];
    wp71Pos = [13.875+0.39 (21.1875+2+34.75)-(0.175+(5.07-2.71654))]; %Same as WP1-1 in theory
    wp72Pos = [(13.8125+0.39) ((21+(3/16))+2+0.175+(5.07-2.71654))];  %Same as WP1-2 in theory
end

if any(cell2mat(regexp(ProcessFileName,list2)))
    wp11Pos = [13.8125+0.39 (48.5+2.175+28.4375)-(5.07-2.71654)];
    wp12Pos = [13.8125+0.39 48.5+2.175+(5.07-2.71654)];
    wp21Pos = [0.125+(5.07-2.71654) 48.25+9.5+13.21875+0.39];  %Same as WP4-1 in theory
    wp22Pos = [0.125+(5.07-2.71654) 48.25+9.5+0.39];           %Same as WP4-2 in theory
    wp31Pos = [0 0];
    wp32Pos = [0 0];
    wp41Pos = [0.125+(5.07-2.71654) 48.25+9.5+13.21875+0.39];
    wp42Pos = [0.125+(5.07-2.71654) 48.25+9.5+0.39];
    wp51Pos = [(3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
    wp52Pos = [(3.9375+3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
    wp61Pos = [0 0];
    wp62Pos = [0 0];
    wp71Pos = [13.8125+0.39 (48.5+2.175+28.4375)-(5.07-2.71654)]; %Same as WP1-1 in theory
    wp72Pos = [13.8125+0.39 48.5+2.175+(5.07-2.71654)];           %Same as WP1-2 in theory
end

if any(cell2mat(regexp(ProcessFileName,list3)))
    wp11Pos = [0.39 (21.25+2.175+34.75)-(5.07-2.71654)]; %
    wp12Pos = [0.39 21.25+2.175+(5.07-2.71654)]; %
    wp21Pos = [13.875+0.125+(5.07-2.71654) 32.125+16.375+0.39];  %Same as WP4-1 in theory
    wp22Pos = [13.875+0.125+(5.07-2.71654) 32.125+0.3];           %Same as WP4-2 in theory
    wp31Pos = [0 0];
    wp32Pos = [0 0];
    wp41Pos = [13.875+0.125+(5.07-2.71654) 32.125+16.375+0.39]; %
    wp42Pos = [13.875+0.125+(5.07-2.71654) 32.125+0.39]; %
    wp51Pos = [(3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
    wp52Pos = [(3.9375+3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
    wp61Pos = [0 0];
    wp62Pos = [0 0];
    wp71Pos = [0.39 (21.25+2.175+34.75)-(5.07-2.71654)]; %Same as WP1-1 in theory
    wp72Pos = [0.39 21.25+2.175+(5.07-2.71654)];           %Same as WP1-2 in theory
end
    
if any(cell2mat(regexp(ProcessFileName,list4)))
    wp11Pos = [-0.39 (48.25+2.175+29.625)-((5.07-2.71654)+0.125)]; %
    wp12Pos = [-0.39 48.25+2.175+(5.07-2.71654)]; %
    wp21Pos = [13.875-(0.125+(5.07-2.71654)) 57+14.875+0.39];  %Same as WP4-1 in theory
    wp22Pos = [13.875-(0.125+(5.07-2.71654)) 57+0.39];           %Same as WP4-2 in theory
    wp31Pos = [0 0];
    wp32Pos = [0 0];
    wp41Pos = [13.875-(0.125+(5.07-2.71654)) 57+14.875+0.39]; %
    wp42Pos = [13.875-(0.125+(5.07-2.71654)) 57+0.39]; %
    wp51Pos = [(3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
    wp52Pos = [(3.9375+3.0625+1.375+0.50) (48.5+2.175+28.4375+2+(14.9375-0.8125)+(5.07-2.71654))];
    wp61Pos = [0 0];
    wp62Pos = [0 0];
    wp71Pos = [-0.39 (48.25+2.175+29.625)-((5.07-2.71654)+0.125)]; %Same as WP1-1 in theory
    wp72Pos = [-0.39 48.25+2.175+(5.07-2.71654)];         %Same as WP1-2 in theory
end

wpPos = [wp11Pos; wp12Pos; wp21Pos; wp22Pos; wp31Pos; wp32Pos; wp41Pos; wp42Pos; wp51Pos; wp52Pos; wp61Pos; wp62Pos; wp71Pos; wp72Pos];
end