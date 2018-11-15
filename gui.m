function varargout = gui(varargin)
    % GUI MATLAB code for gui.fig
    %      GUI, by itself, creates a new GUI or raises the existing
    %      singleton*.
    %
    %      H = GUI returns the handle to a new GUI or the handle to
    %      the existing singleton*.
    %
    %      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in GUI.M with the given input arguments.
    %
    %      GUI('Property','Value',...) creates a new GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before gui_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help gui

    % Last Modified by GUIDE v2.5 14-Nov-2018 17:31:09

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @gui_OpeningFcn, ...
                       'gui_OutputFcn',  @gui_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to gui (see VARARGIN)

    % Choose default command line output for gui
    handles.output = hObject;

    handles.gyroscopePlot = sensorPlot(handles.gyroscopeAxes, 500, 'Gyroscope');
    handles.accelerometerPlot = sensorPlot(handles.accelerometerAxes, 500, 'Accelerometer');
    handles.magnetometerPlot = sensorPlot(handles.magnetometerAxes, 500, 'Magnetometer');
    handles.quaternionPlot = quaternionPlot(handles.quaternionAxes);

    handles.timer = timer('Period', 0.02, 'ExecutionMode', 'fixedRate');
    handles.timer.TimerFcn = {@timer_Callback, handles};
    start(handles.timer);

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes gui wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
end


% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end



function udpPortEditText_Callback(hObject, eventdata, handles)
    % hObject    handle to udpPortEditText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of udpPortEditText as text
    %        str2double(get(hObject,'String')) returns contents of udpPortEditText as a double
end


% --- Executes during object creation, after setting all properties.
function udpPortEditText_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to udpPortEditText (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% --- Executes on button press in openPushButton.
function openPushButton_Callback(hObject, eventdata, handles)
    % hObject    handle to openPushButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Close all preivous UDP sockets
    try
        fclose(instrfindall);
    catch
    end

    % Open UDP socket
    try
        udpPort = str2double(get(handles.udpPortEditText, 'String'));
        handles.udp = udp('255.255.255.255',  'Localport', udpPort,  'InputBufferSize', 4096);
        handles.udp.datagramReceivedFcn = {@processData_Callback, handles};
        fopen(handles.udp);
    catch exception
        errordlg(exception.message);
    end

    % Update handles
    guidata(hObject, handles);
end


% --- Executes on button press in closePushButton.
function closePushButton_Callback(hObject, eventdata, handles)
    % hObject    handle to closePushButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    try
        fclose(instrfindall);
    catch
    end
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    try
        fclose(instrfindall);
    catch
    end
    stop(handles.timer);
    delete(handles.timer);

    % Hint: delete(hObject) closes the figure
    delete(hObject);
end


function processData_Callback(hObject, eventdata, handles)

    % Do nothing if socket closed
    if strcmp(handles.udp.Status, 'closed')
        return;
    end

    % Discad input buffer if overrun
    if handles.udp.BytesAvailable == handles.udp.InputBufferSize
        flushinput(handles.udp);
        warning('UDP input buffer overrun.');
        return;
    end

    % Read UDP packet
    charArray = char(fread(handles.udp))';

    % Prcess OSC packet
    oscMessages = getOscMessages(charArray);

    % Process OSC messages
    for oscMessagesIndex = 1:length(oscMessages)
        oscMessage = oscMessages(oscMessagesIndex);

        % Filter by OSC address
        switch oscMessage.oscAddress
            case '/sensors'
                handles.gyroscopePlot.updateData([oscMessage.arguments{1}, oscMessage.arguments{2}, oscMessage.arguments{3}]);
                handles.accelerometerPlot.updateData([oscMessage.arguments{4}, oscMessage.arguments{5}, oscMessage.arguments{6}]);
                handles.magnetometerPlot.updateData([oscMessage.arguments{7}, oscMessage.arguments{8}, oscMessage.arguments{9}]);
            case '/quaternion'
                quaternionAxes = [oscMessage.arguments{1}, oscMessage.arguments{2}, oscMessage.arguments{3}, oscMessage.arguments{4}];
                handles.quaternionPlot.updateData(quaternionAxes);
            case '/temperature'
                % This message is currnelty unhandled
            case '/humidity'
                % This message is currnelty unhandled
            case '/battery'
                % This message is currnelty unhandled
            otherwise
                warning(['Unhandled OSC address received: ' oscMessage.oscAddress]);
        end
    end
end


function timer_Callback(hObject, eventdata, handles)
    handles.gyroscopePlot.updatePlot();
    handles.accelerometerPlot.updatePlot();
    handles.magnetometerPlot.updatePlot();
    handles.quaternionPlot.updatePlot();
	drawnow;
end
