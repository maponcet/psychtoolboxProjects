function [trialData] = trial_DC_rating(expInfo, conditionInfo)
% if the escape key is pressed then the experiment is aborted
% press space to pause the experiment

stimStartTime = 0;
black = BlackIndex(expInfo.curWindow);


drawFixation(expInfo, expInfo.fixationInfo);
t = Screen('Flip', expInfo.curWindow);
trialData.validTrial = true;
trialData.abortNow   = false;
trialData.trialStartTime = t;
trialData.response = 999;
ifi = expInfo.ifi;

if expInfo.useBitsSharp
    checkTiming = 1;
else
    checkTiming = 0; % timing of the nb of frames only checked for the "real" experiment using bitsharp
end

%%% VEP parameters
framesPerCycle = 1/conditionInfo.stimTagFreq * round(expInfo.monRefresh);
cycleDuration = 1/conditionInfo.stimTagFreq;
monitorPeriodSecs = 1/round(expInfo.monRefresh);

% framesPerCycle = cycleDuration / monitorPeriodSecs;
framesOn = conditionInfo.dutyCycle * framesPerCycle;
framesOff = framesPerCycle - framesOn;

timeStimOn = monitorPeriodSecs * framesOn;
timeStimOff = monitorPeriodSecs * framesOff;

nbTotalCycles = ceil(conditionInfo.trialDuration * conditionInfo.stimTagFreq);
trialDuration = nbTotalCycles * cycleDuration; % =11.67060200

% save it in the data output structure
trialData.framesPerCycle = framesPerCycle;
trialData.framesOn = framesOn;
trialData.framesOff = framesOff;
trialData.timeStimOn = timeStimOn;
trialData.timeStimOff = timeStimOff;
trialData.nbTotalCycles = nbTotalCycles;
trialData.trialDuration = trialDuration;
trialData.cycleDuration = cycleDuration;



%%% stim presentation
rectStim = conditionInfo.stimSize*expInfo.ppd;
ycoord = expInfo.center(2) - (conditionInfo.yloc * expInfo.ppd); % - above
xcoord = expInfo.center(1) + (conditionInfo.xloc * expInfo.ppd); % + right
eccMotion = xcoord + (conditionInfo.xMotion * expInfo.ppd); 
loc1 = conditionInfo.loc1 * expInfo.ppd;
loc2 = conditionInfo.loc2 * expInfo.ppd;

% horizontal bar
horizBar = conditionInfo.horizBar*expInfo.ppd;
yBarTop = ycoord - conditionInfo.stimSize(4)/2*expInfo.ppd;
yBarBottom = ycoord + conditionInfo.stimSize(4)/2*expInfo.ppd;


% start trial
for cycleNb = 1 : nbTotalCycles
    % check if key is pressed in case needs to quit
    [keyIsDown, secs, keyCode]=KbCheck(expInfo.deviceIndex);
    if keyIsDown
        trialData.validTrial = false;
        if keyCode(KbName('escape'))
            trialData.abortNow   = true;
        elseif keyCode(KbName('space'))
            trialData.validTrial = false;
            Screen('DrawText', expInfo.curWindow, 'Taking a break', 0, expInfo.center(2), [0 0 0]);
            Screen('DrawText', expInfo.curWindow, 'Press c to continue', 0, expInfo.center(2)+expInfo.center(2)/4, [0 0 0]);
            Screen('Flip',expInfo.curWindow);
            pressSpace = 1;
            while pressSpace
                [keyIsDown, secs, keyCode]=KbCheck(expInfo.deviceIndex);
                if keyCode(KbName('c'))
                    pressSpace = 0;
                end
            end
        end
        break;
    end

    %%% stim ON
    drawFixation(expInfo, expInfo.fixationInfo);
    if conditionInfo.motion == 1 && mod(cycleNb,2)==0 % in motion
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(rectStim,eccMotion,ycoord));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(rectStim,eccMotion+loc1,ycoord));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(rectStim,eccMotion+loc2,ycoord));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(horizBar,eccMotion+loc1,yBarTop));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(horizBar,eccMotion+loc1,yBarBottom));
    else
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(rectStim,xcoord,ycoord));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(rectStim,xcoord+loc1,ycoord));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(rectStim,xcoord+loc2,ycoord));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(horizBar,xcoord+loc1,yBarTop));
        Screen('FillRect', expInfo.curWindow, black,CenterRectOnPoint(horizBar,xcoord+loc1,yBarBottom));
    end
    prevStim = t;
    t = Screen('Flip', expInfo.curWindow, t + framesOff * ifi - ifi/2);
    if cycleNb == 1
        stimStartTime = t;
    end
    
    %%% stim OFF
    %Screen('FillRect', expInfo.curWindow, expInfo.bckgnd);
    drawFixation(expInfo, expInfo.fixationInfo);
    t = Screen('Flip', expInfo.curWindow, t + framesOn * ifi - ifi/2 );
        
    if checkTiming
        if t-prevStim > cycleDuration + ifi/2 || t-prevStim < cycleDuration - ifi/2
            trialData.validTrial = false;
            break;
        end
    end
        
end

% this is to send a last trigger
drawFixation(expInfo, expInfo.fixationInfo);
prevStim = t;
t = Screen('Flip', expInfo.curWindow, t + framesPerCycle * ifi - ifi/2);
trialData.stimEndTime = t;
% t-prevStim
if checkTiming
    if t-prevStim > cycleDuration + ifi/2 || t-prevStim < cycleDuration - ifi/2
    trialData.validTrial = false;
    end
end

trialData.stimStartTime = stimStartTime;

% Find the key values (not the same in PC and MAC) for the response loop
for keyVal=0:3
    vectKeyVal(keyVal+1) = KbName(num2str(keyVal));
end

if trialData.validTrial
    % response screen
    Screen('DrawText', expInfo.curWindow, 'Strengh of motion?', 0, expInfo.center(2), [0 0 0]);
    Screen('DrawText', expInfo.curWindow, '0.none  1.weak  2.medium  3.strong', 0, expInfo.center(2)+expInfo.center(2)/4, [0 0 0]);
    trialData.respScreenTime =Screen('Flip',expInfo.curWindow);
    % check for key press
    while trialData.response==999 % && (GetSecs < trialData.respScreenTime + conditionInfo.maxToAnswer -ifi/2)
        [keyDown, secs, keyCode] = KbCheck;
        if keyDown
            if find(keyCode)>=min(vectKeyVal) && find(keyCode)<=max(vectKeyVal)
                trialData.response = str2num(KbName(keyCode));
                trialData.rt = secs - trialData.respScreenTime;
            else
                if keyCode(KbName('ESCAPE'))
                    trialData.abortNow   = true;
                end
                trialData.validTrial = false;break;
            end
        end
    end
    FlushEvents('keyDown');
end

if trialData.response==999 % no response
    trialData.validTrial = false;
end

drawFixation(expInfo, expInfo.fixationInfo);
t = Screen('Flip', expInfo.curWindow);
trialData.trialEndTime = t;

trialData.trialDurationReal = trialData.stimEndTime - trialData.stimStartTime ;
trialData.trialDurationTotal = trialData.trialEndTime - trialData.trialStartTime ;


end

