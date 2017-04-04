function [curloc,hsmvd,btprsd,x,y] = InpMoved(P,lastloc,wPtr,Wheel)
%INPMOVED unifies the output of Gamepad, Mouse & Griffin Powermate
%
%   via the optional input 'lastloc' with fields .y and .x, a previous
%   location can be provided, to which the new location is compared.
%   The default threshold for reporting a move is 10px. Optionally, this
%   can be specified in P.AllowedMouseMove.
%   P (optional as well) with field P.isPad informs the function about the
%   connected sort of input device (default is 0=Mouse).
%   If P.isPad == 1, the function also requires P.PadHandle, to know which
%   gamepad to check, as well as P.myHeight and P.myWidth (Resolution of
%   the Screen).
%   If P.isPad ==2, the function polls the Griffin Powermate instead. It
%   then needs input to get the pixel coordinates of the circle where
%   subjects can respond. You can either supply that directly as argument
%   'Wheel'(see in code below how to construct one) or you can supply
%   all of: P.myHeight, P.myWidth, P.matePrec, P.mateRad.
%   to construct a Wheel. Obviously the powermate can then only output
%   coordinates that are in Wheel.
%   Like for the Gamepad, this function needs to know the handle for the
%   powermate as well. Usually, you would define that at the start of the
%   experiment via P.mateHandle = PsychPowerMate('Open');  and close it at
%   the end with PsychPowerMate('Close', P.mateHandle);
%   The output parameter 'hsmvd' is a boolean defining if the location has
%   changed (default = 0).
%   'curloc' always provides the current location in pixel coordinates.
%   Also outputs btprsd = is any button/key pressed
%
%   First version by Wanja Moessing on Feb 25, 2016
%   Included btprsd WM, June 2016
%   Added powermate functionality Mar 31,2017 (WM)

%on linux: when no screen is defined simply poll standard
if nargin<3
    wPtr=[];
end

%if P.isPad doesn't exist poll standard mouse
if ~isfield(P,'isPad')
    P.isPad = 0;
end

%if no maximally allowed move is defined, take 10 pixels
if ~isfield(P,'P.AllowedMouseMove')
    P.AllowedMouseMove = 10;
end

%if input from PowerMate is required you want to output matePos, so you can
%compare to previous runs. If no lastloc.matePos is given, just assume 0,
%the initial value.
if P.isPad==2 && exist('lastloc','var')
    if ~isfield(lastloc,'matePos')
        lastloc.matePos = 0;
    end
elseif P.isPad==2 && ~exist('lastloc','var')
    lastloc.matePos=0;
end

%control where output begins if no lastloc is given and mate is used
if ~isfield(P,'RandoMate')
    P.RandoMate = 'random';
end


%create wheel if it doesn't exist
if ~exist('Wheel','var') && P.isPad ==2
    Wheel = [cosd(1/P.matePrec:(1/P.matePrec):360).*P.mateRad + P.myWidth/2; ...
        sind(360-(1/P.matePrec):-(1/P.matePrec):0).*P.mateRad + P.myHeight/2];
end

%when mouse or gamepad produced x&y values that are not on the powermate's
%wheel, ignore that lastloc and just set it to whatever. Else find indices
%that represent the lastloc
if P.isPad==2
    if exist('lastloc','var')
        mateIdx = Wheel(1,:)==lastloc.x & Wheel(2,:)==lastloc.y;
    else
        mateIdx = 0;
    end
    if ~any(mateIdx)
        if strcmp(P.randoMate,'random')
            mateIdx = find(randi(length(Wheel),1));
        else
            mateIdx = P.randoMate*P.RespWheelPrec; %set to to degree
        end
    end
end


%Poll current location of device
switch P.isPad
    case 0
        [curloc.x,curloc.y,mbut]   =   GetMouse(wPtr);
    case 1
        [curloc.x,curloc.y]   =   convertPadAxes(axis(P.PadHandle),P);
    case 2
        [matebutton, curloc.matePos]     =   PsychPowerMate('Get', P.mateHandle);
        %use the Wheel from above to determine the x & y coordinates that
        %correspond to the move. P.randomMate can be used to control
        %whether to choose a random or a specific value as starting point.
        if curloc.matePos ~= lastloc.matePos
            if curloc.matePos<lastloc.matePos
                mateIdx = mateIdx-(lastloc.matePos-curloc.matePos);
            else
                mateIdx = mateIdx+(lastloc.matePos-curloc.matePos);
            end
            if mateIdx<0
                tmp = Wheel(:,end-mateIdx);
            else
                tmp = Wheel(:,mod(mateIdx,length(Wheel)));
            end
            curloc.x = tmp(1,:);
            curloc.y = tmp(2,:);
        else
            curloc=lastloc;
        end
end


%Check if buttons are pressed
btprsd =0;
switch P.isPad
    case 0
        btprsd=any(mbut);
    case 1
        padStat = button(P.PadHandle);
        if sum(padStat)>0
            btprsd=1;
        end
    case 2
        btprsd=matebutton;
end


if ~exist('lastloc','var') || isempty(lastloc)
    hsmvd = 0;
elseif hypot((curloc.x-lastloc.x),(curloc.y-lastloc.y))>P.AllowedMouseMove
    hsmvd = 1;
elseif hypot((curloc.x-lastloc.x),(curloc.y-lastloc.y))<=P.AllowedMouseMove
    hsmvd =0;
end

% this might be useful if a struct is inconvenient for the flow
if nargout>3
    x = curloc.x;
    y = curloc.y;
end
end