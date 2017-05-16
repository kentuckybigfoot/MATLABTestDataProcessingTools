if ProcessConfigLPs == true
    load('C:\Users\clk0032\Dropbox\Friction Connection Research\Linear Spring Potentiometer Calibration\LPCal.mat');
    
    for r = 1:1:size(p1,2)
        lpValues1(:,r) = offset(polyval(p1(:,r), lp(:,1)));
        lpValues2(:,r) = offset(polyval(p2(:,r), lp(:,2)));
        lpValues3(:,r) = offset(polyval(p3(:,r), lp(:,3)));
        if r < 4 && r ~= 2
            lpValues4(:,r) = offset(polyval(p4(:,r), lp(:,4)));
        end
    end
    
    lpValues4(:,2) = [];
    %mu = [4819.07121967553;82.6511269503711];
    %p4 = [-0.00271303197038322,-0.0265050717127049,-0.0860876554573797,-0.0693793958492654,0.162275673684280,0.324824621310463,0.204426859405091,0.347725190280539,5.34467391561030];
    p4 = [-8.14898838897599e-20;2.31385242074387e-15;-2.53901613238266e-11;1.16383850495194e-07;5.34327273544657e-05;-3.04408237969401;14004.5257169421;-28235882.0040511;22265113361.3903];
    lpValues4(:,end+1) = abs(offset(polyval(p4, lp(:,4))));
    lpValues1(:,end+1) = mean(lpValues1,2);
    lpValues2(:,end+1) = mean(lpValues2,2);
    lpValues3(:,end+1) = mean(lpValues3,2);
    lpValues4(:,end+1) = mean(lpValues4,2);
    
    lp(:,1) = lpValues1(:,end);
    lp(:,2) = lpValues2(:,end);
    lp(:,3) = lpValues3(:,end);
    lp(:,4) = lpValues4(:,end);
    lp(:,5) = (offset(lpValues1(:, end)) + offset(lpValues3(:,end)))/2;
    lp(:,6) = (offset(lpValues2(:, end)) + offset(lpValues4(:,end)))/2;
    
end