%Adapted from Peter Scarfe's PTB demos (at http://peterscarfe.com/) and 
%the PTB-3 MovingLineDemo.
% Clear the workspace and the screen
close all;
clear all; %#ok<CLSCR>
sca

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer. For help see: Screen Screens?
screens = Screen('Screens');

screenNumber = max(screens);

% Define black and white (white will be 1 and black 0).
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

%% Get the start and end x coordinates for the line to move between

xRangeinitial = false; 
while (~ xRangeinitial) %while not in the range of x pixels

    xquestionini = 'Your starting X coordinate? '; %asks for the x 
    %coordinate that you want the line to be moved from
    
   xinitial = input(xquestionini); %initial x coordinate is the input
    
    if xinitial <= 1920 && xinitial >= 0 %if the x answer is outside the 
    %specified range for the lilac room
    
%      if xinitial <= 1280 && xinitial >= 0 %if the x answer is outside the 
%     %specified range for the CRT in the lab
        
    xRangeinitial = true;
    
    else
        
        xRangeinitial = false;
        disp('Please enter a value in the range 0-1920'); %lilac room
        
%         xRangeinitial = false;
%         disp('Please enter a value in the range 0-1920'); %lab crt
         
    end
end 

xRangefinal = false; 
while (~ xRangefinal) %while not in the range of x pixels

    xquestionfin = 'Your end X coordinate? '; %asks for the x 
    %coordinate that you want the line to be moved from
    
   xfinal = input(xquestionfin); %initial x coordinate is the input
    
    if xfinal <= 1920 && xfinal >= 0 %if the x answer is outside the 
    %specified range for the lilac room
    
%      if xfinal <= 1280 && xfinal >= 0 %if the x answer is outside the 
%     %specified range for the CRT in the lab
        
    xRangefinal = true;
    
    else
        
        xRangefinal = false;
        disp('Please enter a value in the range 0-1920'); %lilac room
        
%         xRangefinal = false;
%         disp('Please enter a value in the range 0-1920'); %lab crt
         
    end
end 


speedquestion = 'How fast would you like the line to move across the screen? ';
    
xv = input(speedquestion); %xv = the speed that the line is moving 
   %through the x axis. Not entirely sure how this translates into metres
   %per second/ millimetres per second/ degrees per second?
   %As coded here it's in pixels/(time to iterate while loop). Most likely a single video frame so:
   % Pixels / ifi

%% Generating the window with the line
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window in pixels.
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window); %taken from PTB-3 MovingLineDemo
vbl=Screen('Flip', window); %taken from PTB-3 MovingLineDemo
% Get the centre coordinate of the window in pixels
%[xCenter, yCenter] = RectCenter(windowRect);

% basically for adapting this code into the wrapper you just need to start
% here. The wrapper script handles everything above.
%-------------------------------------------------------
% function [trialData] = drawDotTrial(screenInfo, conditionInfo)
%
lw = 1; %linewidth


if xinitial > xfinal;
       
    while xinitial > xfinal;
     xinitial=mod(xinitial-xv, screenXpixels); %the part that actually gets 
     %the line to move within the while loop. taking xv off the value to
     %move to the left.
        Screen('DrawLines', window, [xinitial, xinitial ; 0, screenYpixels], lw); 
        vbl=Screen('Flip', window,vbl+ifi/2); %taken from PTB-3 MovingLineDemo
        %if this isn't flipped within the while loop you won't see the line
        %being moved across the window.
    end
else
    while xinitial < xfinal; 
     xinitial=mod(xinitial+xv, screenXpixels); %adding xv onto the value so
     %that the line moves towards the right
        Screen('DrawLines', window, [xinitial, xinitial ; 0, screenYpixels], lw); 
        vbl=Screen('Flip', window,vbl+ifi/2); %taken from PTB-3 MovingLineDemo
        %Drawing and flipping everything onto the screen so that it appears
        %as it should.

    end 
end    

KbStrokeWait;

%This would be the end of your trial script. 
%%%%%
%--------------------------
% This also gets handled by the wrapper script. 
% Clear the screen. "sca" is short hand for "Screen CloseAll". This clears
% all features related to PTB. Note: we leave the variables in the
% workspace so you can have a look at them if you want.
% For help see: help sca
sca;