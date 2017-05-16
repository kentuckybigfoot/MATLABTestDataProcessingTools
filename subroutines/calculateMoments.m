if ProcessMoments == true
    %Generate strain gauge width increments
    strainIncrement            = (stMidHeight:-gaugeWidth:0).';
    strainIncrement(end+1,1)   = 0;
    strainIncrement(end:end+(length(strainIncrement)-1),1) = -flipud(strainIncrement).';
    
    %Sign convention followed is standard counter-clockwise positive,
    %clockwise negative. If this were a beam, positive on the right side
    %would be counter-clockwise with shear force up while negative on the
    %left being clockwise with shear force down.
    
    if ProcessShearTab == '2' || ProcessShearTab == '4'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Moments calculated using SG data %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%% Moment at center of the shear tab %%%
        
        %Not including BFFD
        moment(:,1) = force(:,1)*yGaugeLocations(1) + force(:,2)*yGaugeLocations(2);
        moment(:,2) = force(:,3)*abs(yGaugeLocations(3)) + force(:,4)*abs(yGaugeLocations(4));
        moment(:,3) = moment(:,1) + moment(:,2);
        
        %Including BFFD
        moment(:,4) = force(:,5)*abs(yGaugeLocations(5));
        moment(:,5) = moment(:,3) + moment(:,4);
        
        %%% Moment at COR (COR calculated using strain gauges) %%%
        
        %Not Implented yet. May not be needed due to small change in COR.
        %An alternative would be to do moment at center of force
        %distribution.
        
        %Moment at center of ST calculated using SG regression data and
        %intergrating over area.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        
        
        
        %Moment integrating strain linear regression across shear table only
        momentReg(:,1) = -(2/3)*stMidHeight*modulus*(sgReg(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,2) = (2/3)*stMidHeight*modulus*(sgReg(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,3) = momentReg(:,1) + momentReg(:,2);
        
        %Bending moment integrating strain linear regression across ST only
        momentRegBend(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBend(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,2) = (2/3)*stMidHeight*modulus*(sgRegBend(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,3) = momentRegBend(:,1) + momentRegBend(:,2);
        
        %Moment integrating strain linear regression across ST and BFFD/CFFD
        momentRegBFFD(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBFFD(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,2) = (2/3)*stMidHeight*modulus*(sgRegBFFD(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,3) = momentRegBFFD(:,1) + momentRegBFFD(:,2);
        
        % Moment at centroid of strain calculated using SG regression data
        % and integrating over area. INCOMPLETE
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %Moment integrating strain linear regression across shear tab only
        momentReg(:,1) = -(2/3)*stMidHeight*modulus*(sgReg(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,2) = (2/3)*stMidHeight*modulus*(sgReg(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentReg(:,3) = momentReg(:,1) + momentReg(:,2);
        
        %Bending moment integrating strain linear regression across ST only
        momentRegBend(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBend(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,2) = (2/3)*stMidHeight*modulus*(sgRegBend(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBend(:,3) = momentRegBend(:,1) + momentRegBend(:,2);
        
        %Moment integrating strain linear regression across ST and BFFD/CFFD
        momentRegBFFD(:,1) = -(2/3)*stMidHeight*modulus*(sgRegBFFD(:,1).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,2) = (2/3)*stMidHeight*modulus*(sgRegBFFD(:,5).^2)*gaugeLength(1)*gaugeWidth(1);
        momentRegBFFD(:,3) = momentRegBFFD(:,1) + momentRegBFFD(:,2);
        
    end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Moments calculated using LC Data %%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        distG1 = 29.25; %28.9375;%(29+(11/16)); %Dist from center of LC G1 to column face
        distG2 = 29.0; %29.125;  %(29+(7/16)); %Dist from center of LC G2 to column face
        %Middle of shear tab at column flange face
        
        %Unadjusted due to rotation. From roller to column flange
        moment(:,6) = lc(:,7)*distG2 - lc(:,6)*distG1;
        
        %Adjust due to rotation changing distance from roller to col. face
        %Method 1: Using average from linear potentiometers.
        %moment(:,7) = lc(:,7)*distG2 - lc(:,6)*distG1;
        %Method 2: Using beam rotation from wire-pot group 3.
        x1 = mean([2*wp41Pos(2).*sin((beamRotation(:,3)/10)/2) 2*wp21Pos(2).*sin((beamRotation(:,3)/10)/2)],2);
        x2 = mean([2*wp42Pos(2).*sin((beamRotation(:,3)/10)/2) 2*wp22Pos(2).*sin((beamRotation(:,3)/10)/2)],2);
        moment(:,7) = lc(:,7).*(distG2-x2) - lc(:,6).*(distG1-x1);
         
        %Need to implement. Will require measuring distance from center of
        %LCs to column. Will also have to take into count translation of
        %the beam/column.

    clearvars gaugeLength gaugeWidth stMidHeight x topLength botLength strainTop strainTop1 strainBot strainBot1 elongationTop elongationTop1 elongationBot elongationBot1 x1 x2
    
end