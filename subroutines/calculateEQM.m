if ProcessEQM == true
    x1 = 48;
    x2 = 36;
    x3 = (29+(11/16));
    x4 = (29+(7/16));
    
    eqm(:,1) = (lc(:,6)*x3 - lc(:,7)*x4)/(x1 + x2);
    eqm(:,2) = lc(:,6) - lc(:,7);
    eqm(:,3) = -lc(:,5);
    eqm(:,4) = lc(:,5)*x1 - lc(:,6)*x3 + lc(:,7)*x4 - eqm(:,3)*x2;
    eqm(:,5) = -lc(:,5)*x1 + lc(:,6)*x3 - lc(:,7)*x4 + eqm(:,3)*x2;
end