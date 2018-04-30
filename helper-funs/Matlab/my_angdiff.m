function [ a, b, c ] = my_angdiff( deg1,deg2 )
%MY_ANGDIFF takes two angles in degree and outputs their difference
%
%  [ a, b, c ] = my_angdiff( deg1,deg2 )
%
% deg1 & deg2 can be two real numbers or same-sized vectors.
% Output 'a' is a vector with the absolute difference between two degrees.
% 'b' shows whether deg2 was counterclockwise (-1) or clockwise (1) rotated
% in relation to the target.
% Output 'c' combines this information.
%
% wanja moessing, moessing@wwu.de
v1 = deg2rad(deg1);
v2 = deg2rad(deg2);

v1x = cos(v1);
v1y = sin(v1);

v2x = cos(v2);
v2y = sin(v2);

for i = 1:length(v1)
    a(i) = acos([v1x(i) v1y(i)]*[v2x(i) v2y(i)]');
end

a = rad2deg(a);

% optional output argument 2
if nargout>1
    for i = 1:length(a)
        if mod(deg1(i)-deg2(i), 360) < 180
            b(i) = -1;
        else
            b(i) = 1;
        end
    end
end

%optional output 3
if nargout > 2
    c = a.*b;
end
end

