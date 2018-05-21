function [ flag ] = superIsField( obj, checkField )
%superIsField Structure-type independant isfield() function for top level of a structure.
%   Maybe add recursion?

	if sum(strcmp(fieldnames(obj), checkField)) == 1
        flag = true();
    else
        flag = false();
    end
end

