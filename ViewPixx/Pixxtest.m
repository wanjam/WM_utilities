AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);
w=Screen('OpenWindow',max(Screen('Screens')));
load('inverse_CLUT20160517T114847.mat');
[oldCLUT,~] = Screen('LoadNormalizedGammaTable',w,inverseCLUT);

for i = 0:255
    PixxPut(w,i,inverseCLUT);
    Screen('Flip',w);
    WaitSecs(.2);
    Screen('FillRect',w,[0,0,0],[0,0,1,1]);
    Screen('Flip',w);
    WaitSecs(.05);
end
Screen('LoadNormalizedGammaTable',w,oldCLUT);
sca;