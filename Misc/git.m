function git(varargin)
%GIT simply wraps the git cmd for matlab
%
% Wanja Moessing, October 2017, moessing@wwu.de
if nargin>1
    cmd = strjoin(varargin,' ');
else
    cmd = varargin{:};
end
system(sprintf('git %s', cmd));
end

