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
     
list2 = {'FS Testing -ST2 - 06-13-16', 'FS Testing -ST2 - 05-16-15', ...
         };
     
if any(cell2mat(regexp(ProcessFileName,list1)))
    wp11Pos = [(13+7/8)+0.50+0.39 (8*12)-(38 + 2+ 5/16 + (5.07-2.71654))];
    wp12Pos = [(13+7/8)+0.39 (22.9375+0.1875+0.1250+(5.07-2.71654))];
    wp21Pos = [((5.07-2.71654)+0.125) (48.125+0.39)];  %Same as WP4-1 in theory
    wp22Pos = [((5.07-2.71654)+0.125) (32.1875+0.39)]; %Same as WP4-2 in theory
    wp31Pos = [0 0];
    wp32Pos = [0 0];
    wp41Pos = [((5.07-2.71654)+0.125) (48.125+0.39)];
    wp42Pos = [((5.07-2.71654)+0.125) (32.1875+0.39)];
    wp51Pos = [0 0];
    wp52Pos = [0 0];
    wp61Pos = [0 0];
    wp62Pos = [0 0];
    wp71Pos = [(13+7/8)+0.50+0.39 (8*12)-(37.75 + 5/16 + (5.07-2.71654))]; %Same as WP1-1 in theory
    wp72Pos = [(13+7/8)+0.39 (23.1875+0.1250+(5.07-2.71654))];             %Same as WP1-2 in theory
end

if any(cell2mat(regexp(ProcessFileName,list2)))
    wp11Pos = [(13+7/8)+0.50+0.39 (8*12)-(38 + 2+ 5/16 + (5.07-2.71654))];
    wp12Pos = [(13+7/8)+0.39 (22.9375+0.1875+0.1250+(5.07-2.71654))];
    wp21Pos = [((5.07-2.71654)+0.125) (48.125+0.39)];  %Same as WP4-1 in theory
    wp22Pos = [((5.07-2.71654)+0.125) (32.1875+0.39)]; %Same as WP4-2 in theory
    wp31Pos = [0 0];
    wp32Pos = [0 0];
    wp41Pos = [((5.07-2.71654)+0.125) (48.125+0.39)];
    wp42Pos = [((5.07-2.71654)+0.125) (32.1875+0.39)];
    wp51Pos = [0 0];
    wp52Pos = [0 0];
    wp61Pos = [0 0];
    wp62Pos = [0 0];
    wp71Pos = [(13+7/8)+0.50+0.39 (8*12)-(37.75 + 5/16 + (5.07-2.71654))]; %Same as WP1-1 in theory
    wp72Pos = [(13+7/8)+0.39 (23.1875+0.1250+(5.07-2.71654))];             %Same as WP1-2 in theory
end

wpPos = [wp11Pos; wp12Pos; wp21Pos; wp22Pos; wp31Pos; wp32Pos; wp41Pos; wp42Pos; wp51Pos; wp52Pos; wp61Pos; wp62Pos; wp71Pos; wp72Pos];
end

