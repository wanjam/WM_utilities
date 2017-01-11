function [PTBPointerID] = TwoMiceOnLinux(OnOrOff,MouseModel1, MouseModel2)
%TWOMICEONLINUX creates a 2nd pointer for a 2nd mouse
% only works on Linux, silently ignored on other systems
%
% For some reason, providing this ID to Get/SetMouse doesn't work. However,
% in our lab this function works just fine, as PTB will only use the input
% from the mouse in the cabin.
%
% Usage: call 1x at beginning TwoMiceOnLinux and when closing the
% experiment TwoMiceOnLinux(0)
%
% Input can be 1 (create 2nd pointer, default) or 0 (delete it)
%
% Optionally, you can input other mice models as strings. Check names with
% system('xinput'). We just assume both are 'Logitech USB-PS/2 Optical Mouse' 
%
% Wanja Moessing, Jan 2017, moessing@wwu.de

% make defaults
if nargin==0
    OnOrOff=1;
end
if nargin < 2
    MouseModel1 = 'Logitech USB-PS/2 Optical Mouse';
    MouseModel2 = 'Logitech USB-PS/2 Optical Mouse';
end

%only works on Linux
if isunix && OnOrOff
    % get indices of all actual mice
    [~, name, info]  = GetMouseIndices('slavePointer');
    % extract info on just the indicated mice
    ConnectedMicePointer = info(contains(name,{MouseModel1,MouseModel2}));
    
    % extract system-ID of the sencond mouse
    %Mouse1 = ConnectedMicePointer{1,1}.interfaceID;
    Mouse2 = ConnectedMicePointer{1,2}.interfaceID;
    
    % create a new 'masterPointer' (i.e., a cursor)
    system('xinput create-master PTBPointer');
    
    % get the system-ID of that  masterPointer
    [~,PTBPointerID]=system('xinput --list --id-only ''PTBPointer pointer''');
    PTBPointerID = str2double(PTBPointerID);
    
    % detach Mouse2 from old masterPointer and attach it to the new one
    system(['xinput reattach ',num2str(Mouse2),' ',num2str(PTBPointerID)]);
    
elseif isunix && ~OnOrOff
    % get ID of original masterPointer
    [~, ~, info]  = GetMouseIndices('masterPointer');
    CurrentMasterPointer = info{1,1}.interfaceID;
    % get ID of masterPointer created with previous call
    [~,PTBPointerID]=system('xinput --list --id-only ''PTBPointer pointer''');
    PTBPointerID = str2double(PTBPointerID);
    % remove masterPointer from previous call and reattach the Mouse to the
    % original masterPointer
    system(['xinput --remove-master ', num2str(PTBPointerID), ' AttachToMaster ',num2str(CurrentMasterPointer)]);
else %Win/OSX
    PTBPointerID=NaN;
end
end
