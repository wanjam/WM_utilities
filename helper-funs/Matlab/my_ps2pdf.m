function my_ps2pdf(psfile, remove_original)
%MY_PS2PDF tries to find ps2pdf binary and the converts postscript to pdf
%
% input:
%       - psfile: string with filename. should end on .ps
%       - remove_original: bool, default 0
%
% the ps2pdf binary is often shipped with TeX or ghostscript installations.
%
% currently Linux and Windows only.
%
% Wanja Moessing, April 2019, moessing@wwu.de

if ispc
    binary = 'ps2pdf.exe';
    searchfolder = 'C:/Program Files*/';
    lookup = 'where ';
elseif isunix
    binary = 'ps2pdf';
    searchfolder = '/usr/bin';
    lookup = 'which ';
end

[res, ~] = system([lookup, binary]);
if res == 0
    ps2pdf = 'ps2pdf ';
else
    disp('ps2pdf does not seem to be on your PATH. Will try to find one in program folder. This takes a moment...');
    content = dir([searchfolder, '**/ps2pdf']);
    if sum(idx) >= 1
        % just use the first one
        ps2pdf = ['"', content(1).folder, filesep, content(1).name, '" '];
    else
        warning('Couldn''t find ps2pdf binary on this machine. Not converting to PDF');
        return
    end
end

system([ps2pdf, '" -dEmbedAllFonts=true ', psfile, '"']);

if nargin < 2
    remove_original = 0;
end

if remove_original
    delete(psfile);
end

end
