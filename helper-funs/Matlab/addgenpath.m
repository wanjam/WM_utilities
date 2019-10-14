function addgenpath(P)
%ADDGENPATH does the same as addpath(genpath(... ignoring .git & .Rproj
P = genpath(P);
P = strsplit(P, ';');
P = P(~contains(P, '.git'));
P = P(~contains(P, '.Rproj'));
P = sprintf('%s;', P{1:end-1});
addpath(P);
end

