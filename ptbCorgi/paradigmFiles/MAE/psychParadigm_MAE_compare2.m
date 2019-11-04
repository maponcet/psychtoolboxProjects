function [conditionInfo, expInfo] = psychParadigm_MAE_compare2(expInfo)
% mix the different test conditions
% 9 Hz test works. Now compare with small phase and counterphase flicker
% - 9Hz 90deg
% - 9Hz 10deg
% - 9Hz 180deg
% All with 0.5 c/deg
% 25 s adapt followed by 10 s test
% 3 different tests (blocked) x 9 times each = 27 trials in adaptation
% block x 2 directions + 3x9 trials in unadaptated

% triggers: 101 102 103 = not meaningful
% only consider 111 to 133


KbName('UnifyKeyNames');



conditionInfo(1).direction = 'none';
% choose from none, left, or right adaptation
% sequence: none - L/R - none - L/R - none


if strcmp(conditionInfo(1).direction, 'none')
    expInfo.trialRandomization.nBlockReps = 3;
    condition = 10;
    %     conditionInfo(1).nReps = 3;
else
    expInfo.trialRandomization.nBlockReps = 9; % 9
    %     conditionInfo(1).nReps = 9;
    if strcmp(conditionInfo(1).direction, 'left')
        condition = 20;
    elseif strcmp(conditionInfo(1).direction, 'right')
        condition = 30;
    end
end


%paradigmName is what will be prepended to data files
expInfo.paradigmName = 'MAEcomp';
expInfo.viewingDistance = 57;
expInfo.trialRandomization.type = 'custom';
list = repmat(1:3,expInfo.trialRandomization.nBlockReps,1);
expInfo.trialRandomization.trialList  = Shuffle(list(:)');

expInfo.useBitsSharp = true;
expInfo.enableTriggers = true;

expInfo.fixationInfo(1).type  = 'dot';
expInfo.fixationInfo(1).size  = .15; % radius of the dot
expInfo.fixationInfo(1).loc = [0 0]; % location of the fixation relative to centre in degrees (1st number is horizontal, 2nd is vertical)

expInfo.instructions = 'FIXATE the dot';
expInfo.showTrialNb = 1; % give trial nb at the end of each trial (+ wait for keyboard)

conditionInfo(1).maxToAnswer = 5000;
conditionInfo(1).iti = 0;
conditionInfo(1).type = 'Generic';
conditionInfo(1).giveFeedback = 1;
conditionInfo(1).intervalBeep = 0;
conditionInfo(1).trialFun=@trial_MAEcomp;
conditionInfo(1).stimSize = 24; % 24 grating image in degrees. 
% should be an integer of 8 so that the lowest spatial frequency grating will
% have full cycles only = the average luminance of the grating is equal to the background luminance 
conditionInfo(1).yEccentricity = 3;
conditionInfo(1).tempFq = 85/18; % 85/18 or 85/16? 4.72 Hz 
conditionInfo(1).testDuration = 840/85; % in s: 840/85
conditionInfo(1).adaptDuration = 25; % in sec: 25

conditionInfo(1).probeDuration = 6; % nb of frames (6 frames = 70ms)

conditionInfo(1).f1 = 0.5; % 0.5 cycle/deg
conditionInfo(1).testFreq = 85/10; % 8.5 Hz
conditionInfo(1).fovea = 0;

%%%%%%%%%%%% parameters for the different conditions
conditionTemplate = conditionInfo(1); 
conditionInfo = createConditionsFromParamList(conditionTemplate,'pairwise',...
    'phase',[10 90 180],...
    'trigger',[1+condition 2+condition 3+condition]); 


end





