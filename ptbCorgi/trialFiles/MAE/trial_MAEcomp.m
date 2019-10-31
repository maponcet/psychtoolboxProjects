function [trialData] = trial_MAEcomp(expInfo, conditionInfo)

trialData.validTrial = true;
trialData.abortNow   = false;
trialData.response = 'none';
abortExpTrigger = 99;

% Find the color values which correspond to white and black.
white=WhiteIndex(expInfo.curWindow);
black=BlackIndex(expInfo.curWindow);
gray=(white+black)/2;
inc=white-gray;

% Enable alpha blending
Screen('BlendFunction', expInfo.curWindow, GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

% Create a special texture drawing shader for masked texture drawing:
glsl = MakeTextureDrawShader(expInfo.curWindow, 'SeparateAlphaChannel');

%%% timing test:
nbTestCycles = conditionInfo.testDuration / (1/conditionInfo.testFreq);
trialData.nbTestCycles = nbTestCycles;

%%%%%%%%%%%%%%%%%
%%%% Gratings
texsize = conditionInfo.stimSize*expInfo.ppd; % Size of the grating image.
cyclespersecond1 = conditionInfo.tempFq; % temporal frequency (related to velocity)

% spatial freq of the 2 gratings
f1 = conditionInfo.f1/expInfo.ppd; % cycle/deg

% direction of the 2 gratings
angle1 = 99;
if strcmp(conditionInfo.direction,'left')
    angle1 = 0;
elseif strcmp(conditionInfo.direction,'right')
    angle1 = 180;
end
trialData.dir1 = angle1;

% Calculate parameters of the grating:
fr1=f1*2*pi;

% Create gratings:
% the 2 gratings are created with the same sin 0 such that it gives a more
% 'edgy' stimulus (which is more natural and that the brain likes)
x = meshgrid(-texsize:texsize, -texsize:texsize);
grating1 = gray + inc*sin(fr1*x);

% add alpha column
grating1 = repmat(grating1,[1,1,3]);
grating1(:,:,4) = ones(size(grating1,1));

% Store alpha-masked grating in texture and attach the special 'glsl'
% texture shader to it:
gratingAdapt1 = Screen('MakeTexture', expInfo.curWindow, grating1 , [], [], [], [], glsl);

    
%%% shift
if conditionInfo.f1 == 0.5
    testShift = 1; % counterphase
elseif conditionInfo.f1 == 2
    testShift = 0.25; % counterphase
end
testShift = testShift/2* expInfo.ppd;

% Definition of the drawn source rectangle on the screen:
srcRect=[0 0 texsize texsize];
foveaRect = [0 0 texsize 2*expInfo.ppd];
tgtRect = [0 0 expInfo.fixationInfo(1).size*0.7*expInfo.ppd expInfo.fixationInfo(1).size*0.7*expInfo.ppd];
% yEcc = conditionInfo.yEccentricity * expInfo.ppd;

%%%%%%%%%%%%%%%%%
%%% timing for presentation
waitframes = 1;
waitduration = waitframes * expInfo.ifi; 

% Recompute p, this time without the ceil() operation from above.
% Otherwise we will get wrong drift speed due to rounding!
p1 = 1/f1; % pixels/cycle

% Translate requested speed of the gratings (in cycles per second) into
% a shift value in "pixels per frame", assuming given waitduration:
shiftperframe1 = cyclespersecond1 * p1 * waitduration;

% parameters for test
cycleDuration = 1/conditionInfo.testFreq;
framesPerCycle = 1/conditionInfo.testFreq * round(expInfo.monRefresh);
framesPerHalfCycle = framesPerCycle/2;

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
if expInfo.useBitsSharp
    trialData.trigger = conditionInfo.trigger;
    ptbCorgiSendTrigger(expInfo,'conditionnumber',true,conditionInfo.trigger);
end
    
if expInfo.useBitsSharp
    f1Trigger = expInfo.triggerInfo.ssvepTagF1;
    checkTime = 1;
    ptbCorgiSendTrigger(expInfo,'starttrial',true);
else
    f1Trigger = 1;
    checkTime = 0;
end

drawFixation(expInfo, expInfo.fixationInfo);
vbl = Screen('Flip', expInfo.curWindow);
trialData.trialStartTime = vbl;


vblAdaptTime = vbl + conditionInfo.adaptDuration;
trialData.adaptTime = vblAdaptTime;

% testShift = 0.25 * expInfo.ppd;
% Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)+yEcc),[], [], [], [], [], [], [0, 0, 0, 0]);
% Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)-yEcc),[], [], [], [], [], [], [0, testShift, 0, 0]);
% Screen('Flip', expInfo.curWindow);



%%%%%% variables for the task
% between 4 and 7 probes during adaptation
% add between 0 and 2 tgt during test
%%%% for adaptation, do it based on frames
frTgtPresent = conditionInfo.probeDuration; % nb of frames during which the target is presented
tmpTgt = shuffle(4:7); 
nbTgt = tmpTgt(1)
frAdapt = conditionInfo.adaptDuration / expInfo.ifi; % nb of frames during adaptation
timeTgtOn = randsample(1:frTgtPresent:frAdapt,nbTgt,0);
timeTgt = [];
for tt=1:length(timeTgtOn)
    timeTgt = [timeTgt timeTgtOn(tt):timeTgtOn(tt)+frTgtPresent-1];
end
trialData.nbAdaptProbe = nbTgt;
trialData.timeAdaptProbe = timeTgt;
%%% for test do it based on cycle
tmpTest = shuffle(0:2); 
nbTestProbe = tmpTest(1);
if conditionInfo.testFreq > 5
    cycleOn = randsample(0:2:nbTestCycles-1,nbTestProbe,0); % do not include last cycle: probe duration can last until the next cycle    
else
    cycleOn = randsample(0:nbTestCycles,nbTestProbe,0)-1; % cycle starts at 0
end
halfCycle = randsample(1:2,nbTestProbe,1); % present at 1st or 2nd half of the cycle
probeTest = [cycleOn' halfCycle'];
trialData.cycleOn = cycleOn;
trialData.halfCycle = halfCycle;
trialData.probeTest = probeTest;
interFrames = mod(framesPerCycle-frTgtPresent,10); % probe presented a couple of frames after the start of the cycle
interTime = interFrames * expInfo.ifi;
trialData.interTime = interTime;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ADAPTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i = 0; % incremental shift of the gratings 
if strcmp(conditionInfo.direction,'none')
    %%%%%%%%%%%%%%%%% No adaptation
    while (vbl < vblAdaptTime) && ~trialData.abortNow % && ~KbCheck(expInfo.deviceIndex)
        i=i+1;
        Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)));
        if conditionInfo.fovea == 0
            Screen('FillRect', expInfo.curWindow, gray, CenterRectOnPoint(foveaRect,expInfo.center(1),expInfo.center(2)));
        end
        drawFixation(expInfo, expInfo.fixationInfo); 
        
        if ismember(i, timeTgt)
            Screen('FillOval', expInfo.curWindow, gray, CenterRectOnPoint(tgtRect,expInfo.center(1),expInfo.center(2)));
        end
        vbl = Screen('Flip', expInfo.curWindow, vbl + (waitframes - 0.5) * expInfo.ifi);
        
        [keyDown, secs, keyCode] = KbCheck(expInfo.deviceIndex);
        if keyDown
            if keyCode(KbName('ESCAPE'))
                trialData.abortNow   = true;
                trialData.validTrial = false;
            end
            drawFixation(expInfo, expInfo.fixationInfo);
            Screen('DrawText', expInfo.curWindow, 'please do not press a key', 150, expInfo.center(2)-expInfo.center(2)/4, [0 0 0]);
            vbl = Screen('Flip',expInfo.curWindow);
            vblAdaptTime = vbl + conditionInfo.adaptDuration;
            trialData.adaptTime = vblAdaptTime;
        end
    end
else
    %%%%%%%%%%%%%%%%%
    %%% Adaptation loop: Run for 10 s or keypress.
    while (vbl < vblAdaptTime) && ~trialData.abortNow % && ~KbCheck(expInfo.deviceIndex)
        
        % Shift the grating by "shiftp2perframe" pixels per frame. We pass
        % the pixel offset 'yoffset' as a parameter to
        % Screen('DrawTexture'). The attached 'glsl' texture draw shader
        % will apply this 'yoffset' pixel shift to the RGB or Luminance
        % color channels of the texture during drawing, thereby shifting
        % the gratings. Before drawing the shifted grating, it will mask it
        % with the "unshifted" alpha mask values inside the Alpha channel:
        yoffset1 = mod(i*shiftperframe1,p1);
        i=i+1;
        
        % Draw gratings texture, rotated by "angle":
        Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)), angle1, [], [], [], [], [], [0, yoffset1, 0, 0]);
        if conditionInfo.fovea == 0
            Screen('FillRect', expInfo.curWindow, gray, CenterRectOnPoint(foveaRect,expInfo.center(1),expInfo.center(2)));
        end
        drawFixation(expInfo, expInfo.fixationInfo);
        if ismember(i, timeTgt)
            Screen('FillOval', expInfo.curWindow, gray, CenterRectOnPoint(tgtRect,expInfo.center(1),expInfo.center(2)));
        end        
        
        % Flip 'waitframes' monitor refresh intervals after last redraw.
        vbl = Screen('Flip', expInfo.curWindow, vbl + (waitframes - 0.5) * expInfo.ifi);
            
        [keyDown, secs, keyCode] = KbCheck(expInfo.deviceIndex);
        if keyDown
            if keyCode(KbName('ESCAPE'))
                trialData.abortNow   = true;
                trialData.validTrial = false;
            end
            drawFixation(expInfo, expInfo.fixationInfo);
            Screen('DrawText', expInfo.curWindow, 'please do not press a key', 150, expInfo.center(2)-expInfo.center(2)/4, [0 0 0]);
            vbl = Screen('Flip',expInfo.curWindow);
            vblAdaptTime = vbl + conditionInfo.adaptDuration;
            trialData.adaptTime = vblAdaptTime;
        end
    end
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TEST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test presented right after the end of adaptation = no stimulus onset that
% would create an ERP so that we can record SSVEP earlier 

cycle = 0;
while cycle<nbTestCycles && trialData.validTrial % ~KbCheck(expInfo.deviceIndex)
    [keyDown, secs, keyCode] = KbCheck(expInfo.deviceIndex);
    if keyDown
        if keyCode(KbName('ESCAPE'))
            trialData.abortNow   = true;
            trialData.validTrial = false;
        end
    end

    % first stim
    Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)),[], [], [], [], [], [], [0, 0, 0, 0]);
    if conditionInfo.fovea == 0
        Screen('FillRect', expInfo.curWindow, gray, CenterRectOnPoint(foveaRect,expInfo.center(1),expInfo.center(2)));
    end
    drawFixation(expInfo, expInfo.fixationInfo);
    if probeTest(1) == cycle-1 && probeTest(2) == 2 &&  conditionInfo.testFreq > 5
        Screen('FillOval', expInfo.curWindow, gray, CenterRectOnPoint(tgtRect,expInfo.center(1),expInfo.center(2)));
    end
    ptbCorgiSendTrigger(expInfo,'raw',0,f1Trigger);
    vbl = Screen('Flip', expInfo.curWindow, vbl + (framesPerHalfCycle - 0.5) * expInfo.ifi);
    vbl1 = vbl;
    if cycle == 0
        trialData.trialTestTime = vbl;
    elseif checkTime
%         vbl1 - vbl2
        if vbl1 - vbl2 > cycleDuration/2 + expInfo.ifi/2 || vbl1 - vbl2 < cycleDuration/2 - expInfo.ifi/2
            trialData.validTrial = false;
        end
    end
    
    if probeTest(1) == cycle && probeTest(2) == 1
        Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)),[], [], [], [], [], [], [0, 0, 0, 0]);
        if conditionInfo.fovea == 0
            Screen('FillRect', expInfo.curWindow, gray, CenterRectOnPoint(foveaRect,expInfo.center(1),expInfo.center(2)));
        end
        drawFixation(expInfo, expInfo.fixationInfo);
        Screen('FillOval', expInfo.curWindow, gray, CenterRectOnPoint(tgtRect,expInfo.center(1),expInfo.center(2)));
        Screen('Flip', expInfo.curWindow, vbl + (interTime - 0.5) * expInfo.ifi);
    end
    
    % second stim
    Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)),[], [], [], [], [], [], [0, testShift, 0, 0]);
    if conditionInfo.fovea == 0
        Screen('FillRect', expInfo.curWindow, gray, CenterRectOnPoint(foveaRect,expInfo.center(1),expInfo.center(2)));
    end
    drawFixation(expInfo, expInfo.fixationInfo);
    if probeTest(1) == cycle && probeTest(2) == 1 &&  conditionInfo.testFreq > 5
        Screen('FillOval', expInfo.curWindow, gray, CenterRectOnPoint(tgtRect,expInfo.center(1),expInfo.center(2)));
    end
    ptbCorgiSendTrigger(expInfo,'clear',0);
    vbl = Screen('Flip', expInfo.curWindow, vbl + (framesPerHalfCycle - 0.5) * expInfo.ifi);
    vbl2 = vbl;
    
    if checkTime
%         vbl2 - vbl1
        if vbl2 - vbl1 > cycleDuration/2 + expInfo.ifi/2 || vbl2 - vbl1 < cycleDuration/2 - expInfo.ifi/2
            trialData.validTrial = false;
        end
    end

    if probeTest(1) == cycle && probeTest(2) == 2
        Screen('DrawTexture', expInfo.curWindow, gratingAdapt1, srcRect, CenterRectOnPoint(srcRect,expInfo.center(1),expInfo.center(2)),[], [], [], [], [], [], [0, 0, 0, 0]);
        if conditionInfo.fovea == 0
            Screen('FillRect', expInfo.curWindow, gray, CenterRectOnPoint(foveaRect,expInfo.center(1),expInfo.center(2)));
        end
        drawFixation(expInfo, expInfo.fixationInfo);
        Screen('FillOval', expInfo.curWindow, gray, CenterRectOnPoint(tgtRect,expInfo.center(1),expInfo.center(2)));
        Screen('Flip', expInfo.curWindow, vbl + (interTime - 0.5) * expInfo.ifi);
    end
    
    % increment cycle
    cycle = cycle+1;
end

[keyDown, secs, keyCode] = KbCheck(expInfo.deviceIndex);
if keyDown
    if keyCode(KbName('ESCAPE'))
        trialData.abortNow   = true;
        trialData.validTrial = false;
    end
end

drawFixation(expInfo, expInfo.fixationInfo);
if expInfo.useBitsSharp
    if trialData.validTrial
        ptbCorgiSendTrigger(expInfo,'raw',0,f1Trigger);
    else
        ptbCorgiSendTrigger(expInfo,'raw',1,abortExpTrigger); % abort trial
    end
end
trialData.trialEndTime = Screen('Flip', expInfo.curWindow, vbl + (framesPerHalfCycle - 0.5) * expInfo.ifi);
if trialData.validTrial
    trialData.testDuration = trialData.trialEndTime - trialData.trialTestTime;
    trialData.trialDuration = trialData.trialEndTime - trialData.trialStartTime;
end

%%%% close all the textures
Screen('Close', gratingAdapt1);

ptbCorgiSendTrigger(expInfo,'clear',0);
drawFixation(expInfo, expInfo.fixationInfo);
Screen('Flip', expInfo.curWindow);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RESPONSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get response: direction of MAE
if trialData.validTrial
    % response screen
    Screen('DrawText', expInfo.curWindow, 'number of targers?', 150, expInfo.center(2)-expInfo.center(2)/4, [0 0 0]);
    Screen('DrawText', expInfo.curWindow, '(choose between 4 and 9)', 150, expInfo.center(2), [0 0 0]);

    trialData.respScreenTime =Screen('Flip',expInfo.curWindow);
    % check for key press
    while strcmp(trialData.response,'none') && (GetSecs < trialData.respScreenTime + conditionInfo.maxToAnswer)
        [keyDown, secs, keyCode] = KbCheck(expInfo.deviceIndex);
        if keyDown
            trialData.rt = secs - trialData.respScreenTime;
            keyCode(KbName)
            if keyCode(KbName('4'))
                trialData.response = 4;
            elseif keyCode(KbName('5'))
                trialData.response = 5;
            elseif keyCode(KbName('6'))
                trialData.response = 6;
            elseif keyCode(KbName('7'))
                trialData.response = 7;
            elseif keyCode(KbName('8'))
                trialData.response = 8;
            elseif keyCode(KbName('9'))
                trialData.response = 9;
            elseif keyCode(KbName('ESCAPE'))
                trialData.abortNow   = true;
                trialData.response = 'abort';
            else
                Screen('DrawText', expInfo.curWindow, 'not an existing response key', 150, expInfo.center(2)-expInfo.center(2)/4, [0 0 0]);
                Screen('DrawText', expInfo.curWindow, 'please choose between 4 and 9', 50, expInfo.center(2), [0 0 0]);
                Screen('Flip',expInfo.curWindow);
            end
        end
    end
    FlushEvents('keyDown');    
end

if expInfo.useBitsSharp
    ptbCorgiSendTrigger(expInfo,'endtrial',true);
end
    
end


