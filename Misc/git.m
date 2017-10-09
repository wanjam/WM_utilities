function git(cmd)
%GIT simply wraps the git cmd for matlab
%
% Wanja Moessing, October 2017, moessing@wwu.de
system(sprintf('git %s', cmd));
end

