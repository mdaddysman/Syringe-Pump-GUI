function singleinjection()
rh.fh = figure('Name','Single Syringe Pump Control','NumberTitle','off', ...
    'Resize','off','Position',[50 50 300 300],'MenuBar','none','ToolBar','none');

%get com port strings
coms = instrhwinfo('serial');
comstrings = [{''};coms.AvailableSerialPorts];

rh.cpsh = uicontrol('Style','popup','String',comstrings,'Position',[5 270 100 25],'FontSize',10);
rh.ocph = uicontrol('Style','pushbutton','String','Open','Position',[107 270 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8]);
rh.ccph = uicontrol('Style','pushbutton','String','Close','Position',[170 270 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8],'Enable','off');
rh.stph = uicontrol('Style','togglebutton','String','Screen','Position',[233 270 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8],'Enable','off','Value',1);

rh.pth = uicontrol('Style','text','String','Pump Output: ', ...
    'Position',[5 240 290 25],'FontSize',10,'HorizontalAlignment','left');


rh.trth = uicontrol('Style','text','String',['Time Remaining: ' num2str(0,'%02d') ':' num2str(0,'%04.1f')], ...
    'Position',[5 60 290 20],'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');
rh.sitb = uicontrol('Style','togglebutton','String','Start Injection','Position',[50 5 200 50], ...
    'BackgroundColor',[0.8,0.8,0.8],'FontSize',12,'FontWeight','bold','Enable','off','Callback',{@InjectOnOff});

rh.timer = timer('ExecutionMode','fixedRate','Period',0.1,'TimerFcn',{@UpdateWindow,rh});
start(rh.timer);
set(rh.ocph,'Callback',{@OpenCOM_Callback,rh,comstrings});
set(rh.ccph,'Callback',{@CloseCOM_Callback,rh});
set(rh.stph,'Callback',{@ToggleScreen_Callback});
set(rh.fh,'CloseRequestFcn',{@CloseGUI,rh});

end

function UpdateWindow(~,~,rh)
global pumpobj
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
    WritePort(pumpobj,'ver');
end

end

function CloseCOM_Callback(src,~,rh)
global pumpobj

ClosePort(pumpobj);
set(rh.ocph,'Enable','on');
set(src,'Enable','off');
set(rh.stph,'Enable','off','Value',1);


end

function InjectOnOff(src,~)
value = get(src,'Value');

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
        fclose(obj);
        delete(obj);
    end
end
end