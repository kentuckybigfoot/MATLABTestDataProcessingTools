if ProcessWPCoords == true
    %Get (x3,y3) coords of vertex C of wire pot triangles
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %WP G1 Top
    coordAngles(:,1) = pi - (atan2((wp71Pos(2)-wp21Pos(2)),wp21Pos(1)-wp71Pos(1)) + wpAngles(:,14));
    x3Loc(:,1) = -1.*wp(:,12).*cos(coordAngles(:,1));
    x3Glo(:,1) = x3Loc(:,1) + wp71Pos(1);
    
    y3Loc(:,1) = wp(:,12).*sin(coordAngles(:,1));
    y3Glo(:,1) = wp71Pos(2)-y3Loc(:,1);
    
    %WP G2 Top
    coordAngles(:,2) = atan2((wp22Pos(2) - wp72Pos(2)),(wp22Pos(1) - wp72Pos(1))) + wpAngles(:,16);
    x3Loc(:,2) = wp(:,13).*cos(coordAngles(:,2));
    x3Glo(:,2) = x3Loc(:,2) + wp72Pos(1);
    
    y3Loc(:,2) = (wp(:,13).*sin(coordAngles(:,2)));
    y3Glo(:,2) = wp72Pos(2) + y3Loc(:,2);
    
    %WP G1 Bottom
    coordAngles(:,3) = pi - (atan2((wp11Pos(2)-wp41Pos(2)),wp41Pos(1)-wp11Pos(1)) + wpAngles(:,2));
    x3Loc(:,3) = -1.*wp(:,1).*cos(coordAngles(:,3));
    x3Glo(:,3) =  x3Loc(:,3) + wp11Pos(1);
    
    y3Loc(:,3) = wp(:,1).*sin(coordAngles(:,3));
    y3Glo(:,3) = wp11Pos(2)-y3Loc(:,3);
    
    %WP G2 Bottom
    coordAngles(:,4) = atan2((wp42Pos(2) - wp12Pos(2)),(wp42Pos(1) - wp12Pos(1))) + wpAngles(:,4);
    x3Loc(:,4) = wp(:,2).*cos(coordAngles(:,4));
    x3Glo(:,4) = x3Loc(:,4) + wp12Pos(1);
    
    y3Loc(:,4) = (wp(:,2).*sin(coordAngles(:,4)));
    y3Glo(:,4) = wp12Pos(2) + y3Loc(:,4);
    
    %WP G5 at Top of Column (Global Positioning)
    %Using WP5-1
    x3Loc(:,5) = wp(:,9).*sin((pi/2) - wpAngles(:,10));
    x3Glo(:,5) = wp51Pos(1) + x3Loc(:,5);
    
    y3Loc(:,5) = wp(:,9).*cos((pi/2) - wpAngles(:,10));
    y3Glo(:,5) = wp51Pos(2) + y3Loc(:,5);
    
    %Using WP5-2
    x3Loc(:,6) = wp(:,14).*sin((pi/2) - wpAngles(:,11));
    x3Glo(:,6) = wp52Pos(1) + x3Loc(:,6);
    
    y3Loc(:,6) = wp(:,14).*cos((pi/2) - wpAngles(:,11));
    y3Glo(:,6) = wp52Pos(2) + y3Loc(:,6);
    
    %Get (x4,y4) coords middle of line c
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Don't need a local since it would just be half the length of the line
    %C which we calculate in the D* variables.
    
    %WP G1 Top
    x4Glo(:,1) = (wp41Pos(1) + wp11Pos(1))/2;
    y4Glo(:,1) = (wp41Pos(2) + wp11Pos(2))/2;
    
    %WP G1 Bottom
    x4Glo(:,2) = (wp21Pos(1) + wp71Pos(1))/2;
    y4Glo(:,2) = (wp21Pos(2) + wp71Pos(2))/2;
    
    %WP G2 Top
    x4Glo(:,3) = (wp42Pos(1) + wp12Pos(1))/2;
    y4Glo(:,3) = (wp42Pos(2) + wp12Pos(2))/2;
    
    %WP G2 Bottom
    x4Glo(:,4) = (wp22Pos(1) + wp72Pos(1))/2;
    y4Glo(:,4) = (wp22Pos(2) + wp72Pos(2))/2;
end