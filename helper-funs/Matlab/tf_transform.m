function [ powz ] = tf_transform(type, pow, baseline, fdim, tdim, cdim, sdim, bslAsIs, verbosity)
%TF_TRANSFORM normalizes tf-power to z, dB, div or percent-change
%   pow needs to be at least 2D (frequencybands & time)
%   By default, this function assumes that dimensions are in the following
%   order: freqband*time*channels*subjects
%       or:freqband*time*channels
%       or:freqband*time
%   If any of the above is the case, you don't need to specify any the *dim
%   arguments. These are only necessary if you're matrix is ordered in a
%   different way.
%   When a single subject is used as input, sdim can be used for trials
%   (i.e., single trial baseline).
%
%   baseline: This function is time agnostic. So baseline should be given
%   in indeces. Can be 'minmax' to us the whole time as baseline.
%
%   type can be one of: 'z', 'dB', 'div' or 'percent', 'sub'
%   if bslAsIs is 1 [default: 0]; the function does assume, that 'baseline'
%   is not indeces but data. It then simply uses this data.
%
% Wanja Moessing, moessing@wwu.de, Nov 2017

% check input arguments
if nargin < 9
    verbosity = 1;
end
if nargin < 8
    bslAsIs = 0;
end
if nargin < 7
    sdim = 4;
end
if nargin < 6
    cdim = 3;
end
if nargin < 5
    tdim = 2;
end
if nargin < 4
    fdim = 1;
end

if verbosity
    disp(['Converting data to ', type]);
end


% make sure data is in double precision
if ~isa(pow, 'double')
    pow = double(pow);
end

% check baseline
if strcmp('minmax', baseline)
    baseline = [1, size(pow, tdim)];
end

pow = permute(pow, [fdim, tdim, cdim, sdim]);
%preallocate
powz = zeros(size(pow));
if bslAsIs
    bl_pow = mean(baseline, 2);
else
    bl_pow = mean(pow(:,baseline(1):baseline(2), :, :, :, :, :, :), 2);
end
switch type
    case 'z'
        if ~bslAsIs
            bl_powA = baseline;
        else
            bl_powA = pow(:, baseline(1):baseline(2),:,:,:,:,:,:);
        end
        powz = bsxfun(@rdivide,...
            bsxfun(@minus, pow, bl_pow),...
            std(bl_powA, [], 2));
    case 'dB'
        powz = 10 * log10(bsxfun(@rdivide, pow, bl_pow));
    case 'percent'
        powz = 100 * bsxfun(@rdivide,...
            (bsxfun(@minus, pow, bl_pow)), bl_pow);
    case 'div'
        powz = bsxfun(@rdivide, pow, bl_pow);
    case 'sub'
        powz = bsxfun(@minus, pow, bl_pow);
    case 'none'
        powz = pow;
end
end