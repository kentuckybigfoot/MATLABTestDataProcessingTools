if ProcessWPAngles == true
    
    [wpAngles, wpAnglesDeg] = procWPAngles(wp(:,:), [D1, D2, D3, D4, D5, D6]);
    
    c1 = find(round(wpAngles(:,1) + wpAngles(:,2) + wpAngles(:,3),12) ~= round(pi,12));
    c2 = find(round(wpAngles(:,4) + wpAngles(:,5) + wpAngles(:,6),12) ~= round(pi,12));
    c3 = find(round(wpAngles(:,7) + wpAngles(:,8) + wpAngles(:,9),12) ~= round(pi,12));
    c4 = find(round(wpAngles(:,10) + wpAngles(:,11) + wpAngles(:,12),12) ~= round(pi,12));
    c5 = find(round(wpAngles(:,13) + wpAngles(:,14) + wpAngles(:,15),12) ~= round(pi,12));
    c6 = find(round(wpAngles(:,16) + wpAngles(:,17) + wpAngles(:,18),12) ~= round(pi,12));
    
    if all([c1, c2, c3, c4, c5, c6]) == 0
        error('Check angles for accuracy. Unable to verify all angles equal pi');
    end

    disp('Angles using non offset data calculated successfully. Appending to file (if localAppend = true) and removing garbage.')
    clearvars c1 c2 c3 c4 c5 c6
end