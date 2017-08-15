function singleinjection()
fh = figure('Name','Single Syringe Pump Control','NumberTitle','off', ...
    'Resize','off','Position',[50 50 300 300],'MenuBar','none','ToolBar','none');

%get com port strings
coms = instrhwinfo('serial');
comstrings = [{''};coms.AvailableSerialPorts];

cpsh = uicontrol('Style','popup','String',comstrings,'Position',[5 270 100 25],'FontSize',10);
ocph = uicontrol('Style','pushbutton','String','Open','Position',[107 270 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8]);
ccph = uicontrol('Style','pushbutton','String','Close','Position',[170 270 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8],'Enable','off');
stph = uicontrol('Style','togglebutton','String','Screen','Position',[233 270 60 25],'FontSize',10, ...
    'BackgroundColor',[0.8,0.8,0.8],'Enable','off','Value',1);

pth = uicontrol('Style','text','String','Pump Output: ', ...
    'Position',[5 240 290 25],'FontSize',10,'HorizontalAlignment','left');


trth = uicontrol('Style','text','String',['Time Remaining: ' num2str(0,'%02d') ':' num2str(0,'%05.2f')], ...
    'Position',[5 60 290 20],'FontSize',10,'FontWeight','bold','HorizontalAlignment','center');
sitb = uicontrol('Style','togglebutton','String','Start Injection','Position',[50 5 200 50], ...
    'BackgroundColor',[0.8,0.8,0.8],'FontSize',12,'FontWeight','bold','Enable','off','Callback',{@InjectOnOff});

    
end

function InjectOnOff(src,~)
value = get(src,'Value');

end