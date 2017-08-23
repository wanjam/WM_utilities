function [window] = PixxPut(window,PutVal,CLUT,BiosemiCableInUse)
%[window] = PIXXPUT(window,PutVal[,CLUT][,BiosemiCableInUse]) Puts a trigger to the ViewPixx
%   Calculates the color that should be drawn on the top left pixel of the
%   ViewPixx \EEG display, in order to trigger a value PUTVAL to the EEG
%   recording.
%   NOTE: LEAVE THE MS-WINDOWS DESKTOP-BACKGROUND BLACK! This way, the trigger that's
%   sent once PTB closes is always 0.
%   NOTE2: This function only draws on the buffer. The actual trigger is not
%   sent until you subsequently flip the screen and it is triggered for as
%   long as this screen is presented. (You'd need to re-flip, to null it)
%
%   INPUT:
%   window            = PTB-window-pointer
%   PutVal            = 0-255, the triggervalue you want to send
%   CLUT              = 256x3 Matrix with CLUT values of 0-1; if present,
%                       the calculated RGB-values are recalculated to match
%                       the CLUT.
%   BiosemiCableInUse = The optional argument BIOSEMICABLEINUSE can be set to 1 (default), if
%                       the Biosemi Presentation cable or the AE Busch specialized cable is
%                       used. This db25->db37 adapter has pins 2-9 on the db25 side soldered to
%                       pins 1-8 on the db37 side, set to 1 to take care of that (default).
%
% Wanja Moessing July 2016

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
if PutVal>255
    warning('The code you sent with PixxPut requests that more than 8 pins are connected. Are you sure that is true?');
end

if ~exist('BiosemiCableInUse','var')
    BiosemiCableInUse=1;
end

%Convert PutVal to a binary Code
binaryCode = dec2bin(PutVal,24);
binaryCode = str2num(binaryCode(:));

if BiosemiCableInUse
    %Hack for cables that have Pins 1-8 on Input side soldered to Pins 2-9 on
    %output side.
    binaryCode = [binaryCode(2:end)' 0];
end
%create a matrix that contains the pins associated to red in row 1 and the
%associated values that need to be added to the RGB value in row 2
redval=[25-[1,13,2,14,3,15,4,16];[1,2,4,8,16,32,64,128]]; %'25-pins' because Pin 1 is the last number in binaryCode
for i = redval(1,:)
    if ~binaryCode(i)
        % If the above binary code doesn't have a 1 at pin redval(1,i), set the
        % associated value to 0
        redval(2,redval(1,:)==i) = 0;
    end
end

greenval=[25-[5,17,6,18,7,19,8,20];[1,2,4,8,16,32,64,128]];
for i = greenval(1,:)
    if ~binaryCode(i)
        greenval(2,greenval(1,:)==i) = 0;
    end
end

blueval=[25-[9,21,10,22,11,23,12,24];[1,2,4,8,16,32,64,128]];
for i = blueval(1,:)
    if ~binaryCode(i)
        blueval(2,blueval(1,:)==i) = 0;
    end
end

%sum all the second rows of the three matrices and the result is the RGB
% This works flawless, as long as no special CLUT is in use.
RGBvals     = [sum(redval(2,:)),sum(greenval(2,:)),sum(blueval(2,:))];

%% If CLUT is used
if exist('CLUT','var')
    
    %subtract the RGB values from the corresponding rows in the CLUT and
    %find the index of the number closest to 0
    [~,Rn] = min(abs(CLUT(:,1)- RGBvals(1)/255));
    [~,Gn] = min(abs(CLUT(:,2)- RGBvals(2)/255));
    [~,Bn] = min(abs(CLUT(:,3)- RGBvals(3)/255));
    
    %     if ~any(abs(CLUT(:,2)*255-RGBvals(2))<1) || ~any(abs(CLUT(:,1)*255-RGBvals(1))<1)
    %         tCLUT=CLUT*255;
    %         warning('With this custom CLUT, it is not possible to trigger the desired value.\nInstead of %d %d %d, I will use the RGB code %d %d %d, which in the CLUT is color %.2f %.2f %.2f\n',RGBvals(1),RGBvals(2),RGBvals(3),Rn-1,Gn-1,Bn-1,tCLUT(Rn,1),tCLUT(Gn,2),tCLUT(Bn,3));
    %     end
    
    %subtract 1, as matlab is 1-256 and RGB is 0-255
    RGBvals = [Rn,Gn,Bn]-1;
end

%% Put value to pixel value
Screen('FillRect',window,RGBvals,[0,0,1,1]);


%debug message:
% fprintf(2,'\nTrigger: %d RGBvals:%d %d %d\n',PutVal,RGBvals(1),RGBvals(2),RGBvals(3));
% global trigtabCLUT
% if ~exist('trigtabCLUT','var')
%     trigtabCLUT = [PutVal,RGBvals];
% else
%     trigtabCLUT = [trigtabCLUT;PutVal,RGBvals];
% end


end


