classdef quaternionPlot < handle
    properties
        teaPot;
        size;
        teaPotPlot;
        xAxisPlot;
        yAxisPlot;
        zAxisPlot;
        quaternion;
    end
    methods
        function obj = quaternionPlot(axesHandle)

            % Draw teapot
            obj.teaPot = pcdownsample(pcread('teapot.ply'), 'gridAverage', 0.2);
            obj.size = max(max(abs(obj.teaPot.Location)));
            obj.teaPotPlot = plot3(axesHandle, ...
                                   obj.teaPot.Location(:, 1), obj.teaPot.Location(:, 2), obj.teaPot.Location(:, 3), ...
                                   '.', 'Color', [0.8, 0.8, 0.8]);

         	% Draw Earth axes
            hold(axesHandle, 'on');
            red = [0.6350, 0.0780, 0.1840];
            green = [0.4660, 0.6740, 0.1880];
            blue = [0, 0.4470, 0.7410];
            plot3(axesHandle, [0, obj.size], [0, 0], [0, 0], '--', 'Color', red);
            plot3(axesHandle, [0, 0], [0, obj.size], [0, 0], '--', 'Color', green);
            plot3(axesHandle, [0, 0], [0, 0], [0, obj.size], '--', 'Color', blue);

            % Draw sensor axes
            obj.xAxisPlot = plot3(axesHandle, [0, obj.size], [0, 0], [0, 0], 'Color', red);
            obj.yAxisPlot = plot3(axesHandle, [0, 0], [0, obj.size], [0, 0], 'Color', green);
            obj.zAxisPlot = plot3(axesHandle, [0, 0], [0, 0], [0, obj.size], 'Color', blue);
            hold(axesHandle, 'off');

            % Format axes
            set(axesHandle, 'XGrid', 'on');
            set(axesHandle, 'YGrid', 'on');
            set(axesHandle, 'ZGrid', 'on');
            set(axesHandle,'XTickLabel',[]);
            set(axesHandle,'YTickLabel',[]);
            set(axesHandle,'ZTickLabel',[]);
            set(axesHandle, 'xlim', [-obj.size, obj.size]);
            set(axesHandle, 'ylim', [-obj.size, obj.size]);
            set(axesHandle, 'zlim', [-obj.size, obj.size]);
            set(get(axesHandle, 'title'), 'string', 'Quaternion');

            % Initial quaternion vlaue
            obj.quaternion = [1 0 0 0];
        end
        function obj = updateData(obj, quaternion)
            obj.quaternion = quaternion;
        end
        function obj = updatePlot(obj)

            % Convert quaternion to rotation matrix
            %R = quat2rotm(obj.quaternion);
            q = obj.quaternion;
            R = eye(3);
            R(1,1) = 2.*q(1).^2-1+2.*q(2).^2;
            R(1,2) = 2.*(q(2).*q(3)+q(1).*q(4));
            R(1,3) = 2.*(q(2).*q(4)-q(1).*q(3));
            R(2,1) = 2.*(q(2).*q(3)-q(1).*q(4));
            R(2,2) = 2.*q(1).^2-1+2.*q(3).^2;
            R(2,3) = 2.*(q(3).*q(4)+q(1).*q(2));
            R(3,1) = 2.*(q(2).*q(4)+q(1).*q(3));
            R(3,2) = 2.*(q(3).*q(4)-q(1).*q(2));
            R(3,3) = 2.*q(1).^2-1+2.*q(4).^2;

            % Udate teapot
            rotatedTeaPot = pctransform(obj.teaPot, affine3d(rotm2tform(R)));
            set(obj.teaPotPlot, 'XData', rotatedTeaPot.Location(:, 1));
            set(obj.teaPotPlot, 'YData', rotatedTeaPot.Location(:, 2));
            set(obj.teaPotPlot, 'ZData', rotatedTeaPot.Location(:, 3));

            % Udate sensor X axis
            scaledR = obj.size * R;
            set(obj.xAxisPlot, 'XData', [0, scaledR(1, 1)]);
            set(obj.xAxisPlot, 'YData', [0, scaledR(1, 2)]);
            set(obj.xAxisPlot, 'ZData', [0, scaledR(1, 3)]);

            % Udate sensor Y axis
            set(obj.yAxisPlot, 'XData', [0, scaledR(2, 1)]);
            set(obj.yAxisPlot, 'YData', [0, scaledR(2, 2)]);
            set(obj.yAxisPlot, 'ZData', [0, scaledR(2, 3)]);

            % Udate sensor Z axis
            set(obj.zAxisPlot, 'XData', [0, scaledR(3, 1)]);
            set(obj.zAxisPlot, 'YData', [0, scaledR(3, 2)]);
            set(obj.zAxisPlot, 'ZData', [0, scaledR(3, 3)]);
        end
    end
end
