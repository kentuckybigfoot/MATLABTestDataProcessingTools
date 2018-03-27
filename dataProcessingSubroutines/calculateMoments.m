%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Moments calculated using LC Data %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sizeOfLCRecord = size(m,'LC1');
m.moment(sizeOfLCRecord(1),2) = 0;

%Dist from center of LC G1 (distG1) and LC G2 (distG2) to column face
switch ProcessShearTab
    case 1
        distG1 = 29.6875;
        distG2 = 29.4375;
    case 2
        %Use caution
        distG1 = 29.0;
        distG2 = 29.0;
    case 3
        distG1 = 29.25;
        distG2 = 29.0;
    case 4
        distG1 = 28.9375;
        distG2 = 29.125;
    otherwise
        error('Unable to determine connection in data record.')
end

%Unadjusted due to rotation. From roller to column flange
m.moment(:,1) = (m.lc(:,7)*distG2) - (m.lc(:,6)*distG1);

%Adjust due to rotation changing distance from roller to col. face
%Method 1: Using average from linear potentiometers.
%moment(:,7) = lc(:,7)*distG2 - lc(:,6)*distG1;
%Method 2: Using beam rotation from wire-pot group 3.
x1 = mean([2*WPPos(7,2).*sin((m.beamRotation(:,3)/10)/2) 2*WPPos(3,2).*sin((m.beamRotation(:,3)/10)/2)],2);
x2 = mean([2*WPPos(8,2).*sin((m.beamRotation(:,3)/10)/2) 2*WPPos(4,2).*sin((m.beamRotation(:,3)/10)/2)],2);
m.moment(:,2) = m.lc(:,7).*(distG2-x2) - m.lc(:,6).*(distG1-x1);

%Need to implement. Will require measuring distance from center of
%LCs to column. Will also have to take into count translation of
%the beam/column.

%{
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
        %moment(:,1) = force(:,1)*yGaugeLocations(1) + force(:,2)*yGaugeLocations(2);
        %moment(:,2) = force(:,3)*abs(yGaugeLocations(3)) + force(:,4)*abs(yGaugeLocations(4));
        %moment(:,3) = moment(:,1) + moment(:,2);
        
        %Including BFFD
        %moment(:,4) = force(:,5)*abs(yGaugeLocations(5));
        %moment(:,5) = moment(:,3) + moment(:,4);
        
        %%% Moment at COR (COR calculated using strain gauges) %%%
        
        %Not Implented yet. May not be needed due to small change in COR.
        %An alternative would be to do moment at center of force
        %distribution.
        
        %Moment at center of ST calculated using SG regression data and
        %intergrating over area.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
     %}   
   %{     
        
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
        %}

clearvars gaugeLength gaugeWidth stMidHeight x topLength botLength strainTop strainTop1 ...
          strainBot strainBot1 elongationTop elongationTop1 elongationBot elongationBot1 x1 x2