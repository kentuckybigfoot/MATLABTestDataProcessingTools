%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get (x3,y3) coords of vertex C of wire pot triangles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%WP G1 Top
coordAngles(:,1) = pi - (atan2((WPPos(13,2)-WPPos(3,2)),WPPos(3,1)-WPPos(13,1)) + m.wpAngles(:,14));
x3Loc(:,1) = -1.*m.wp(:,12).*cos(coordAngles(:,1));
x3Glo(:,1) = x3Loc(:,1) + WPPos(13,1);

y3Loc(:,1) = m.wp(:,12).*sin(coordAngles(:,1));
y3Glo(:,1) = WPPos(13,2)-y3Loc(:,1);

%WP G2 Top
coordAngles(:,2) = atan2((WPPos(4,2) - WPPos(14,2)),(WPPos(4,1) - WPPos(14,1))) + m.wpAngles(:,16);
x3Loc(:,2) = m.wp(:,13).*cos(coordAngles(:,2));
x3Glo(:,2) = x3Loc(:,2) + WPPos(14,1);

y3Loc(:,2) = (m.wp(:,13).*sin(coordAngles(:,2)));
y3Glo(:,2) = WPPos(14,2) + y3Loc(:,2);

%WP G1 Bottom
coordAngles(:,3) = pi - (atan2((WPPos(1,2)-WPPos(7,2)),WPPos(7,1)-WPPos(1,1)) + m.wpAngles(:,2));
x3Loc(:,3) = -1.*m.wp(:,1).*cos(coordAngles(:,3));
x3Glo(:,3) =  x3Loc(:,3) + WPPos(1,1);

y3Loc(:,3) = m.wp(:,1).*sin(coordAngles(:,3));
y3Glo(:,3) = WPPos(1,2)-y3Loc(:,3);

%WP G2 Bottom
coordAngles(:,4) = atan2((WPPos(8,2) - WPPos(2,2)),(WPPos(8,1) - WPPos(2,1))) + m.wpAngles(:,4);
x3Loc(:,4) = m.wp(:,2).*cos(coordAngles(:,4));
x3Glo(:,4) = x3Loc(:,4) + WPPos(2,1);

y3Loc(:,4) = (m.wp(:,2).*sin(coordAngles(:,4)));
y3Glo(:,4) = WPPos(2,2) + y3Loc(:,4);

%WP G5 at Top of Column (Global Positioning)
%Using WP5-1
x3Loc(:,5) = m.wp(:,9).*sin((pi/2) - m.wpAngles(:,10));
x3Glo(:,5) = WPPos(9,1) + x3Loc(:,5);

y3Loc(:,5) = m.wp(:,9).*cos((pi/2) - m.wpAngles(:,10));
y3Glo(:,5) = WPPos(9,2) + y3Loc(:,5);

%Using WP5-2
x3Loc(:,6) = m.wp(:,14).*sin((pi/2) - m.wpAngles(:,11));
x3Glo(:,6) = WPPos(10,1) + x3Loc(:,6);

y3Loc(:,6) = m.wp(:,14).*cos((pi/2) - m.wpAngles(:,11));
y3Glo(:,6) = WPPos(10,2) + y3Loc(:,6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get (x4,y4) coords middle of line c
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Don't need a local since it would just be half the length of the line
%C which we calculate in the D* variables.

%WP G1 Top
x4Glo(:,1) = (WPPos(7,1) + WPPos(1,1))/2;
y4Glo(:,1) = (WPPos(7,2) + WPPos(1,2))/2;

%WP G1 Bottom
x4Glo(:,2) = (WPPos(3,1) + WPPos(13,1))/2;
y4Glo(:,2) = (WPPos(3,2) + WPPos(13,2))/2;

%WP G2 Top
x4Glo(:,3) = (WPPos(8,1) + WPPos(2,1))/2;
y4Glo(:,3) = (WPPos(8,2) + WPPos(2,2))/2;

%WP G2 Bottom
x4Glo(:,4) = (WPPos(4,1) + WPPos(14,1))/2;
y4Glo(:,4) = (WPPos(4,2) + WPPos(14,2))/2;