function [outIdx] = nextchange(Arr,startIdx)
%NEXTCHANGE takes an array and returns the index of the next change in value
% usage : [outIdx] = nextchange(Arr,startIdx)
% specifically, nextchange returns the index of the first value that
% differs from the value of startIdx
% Wanja Moessing, moessing@wwu.de

if nargin==1
    startIdx = 1;
end

if isnumeric(Arr)
    tmpIdx = find(Arr(startIdx:end)~=Arr(startIdx),1);
elseif iscell(Arr)
    if ischar([Arr{:}])
        tmpIdx = find(~strcmp(Arr(startIdx:end),Arr(startIdx)),1);
    end
end
outIdx = startIdx-1 + tmpIdx;

end

