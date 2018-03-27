%Array to hold repmap'd length of line c on the triangles
lengthOfWPRecord = size(m, 'wp11');

dist = cat(2, repmat(distBetweenWPs(1), lengthOfWPRecord(1), 1), ...
              repmat(distBetweenWPs(2), lengthOfWPRecord(1), 1), ...
              repmat(distBetweenWPs(3), lengthOfWPRecord(1), 1), ...
              repmat(distBetweenWPs(4), lengthOfWPRecord(1), 1), ...
              repmat(distBetweenWPs(5), lengthOfWPRecord(1), 1), ...
              repmat(distBetweenWPs(6), lengthOfWPRecord(1), 1) ...
           );

%Define WP Groups in a, b, and c order
g1 = [m.wp(:,7) m.wp(:,1) dist(:,1)];
g2 = [m.wp(:,2) m.wp(:,8) dist(:,2)];
g3 = [m.wp(:,5) m.wp(:,6) dist(:,3)];
g4 = [m.wp(:,14) m.wp(:,9) dist(:,4)];
g5 = [m.wp(:,3) m.wp(:,12) dist(:,5)];
g6 = [m.wp(:,13) m.wp(:,4) dist(:,6)];

%Calculate WP triangle areas
wpArea = cat(2, heronsFormula(g1), heronsFormula(g2), heronsFormula(g3), ...
                heronsFormula(g4), heronsFormula(g5), heronsFormula(g6) ...
            );

%Calc distance from vertex A to point of the perpendicular base to apex
%{
d1 = (-1.*(g1(:,1).^2) +  g1(:,2).^2 + g1(:,3).^2)./(2.*g1(:,3));
d2 = (-1.*(g2(:,1).^2) +  g2(:,2).^2 + g2(:,3).^2)./(2.*g2(:,3));
d3 = (-1.*(g3(:,1).^2) +  g3(:,2).^2 + g3(:,3).^2)./(2.*g3(:,3));
d4 = (-1.*(g4(:,1).^2) +  g4(:,2).^2 + g4(:,3).^2)./(2.*g4(:,3));
d5 = (-1.*(g5(:,1).^2) +  g5(:,2).^2 + g5(:,3).^2)./(2.*g5(:,3));
d6 = (-1.*(g6(:,1).^2) +  g6(:,2).^2 + g6(:,3).^2)./(2.*g6(:,3));

wpd = cat(2, d1, d2, d3, d4, d5, d6);
%}

%Calculate WP triangle heights using area
wpHeight = cat(2, (2.*(wpArea(:,1)./dist(:,1))),  ...
                  (2.*(wpArea(:,2)./dist(:,2))),  ...
                  (2.*(wpArea(:,3)./dist(:,3))),  ...
                  (2.*(wpArea(:,4)./dist(:,4))),  ...
                  (2.*(wpArea(:,5)./dist(:,5))),  ...
                  (2.*(wpArea(:,6)./dist(:,6))) ...
              );

%Calculate WP triangle heights using the Pythagorean theorem since we
%know the length of the perpendicular from the base to the apex (d).
%{
wpHeight2 = cat(2, sqrt(g1(:,2).^2 - wpd(:,1).^2), sqrt(g2(:,2).^2 - wpd(:,2).^2), ...
                   sqrt(g3(:,2).^2 - wpd(:,3).^2), sqrt(g4(:,2).^2 - wpd(:,4).^2), ...
                   sqrt(g5(:,2).^2 - wpd(:,5).^2), sqrt(g6(:,2).^2 - wpd(:,6).^2) ...
               );
%}

%Potential future additions:
% - Calculate Altitudes
% - Median
% - Angle bisector

%clearvars dist g1 g2 g3 g4 g5 g6 wpArea d1 d2 d3 d4 d5 d6 wpd wpHeight wpHeight2