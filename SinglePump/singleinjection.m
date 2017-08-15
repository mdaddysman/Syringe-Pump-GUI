function singleinjection()
global pumprun
rh.fh = figure('Name','Single Syringe Pump Control','NumberTitle','off', ...
    'Resize','off','Position',[50 50 300 265],'MenuBar','none','ToolBar','none');

pumprun = false;

%settings for min, max, and default infuse rates in uL/min
minrate = 1; maxrate = 1000; defaultrate = 500;
minorrate = 1; majorrate = 10; 
ratestep = [minorrate/(maxrate-minrate), majorrate/(maxrate-minrate)];

mintime = 1; maxtime = 3600; defaulttime = 90;
minortime = 1; majortime = 10; 
timestep = [minortime/(maxtime-mintime), majortime/(maxtime-mintime)];

%get com port strings
coms = instrhwinfo('serial');
comstrings = [{''};coms.AvailableSerialPorts];

rh.cpsh = uicontrol('Style','popup','String',comstrings,'Position',[5 235 100 25],'FontSize',10);
rh.ocph = uicontrol('Style','pushbutton','String','Open','Position',[107 235 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8]);
rh.ccph = uicontrol('Style','pushbutton','String','Close','Position',[170 235 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8],'Enable','off');
rh.stph = uicontrol('Style','togglebutton','String','Screen','Position',[233 235 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8],'Enable','off','Value',1);

rh.pth = uicontrol('Style','text','String','Pump Output: ', ...
    'Position',[5 200 290 25],'FontSize',10,'HorizontalAlignment','left');

rh.irth = uicontrol('Style','text','String',['Infuse Rate: ' num2str(defaultrate) ' uL/min'], ...
    'FontWeight','bold','Position',[5 170 290 25],'FontSize',10,'HorizontalAlignment','left');
rh.irsh = uicontrol('Style','slider','Position',[5 145 290 25],...
    'Value',defaultrate,'Min',minrate,'Max',maxrate,'Enable','off','SliderStep',ratestep);

rh.itth = uicontrol('Style','text','String',['Infuse Time: ' num2str(defaulttime) ' s'], ...
    'FontWeight','bold','Position',[5 115 290 25],'FontSize',10,'HorizontalAlignment','left');
rh.itsh = uicontrol('Style','slider','Position',[5 90 290 25],...
    'Value',defaulttime,'Min',mintime,'Max',maxtime,'Enable','off','SliderStep',timestep);


rh.trth = uicontrol('Style','text','String',['Time Remaining: ' num2str(0,'%02d') ':' num2str(0,'%04.1f')], ...
    'Position',[5 60 290 20],'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');
rh.sitb = uicontrol('Style','togglebutton','String','Start Injection','Position',[50 5 200 50], ...
    'BackgroundColor',[0.8,0.8,0.8],'FontSize',12,'FontWeight','bold','Enable','off');

rh.timer = timer('ExecutionMode','fixedRate','Period',0.1,'TimerFcn',{@UpdateWindow,rh});
start(rh.timer);
set(rh.fh,'CloseRequestFcn',{@CloseGUI,rh});
set(rh.ocph,'Callback',{@OpenCOM_Callback,rh,comstrings});
set(rh.ccph,'Callback',{@CloseCOM_Callback,rh});
set(rh.stph,'Callback',{@ToggleScreen_Callback});
set(rh.irsh,'Callback',{@InfuseRate_Callback,rh});
set(rh.itsh,'Callback',{@InfuseTime_Callback,rh});
set(rh.sitb,'Callback',{@InjectOnOff,rh});

end

function InfuseTime_Callback(src,~,rh)
value = get(src,'Value');
value = round(value);
set(src,'Value',value);

set(rh.itth,'String',['Infuse Time: ' num2str(value) ' s']);

end

function InfuseRate_Callback(src,~,rh)
global pumpobj
value = get(src,'Value');
value = round(value);
set(src,'Value',value);

set(rh.irth,'String',['Infuse Rate: ' num2str(value) ' uL/min']);

WritePort(pumpobj,['irate ' num2str(value) ' ul/min']); 

end

function UpdateWindow(~,~,rh)
global pumpobj pumprun
if(ishghandle(rh.fh))
    %check buffer and write if new text is there
    if isa(pumpobj,'serial')
        if isvalid(pumpobj)
            if pumpobj.BytesAvailable > 0
                r = fscanf(pumpobj,'%c',pumpobj.BytesAvailable);
                r = strrep(strrep(r,newline,' '),char(13),' '); %remove CR & LF
                set(rh.pth,'String',['Pump Output: ' r]);
            end
        end
    end
    
    if pumprun
        time = toc; %current run time
        ltime = get(rh.itsh,'Value') - time;
        if ltime <= 0
            ltime = 0;
            StopInfusion(rh);
        end
        lmin = floor(ltime/60);
        lsec = ltime - 60*lmin;
        set(rh.trth,'String',['Time Remaining: ' num2str(lmin,'%02d') ':' num2str(lsec,'%04.1f')]);        
    end
    
end
end

function StopInfusion(rh)
global pumpobj pumprun
WritePort(pumpobj,'stop');

set(rh.irsh,'Enable','on');
set(rh.itsh,'Enable','on');
set(rh.ccph,'Enable','on');
set(rh.stph,'Enable','on');
set(rh.sitb,'String','Start Injection','ForegroundColor','k','Value',0);
pumprun = false;
end

function InjectOnOff(src,~,rh)
global pumpobj pumprun
value = get(src,'Value');

if value == 1 %start the pump
    set(rh.irsh,'Enable','off');
    set(rh.itsh,'Enable','off');
    set(rh.ccph,'Enable','off');
    set(rh.stph,'Enable','off');    
    set(src,'String','Stop Injection','ForegroundColor','r');
    irate = get(rh.irsh,'Value');
    WritePort(pumpobj,['irate ' num2str(irate) ' ul/min']);
    WritePort(pumpobj,'irun');
    tic
    pumprun = true;
else %stop the pump
    StopInfusion(rh);
end

end

function ToggleScreen_Callback(src,~)
global pumpobj
value = get(src,'Value');

if value == 0 %turn the screen off
    WritePort(pumpobj,'dim 0');
else %otherwise turn it on 
    WritePort(pumpobj,'dim 100');
end

end

function OpenCOM_Callback(src,~,rh,comstrings)
global pumpobj

value = get(rh.cpsh,'Value');

if value > 1
    port = comstrings{value};
    pumpobj = OpenPort(port);
    set(src,'Enable','off');
    set(rh.ccph,'Enable','on');
    set(rh.stph,'Enable','on');
    set(rh.irsh,'Enable','on');
    set(rh.itsh,'Enable','on');
    set(rh.sitb,'Enable','on');
    WritePort(pumpobj,'ver');
    irate = get(rh.irsh,'Value');
    WritePort(pumpobj,['irate ' num2str(irate) ' ul/min']);
end

end

function CloseCOM_Callback(src,~,rh)
global pumpobj

ClosePort(pumpobj);
set(rh.ocph,'Enable','on');
set(src,'Enable','off');
set(rh.stph,'Enable','off','Value',1);
set(rh.irsh,'Enable','off');
set(rh.itsh,'Enable','off');
set(rh.sitb,'Enable','off');


end

function CloseGUI(src,~,rh)
global pumpobj
choice = questdlg('Do you want to exit?','Confirm Exit','Yes','No','No');
switch choice
    case 'Yes'
        ClosePort(pumpobj);
        stop(rh.timer);
        delete(rh.timer);
        delete(src);
    case 'No'
        return
end
end

function WritePort(obj,string)
fprintf(obj,'%s\n',string');
end

function obj = OpenPort(port)
obj = serial(port,'BaudRate',115200,'Parity','none','DataBits',8,'StopBits',2,'FlowControl','none','Terminator',{'','CR/LF'}); 
fopen(obj);
end

function ClosePort(obj)
if isa(obj,'serial')
    if isvalid(obj)
        %send stop command and turn on screen
        WritePort(obj,'dim 100');
        WritePort(obj,'stop');
        fclose(obj);
        delete(obj);
    end
end
end