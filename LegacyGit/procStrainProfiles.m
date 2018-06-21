function [ strainRegression ] = procStrainProfiles( xLocation, gauges )
%strainRegression - Function to take strain gauge data and fit a trend line
%using linear regression.
%   Takes the gauge locations and the gauge data at those locations and
%   uses linear regression to create a linear line of best-fit. Outputs the
%   data as follows:
%   strainRegression(:,1) = y-intercept of original strain profile
%   strainRegression(:,2) = slope of original strain profile
%   strainRegression(:,3) = R2 (level of fit) of original strain profile
%   strainRegression(:,4) = y-intercept of bending strain profile
%   strainRegression(:,5) = slope of bending strain profile
%   strainRegression(:,6) = R2 (level of fit) of bending strain profile
%   strainRegression(:,7) = x-intercept of original strain profile. is
%                           essentially the axial strain component of the 
%                           strain profile
    
    strainRegression = zeros(size(gauges,1),7);

    for i = 1:1:size(gauges,1)
        if size(gauges,2) == 3
            yStrain1    = (10^-6)*[gauges(i,1); gauges(i,2); gauges(i,3)];
        elseif size(gauges,2) == 4
            yStrain1    = (10^-6)*[gauges(i,1); gauges(i,2); gauges(i,3); gauges(i,4)];
        else
            yStrain1    = (10^-6)*[gauges(i,1); gauges(i,2); gauges(i,3); gauges(i,4); gauges(i,5)];
        end

        %Original stress and strain profiles with no modification.
        regPre1     = xLocation\yStrain1;
        strainR21   = 1-(sum((yStrain1 - xLocation*regPre1).^2)/sum((yStrain1 - mean(yStrain1)).^2));

        strainRegression(i,1:3) = [regPre1(1,1) regPre1(2,1) strainR21];


        %Strain due to bending.
        %The x-intercept of the unmodified strain profile equates to being
        %the axial strain component of the strain profile. By subtracting
        %this value from the unmodified strain profiles the bending strain
        %profile is obtained.

        xIntercept = -strainRegression(i,1)/strainRegression(i,2);

        if size(gauges,2) == 3
            yStrain2    = (10^-6)*[gauges(i,1); gauges(i,2); gauges(i,3)] - strainRegression(i,2);
        elseif size(gauges,2) == 4
            yStrain2    = (10^-6)*[gauges(i,1); gauges(i,2); gauges(i,3); gauges(i,4)] - strainRegression(i,2);
        else
            yStrain2    = (10^-6)*[gauges(i,1); gauges(i,2); gauges(i,3); gauges(i,4); gauges(i,5)] - strainRegression(i,2);
        end

        regPre2     = xLocation\yStrain2;
        strainR22   = 1-(sum((yStrain2 - xLocation*regPre2).^2)/sum((yStrain2 - mean(yStrain2)).^2));
        
        xIntercept2 = -regPre2(1,1)/regPre2(2,1);

        strainRegression(i,4:7) = [regPre2(1,1) regPre2(2,1) strainR22 xIntercept];

    end
end

