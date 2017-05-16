if ProcessStrainProfiles == true
    %Calculate lines using linear regression.
    if ProcessShearTab == '2' || ProcessShearTab == '4'
        yLocation   = [[1; 1; 1; 1] yGaugeLocations(1:4)];
        yLocation2  = [[1; 1; 1; 1; 1] yGaugeLocations(1:5)];
        gauges      = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3)), offset(sg(:,4))];
        gauges2     = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3)), offset(sg(:,4)), offset(sg(:,5))];
    else
        yLocation   = [[1; 1; 1] yGaugeLocations(1:3)];
        yLocation2  = [[1; 1; 1; 1] yGaugeLocations(1:4)];
        gauges      = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3))];
        gauges2     = [offset(sg(:,1)), offset(sg(:,2)), offset(sg(:,3)), offset(sg(:,4))];
    end

    %Total strain profile w/o BFFD
    strainRegression = procStrainProfiles(yLocation,gauges);
    
    %Total strain profile w/ BFFD
    strainRegression = [strainRegression procStrainProfiles(yLocation2,gauges2)];
    
    disp('Strain profiles calculated. Appending data to file and removing garbage');
    clearvars yLocation yLocation2 gauges gauges2;
end