function [] = setupPtbCorgi()

luminanceCalibInfo=[];
sizeCalibInfo     =[];


computerName = ptbCorgiGetComputerName();

fh = figure('Visible','on','Units','normalized','Position',[.1 .2 .55 .6]);

yStartPos = .91;

%Computer Name
uicontrol(fh,'Style','text',...
    'String','Computer Name:',...
    'Units','normalized','Position',[.81 yStartPos .15 .05]);

nameTextBoxHandle = uicontrol(fh,'Style','edit',...
    'String',computerName,...
    'Units','normalized','Position',[.81 yStartPos-.03 .15 .05]);

uicontrol(fh,'Style','pushbutton',...
    'String','Change Name',...
    'Units','normalized','Position',[.81 yStartPos-.09 .15 .05],...
    'callback',@changeComputerName);

%-------------------
%Directories
if ispref('ptbCorgi','base')
    baseDir = getpref('ptbCorgi','base');
else
    baseDir = which('ptbCorgi.m');
    setpref('ptbCorgi','base',baseDir);
end

if ispref('ptbCorgi','datadir');
    dataDir = getpref('ptbCorgi','datadir');
else
    dataDir = [];
end

if ispref('ptbCorgi','calibdir');
    calibDir = getpref('ptbCorgi','calibdir');
else
    calibDir = [];
end

uicontrol(fh,'Style','text',...
    'String','Base Directory:','HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 .91 .15 .05]);

baseDirHandle = uicontrol(fh,'Style','edit',...
    'String',baseDir,'HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 .88 .4 .05]);

uicontrol(fh,'Style','pushbutton',...
    'String','Choose ptbCorgi base directory','HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 .825 .25 .05],...
    'callback',@chooseBaseDir);

uicontrol(fh,'Style','text',...
    'String','Data Directory:','HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 .77 .15 .05]);

dataDirHandle = uicontrol(fh,'Style','edit',...
    'String',dataDir,'HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 .74 .4 .05]);

uicontrol(fh,'Style','pushbutton',...
    'String','Choose Data Directory','HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 .685 .25 .05],...
    'callback',@chooseDataDir);

yPos = .63;
uicontrol(fh,'Style','text',...
    'String','Calibration Directory:','HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 yPos .15 .05]);

calibDirHandle = uicontrol(fh,'Style','edit',...
    'String',calibDir,'HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 yPos-.03 .4 .05]);

uicontrol(fh,'Style','pushbutton',...
    'String','Choose Calibration Directory','HorizontalAlignment','left',...
    'Units','normalized','Position',[.35 yPos-.08 .25 .05],...
    'callback',@chooseCalibDir);




%--------
%device
deviceIdx = 1;
deviceList = {'None','Bits Sharp'};
validateBitsVisible = 'off';

if ispref('ptbCorgi','useBitsSharp');
    
    useBitsSharp = getpref('ptbCorgi','useBitsSharp');    
    if useBitsSharp
        deviceIdx = 2;
        deviceList = {'None','Bits Sharp *ptbCorgi*'};
        validateBitsVisible='on';
    end    
end


yPos = .4;
devicePopupH = uicontrol(fh,'Style','popupmenu',...
    'String',deviceList,'Value',deviceIdx,...
    'Units','normalized','Position',[.1 yPos 0.2 .05],...
    'callback',@selectDevice);

uicontrol(fh,'Style','text','String','Output Device',...
    'Units','normalized','Position',[0 yPos 0.1 .05])

% uicontrol(fh,'Style','pushbutton',...
%     'String','Validate Bits Sharp',...
%     'Units','normalized','Position',[0 .2 0.3 .05],...
%     'visible',validateBitsVisible,'callback',@validateBitsSharp);


%---------------------
%Resolution

[screenPref resPref hzPref bitDepthPref] = getPtbCorgiMonPref();
calibList = ptbCorgiGetCalibFileList(calibDir);

%Setup the screen selection popup.
screenHandleList = Screen('screens');
screenLabelList = cellstr(num2str(screenHandleList(:)));

selScreenIdx = find(screenHandleList==screenPref);

selScreenNum = screenHandleList(selScreenIdx);

%screenNumberList{selScreenIdx} = [screenNumberList{selScreenIdx} ' *ptbCorgi*'];

resList = Screen('resolutions',selScreenNum);


%Setup the resolution popup
curRes= Screen('resolution',selScreenNum);
allRes  = getAllResolutionStr();
availRes= getUniqueResolutionsStr();

selResIdx = find(strcmp(availRes,resPref)); %Selected Default resolution
selResString = availRes{selResIdx};
curResIdx = find(strcmp(num2str([curRes.width curRes.height],'%dx%d'),availRes));
resLabels=availRes;
resLabels{curResIdx} = [resLabels{curResIdx} ' *Current Active*'];

%resLabels{selResIdx} = [resLabels{selResIdx} ' *ptbCorgi*'];


frameRateList = getUniqueFrameRateStr();
frameRateLabels = frameRateList;
selFrameRateIdx = find(strcmp(frameRateList,num2str(hzPref)));

bitDepthList  = getUniqueBitDepthStr();
bitDepthLabels = bitDepthList;


%Init Resolution Controls. 
yPos = .88;
popWidth = .2;

uicontrol(fh,'Style','text',...
    'String','Video Mode Settings','HorizontalAlignment','center',...
    'Units','normalized','Position',[0 .91 .3 .05]);

screenPopupH = uicontrol(fh,'Style','popupmenu',...
    'String',screenLabelList,'Value',selScreenIdx,...
    'Units','normalized','Position',[.1 yPos popWidth .05],...
    'callback',@changeScreen);

uicontrol(fh,'Style','text','String','Screen Number',...
    'Units','normalized','Position',[0 yPos 0.1 .05])


resPopupH = uicontrol(fh,'Style','popupmenu',...
    'String',resLabels,'Value',selResIdx,...
    'Units','normalized','Position',[.1 yPos-.04 popWidth .05],...
    'callback',@changeResolution);

uicontrol(fh,'Style','text','String','Resolution',...
    'Units','normalized','Position',[0 yPos-.04 0.1 .05])


frameRatePopupH = uicontrol(fh,'Style','popupmenu',...
    'String',frameRateList,'Value',selFrameRateIdx,...
    'Units','normalized','Position',[.1 yPos-.08 popWidth .05],...
    'callback',@changeFrameRate);

uicontrol(fh,'Style','text','String','Refresh',...
    'Units','normalized','Position',[0 yPos-.08 0.1 .05])


bitDepthPopupH = uicontrol(fh,'Style','popupmenu',...
    'String',bitDepthList,...
    'Units','normalized','Position',[.1 yPos-.12 popWidth .05]);

uicontrol(fh,'Style','text','String','Bit Depth',...
    'Units','normalized','Position',[0 yPos-.12 0.1 .05])

uicontrol(fh,'Style','pushbutton',...
    'String','Calibrate Selected Mode',...
    'Units','normalized','Position',[0 yPos-.18 0.3 .05],...
    'callback',@calibrateMode);


calibFileListH = uicontrol(fh,'Style','listbox',...
    'String',{'None'},...
    'Units','normalized','Position',[0.01 yPos-.42 0.29 .15]);

uicontrol(fh,'Style','text','HorizontalAlignment','left',...
'String', 'Calibration Files for Selected Mode',...
    'Units','normalized','Position',[0 yPos-.25 0.3 .035])


uicontrol(fh,'Style','pushbutton',...
    'String','Save Mode Selections as default',...
    'Units','normalized','Position',[0 .2 0.3 .05],...
    'callback',@setPtbCorgiModePref);


updateCalibFileList();


    function chooseBaseDir(varargin)
        
        startpath=which('ptbcorgi.m');
        
        [dirname] = ...
            uigetdir(startpath,'Pick Base Dir');
        
        set(lumStringHandle,'String',fullfile(pathname,filename));
        setpref('ptbCorgi','base',dirname);
        
    end


    function chooseDataDir(varargin)
        
        startpath=which('ptbcorgi.m');
        [dirname] = ...
            uigetdir(startpath,'Pick Data Dir');
        
        set(dataDirHandle,'String',dirname);
        setpref('ptbCorgi','datadir',dirname);
        
    end

    function chooseCalibDir(varargin)
        
        startpath=which('ptbcorgi.m');
        [dirname] = ...
            uigetdir(startpath,'Pick Calibration Dir');
        
        set(calibDirHandle,'String',dirname);
        setpref('ptbCorgi','calibdir',dirname);
        calibDir = dirname;
        calibList = ptbCorgiGetCalibFileList(calibDir);
        updateCalibFileList();
    end

    function selectDevice(hObject,callbackdata)
      
        deviceIdx = get(hObject,'value');
        
        if deviceIdx == 2
            useBitsSharp = true;
        else
            useBitsSharp = false;
        end
        
        
    end
        

    function [screenPref resPref hzPref bitDepthPref]=getPtbCorgiMonPref()        
        
        if ispref('ptbCorgi','resolution');
            res = getpref('ptbCorgi','resolution');
            screenPref = res.screenNum;
            resPref = num2str([res.width res.height],'%dx%d');
            hzPref    = res.hz;
            bitDepthPref = res.pixelSize;            
        else
            screenPref= max(Screen('screens'));
            curRes    = Screen('resolution',screenPref);
            resPref   = num2str([curRes.width curRes.height],'%dx%d');
            hzPref    = curRes.hz;
            bitDepthPref = curRes.pixelSize;
%             screenPref= [];
%             resPref   = '';
%             hzPref    = [];
%             bitDepthPref = [];
        end
        
        
    end

    function changeComputerName(varargin)
        computerName = get(nameTextBoxHandle,'string');
    end

 

    %Build video mode structure from selection.
    function res = getSelVideoModeStruct()
        [scan] = sscanf(selResString,'%dx%d');
        res.width = scan(1);
        res.height = scan(2);
        
        bitDepthSelIdx = get(bitDepthPopupH,'value');
        res.pixelSize = str2double(bitDepthList(bitDepthSelIdx));
        
        frameRateSelIdx = get(frameRatePopupH,'value');
        res.hz = str2double(frameRateList(frameRateSelIdx));
        res.screenNum = selScreenNum;
    end

    function allRes= getAllResolutionStr()

        resList = Screen('resolutions',selScreenNum);

        %Dense bit that creates a 2 column matrix with the unique resolutions
        allResolutions = [resList(:).width; resList(:).height]'; %Concat width and height
        allRes = strtrim(cellstr(num2str(allResolutions,'%dx%d'))); %Format string
        

    end

    function uniqueRes= getUniqueResolutionsStr()
        allResolutions = getAllResolutionStr();
        uniqueRes= unique(allResolutions);%Sort and remove duplicates        
    end

    
    function uniqueFrameRate = getUniqueFrameRateStr()
        
        matchingResIdx = strcmp(availRes{selResIdx},allRes);
        uniqueHz = flipud(unique([resList(matchingResIdx).hz]','sorted','rows'));
        uniqueFrameRate = strtrim(cellstr(num2str(uniqueHz)));
    end

    function uniqueBitDepth = getUniqueBitDepthStr()
        
        matchingResIdx = strcmp(availRes{selResIdx},allRes);
        
        selHz = str2num(frameRateList{selFrameRateIdx});
        
        matchingFrameRateIdx = [ resList(:).hz]==selHz;
        matchingIdx = matchingResIdx(:) & matchingFrameRateIdx(:);

        uniqueBitDepth=flipud(unique([resList(matchingIdx).pixelSize]','sorted','rows'));
        uniqueBitDepth=strtrim(cellstr(num2str(uniqueBitDepth)));
    end


    function changeScreen(varargin)
        
        selScreenIdx = get(screenPopupH,'value');
        selScreenNum = screenHandleList(selScreenIdx);
        
        
        %Setup the resolution popup
        curRes= Screen('resolution',selScreenNum);
        allRes  = getAllResolutionStr();
        availRes= getUniqueResolutionsStr();
        
        curResIdx = find(strcmp(num2str([curRes.width curRes.height],'%dx%d'),availRes));
        selResIdx = curResIdx;%find(strcmp(availRes,resPref)); %Selected Default resolution
        selResString = availRes{selResIdx};
        resLabels=availRes;
        resLabels{curResIdx} = [resLabels{curResIdx} ' *Current Active*'];
        
        %resLabels{selResIdx} = [resLabels{selResIdx} ' *ptbCorgi*'];
        set(resPopupH,'string',resLabels,'value',selResIdx)

        changeResolution();
        
        
        
        
    end


    function changeResolution(varargin)
        
        selResIdx = get(resPopupH,'value');%What resolution was selected
        selResString = availRes{selResIdx};
        
        frameRateList = getUniqueFrameRateStr();
        frameRateLabels = frameRateList;
        
        set(frameRatePopupH,'string',frameRateLabels);
        changeFrameRate();
        
    end

    function changeFrameRate(hObject,callbackdata)
        
        selFrameRateIdx = get(frameRatePopupH,'value');
        
        bitDepthList  = getUniqueBitDepthStr();
        bitDepthLabels = bitDepthList;
        
        set(bitDepthPopupH,'string',bitDepthLabels);        
        selBitDepthIdx = get(bitDepthPopupH,'value');
        
        updateCalibFileList();
    end
   
    function calibrateMode(hObject,callbackdata)
        
        res = getSelVideoModeStruct();
        res.useBitsSharp = useBitsSharp;
        calibrateDisplay(res);
        calibList = ptbCorgiGetCalibFileList(calibDir);
        updateCalibFileList();
    end

    function updateCalibFileList(hObject,callbackdata)
        
        modeString = generateModeString(getSelVideoModeStruct());
        calibListIdx = [];
        if ~isempty(calibList)
            calibListIdx = find( strcmp({calibList(:).modeString},modeString));
        end
        
        availCalibFiles = {'None'};
        set(calibFileListH,'value',1);
        if ~isempty(calibListIdx)
            availCalibFiles = calibList(calibListIdx).filenames;
            availCalibFiles = {'None', availCalibFiles{:}};
            
        end
        
        set(calibFileListH,'string',availCalibFiles);
        
    end

    function modeString=generateModeString(res)
                
        modeString = [num2str(res.width) 'x' num2str(res.height) ...
            '_' num2str(res.hz) 'Hz_' num2str(res.pixelSize) 'bpp'];

        
    end

    function calibrationFile = getSelectedCalibrationFile()
        
        
        calibSelected = get(calibFileListH,'value');
        fileList = get(calibFileListH,'string');
        calibrationFile = fileList{calibSelected};
        
        if strcmp('calibrationFile','none')
            calibrationFile = [];
        end
        
    end


    function setPtbCorgiModePref(varargin)
        

        res = getSelVideoModeStruct();
        setpref('ptbCorgi','resolution',res);
        calibrationFile = getSelectedCalibrationFile();
        setpref('ptbCorgi','calibrationFile',calibrationFile);
        
        setpref('ptbCorgi','useBitsSharp',useBitsSharp);

        if useBitsSharp
            deviceIdx = 2;
            deviceList = {'None','Bits Sharp *ptbCorgi*'};
            validateBitsVisible='on';
            set( devicePopupH,'value',deviceIdx,'string',deviceList);
        end

        
    end


end
