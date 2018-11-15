classdef sensorPlot < handle
    properties
        axesHandle;
        xData;
        yData;
        zData;
        xPlot;
        yPlot;
        zPlot;
    end
    methods
        function obj = sensorPlot(axesHandle, samplesPerPlot, titleString)
            obj.axesHandle = axesHandle;
            obj.xData = NaN(samplesPerPlot, 1);
            obj.yData = NaN(samplesPerPlot, 1);
            obj.zData = NaN(samplesPerPlot, 1);
            hold(obj.axesHandle, 'on');
            plot(obj.axesHandle, [0 samplesPerPlot], [0 0], 'k:');
            obj.xPlot = plot(obj.axesHandle, obj.xData, 'Color', [0.6350, 0.0780, 0.1840]);
            obj.yPlot = plot(obj.axesHandle, obj.yData, 'Color', [0.4660, 0.6740, 0.1880]);
            obj.zPlot = plot(obj.axesHandle, obj.zData, 'Color', [     0, 0.4470, 0.7410]);
            hold(obj.axesHandle, 'off');
            set(obj.axesHandle, 'xtick', []);
            set(obj.axesHandle, 'YGrid', 'on');
            set(obj.axesHandle, 'YMinorGrid', 'on');
            set(get(obj.axesHandle, 'title'), 'string', titleString);
        end
        function obj = updateData(obj, xyxValue)
            obj.xData = [obj.xData(2:end); xyxValue(1)];
            obj.yData = [obj.yData(2:end); xyxValue(2)];
            obj.zData = [obj.zData(2:end); xyxValue(3)];
        end
        function obj = updatePlot(obj)
            set(obj.xPlot, 'YData', obj.xData);
            set(obj.yPlot, 'YData', obj.yData);
            set(obj.zPlot, 'YData', obj.zData);
            limit = max(abs([obj.xData; obj.yData; obj.zData]));
            if ~isnan(limit)
                set(obj.axesHandle, 'ylim', [-limit, limit]);
            end
        end
    end
end
