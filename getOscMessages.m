function oscMessages = getOscMessages(charArray)
	oscMessages = processOscPacket(charArray, NaN, []);
end

function oscMessages = processOscPacket(charArray, timestamp, oscMessages)
    switch charArray(1)

        % OSC contents is an OSC message
        case '/'
            oscMessage = processOscMessage(charArray);
            if isnan(timestamp) == false
                oscMessage.timestamp = timestamp;
            end
            oscMessages = [oscMessages; oscMessage];

        % OSC contents is an OSC bundle
        case '#'
            [oscTimeTag, oscContents] = processOscBundle(charArray);
            timestamp = double(oscTimeTag) / 2^32; % convert to seconds
            for oscContentsIndex = 1:length(oscContents)
                oscMessages = processOscPacket(oscContents{oscContentsIndex}, timestamp, oscMessages); % call recursively
            end

        % OSC contents is invalid
        otherwise
            warning('Invalid OSC contents.');
    end
end

function [oscTimeTag, oscContents] = processOscBundle(charArray)

    % Get OSC time tag
    oscTimeTag = typecast(uint8(flip(charArray(9:16))), 'uint64');

    % Get OSC bundle elements
    oscBundleElements = charArray(17:end);

    % Loop through each OSC bundle element
    bundleElementIndex = 1;
    while isempty(oscBundleElements) == false

        % Get OSC bundle element size
        oscBundleElementSize = typecast(uint8(flip(oscBundleElements(1:4))), 'int32');

        % Get OSC contents
        oscContents{bundleElementIndex} = oscBundleElements(5:(oscBundleElementSize + 4));
        bundleElementIndex = bundleElementIndex + 1;
        oscBundleElements = oscBundleElements((oscBundleElementSize + 5):end);
    end
end

function oscMessage = processOscMessage(charArray)

    % Get OSC address
    [oscMessage.oscAddress, remainder] = strtok(charArray, 0);

    % Get OSC type tag string
    [~, remainder] = strtok(remainder, ',');
    remainder = remainder(2:end); % trim comma from start
    [oscTypeTagString, remainder] = strtok(remainder, 0);

    % Get argument array
    oscTypeTagStringSize = 1 + length(oscTypeTagString); % include comma
    numberOfNullCharacters = 1;
    while mod(oscTypeTagStringSize + numberOfNullCharacters, 4) ~= 0
        numberOfNullCharacters = numberOfNullCharacters + 1;
    end
    argumentsArray = remainder((1 + numberOfNullCharacters):end);

    % Parse each argument
    for oscTypeTagStringIndex = 1:length(oscTypeTagString)
        switch oscTypeTagString(oscTypeTagStringIndex)
            case 'i'
                int32 = typecast(uint8(flip(argumentsArray(1:4))), 'int32');
                argumentsArray = argumentsArray(5:end);
                oscMessage.arguments{oscTypeTagStringIndex} = int32;
            case 'f'
                float32 = typecast(uint8(flip(argumentsArray(1:4))), 'single');
                argumentsArray = argumentsArray(5:end);
                oscMessage.arguments{oscTypeTagStringIndex} = float32;
            case 's'
                [string, argumentsArray] = strtok(argumentsArray, 0);
                oscMessage.arguments{oscTypeTagStringIndex} = string;
                numberOfNullCharacters = 1;
                while mod(length(string) + numberOfNullCharacters, 4) ~= 0
                    numberOfNullCharacters = numberOfNullCharacters + 1;
                end
                argumentsArray = argumentsArray((length(string) + numberOfNullCharacters):end);
            case 'b'
                blobSize = typecast(uint8(flip(argumentsArray(1:4))), 'int32');
                oscMessage.arguments{oscTypeTagStringIndex} = argumentsArray(5:(4 + blobSize));
				numberOfNullCharacters = 0;
                while mod(blobSize + numberOfNullCharacters, 4) ~= 0
                    numberOfNullCharacters = numberOfNullCharacters + 1;
                end				
                argumentsArray = argumentsArray((5 + blobSize + numberOfNullCharacters):end);
            case 'T'
                oscMessage.arguments{oscTypeTagStringIndex} = true;
            case 'F'
                oscMessage.arguments{oscTypeTagStringIndex} = false;
            otherwise
                warning('Argument type not supported.');
                break;
        end
    end
end
