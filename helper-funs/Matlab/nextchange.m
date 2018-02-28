function [outIdx] = nextchange(Arr,startIdx)
%NEXTCHANGE takes an array and returns the index of the next change in value
% usage : [outIdx] = nextchange(Arr,startIdx)
% specifically, nextchange returns the index of the first value that
% differs from the value of startIdx
% in case there is no further change, it returns end+1
% Wanja Moessing, moessing@wwu.de

%  Copyright (C) 2016 Wanja Mössing
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program. If not, see <http://www.gnu.org/licenses/>.
if nargin==1
    startIdx = 1;
end

if isnumeric(Arr) || islogical(Arr)
    tmpIdx = find(Arr(startIdx:end)~=Arr(startIdx),1);
elseif iscell(Arr)
    if ischar([Arr{:}])
        tmpIdx = find(~strcmp(Arr(startIdx:end),Arr(startIdx)),1);
    end
end

if ~isempty(tmpIdx)
    outIdx = startIdx-1 + tmpIdx;
else
    outIdx = length(Arr)+1;
end
end

