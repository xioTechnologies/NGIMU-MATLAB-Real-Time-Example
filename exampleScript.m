clc
clear
close all;

%% Open connection

try
    fclose(instrfindall); % ensure the socket is closed after previous run
catch
end

udpObject = openConnection(8000); % this port must match the remote port in the device settings

%% Receive loop

runPeriod = 10; % seconds

figure;
hold on;
title('Accelerometer');
xlabel('Time (s)');
ylabel('Acceleration (g)');
set(gca,'XLim', [0 runPeriod]);
set(gca,'YLim', [-2 2]);
set(gca,'YGrid', 'on');
xAxisData = line(nan, nan, 'Color',[1 0 0]); % no data yet
yAxisData = line(nan, nan, 'Color',[0 1 0]);
zAxisData = line(nan, nan, 'Color',[0 0 1]);

firstTimestamp = 0;

startTime = now;

while true

    % Exit loop after set period of time
    if second(now - startTime) >= runPeriod
        break;
    end

    % Read OSC messages
    oscMessages = readOscMessages(udpObject);

    % Do nothing if no OSC messages received
    if isempty(oscMessages)
        continue;
    end

    % Store first timestamp to use as offset
    if firstTimestamp == 0
        firstTimestamp = oscMessages(1).timestamp;
    end

    % Process OSC messages
    for oscMessagesIndex = 1:length(oscMessages)
        oscMessage = oscMessages(oscMessagesIndex);

        % Filter by OSC address
        % See user manual for complete list of OSC addresses and arguments
        switch oscMessage.oscAddress
            case '/sensors'
                offsetTimestamp = oscMessage.timestamp - firstTimestamp;
                set(xAxisData, ...
                    'XData', [get(xAxisData, 'XData') offsetTimestamp], ...
                    'YData', [get(xAxisData, 'YData') oscMessage.arguments{4}]); % 4th argument is a accelerometer x axis
                set(yAxisData, ...
                    'XData', [get(yAxisData, 'XData') offsetTimestamp], ...
                    'YData', [get(yAxisData, 'YData') oscMessage.arguments{5}]); % 5th argument is a accelerometer y axis
                set(zAxisData, ...
                    'XData', [get(zAxisData, 'XData') offsetTimestamp], ...
                    'YData', [get(zAxisData, 'YData') oscMessage.arguments{6}]); % 6th argument is a accelerometer z axis
                drawnow;
            case '/quaternion'
                % TODO
            case '/temperature'
                % TODO
            case '/humidity'
                % TODO
            case '/battery'
                % TODO
            otherwise
                warning(['Unhandled OSC address received: ' oscMessage.oscAddress]);
        end
    end
end

%% Close connection

closeConnection(udpObject);
