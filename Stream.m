classdef Stream < handle
    %STREAM A Packet Stream instance associated that generates packets
    %according to a given distribution.
    
    properties
        distribution;
        stream;
    end
    
    methods
        function obj = Stream(time, lambda, class)
            arrival_time = (-(1/lambda) * log(rand(1))*1000);
            while (arrival_time < time)
                obj.distribution = [arrival_time obj.distribution];
                % Create a packet for this instant
                obj.stream = [cell(1,1), obj.stream];
                obj.stream{1} = Packet(arrival_time, 0);
                obj.stream{1}.class = class;
                arrival_time = arrival_time + (((-1/lambda)*log(rand(1)))*1000);
            end
            %fprintf('\nDistribution:\n');
            %disp(obj.distribution)
            %plot(obj.distribution, 1, '.');
        end
        
        function packet = getPendingPacket(obj, time)
            if(~isempty(obj.distribution))
                if(obj.distribution(end) <= time)
                    %pop the packet from queue
                    packet = obj.stream{end};
                    obj.stream = obj.stream(1:end-1);
                    obj.distribution = obj.distribution(1:end-1);
                else
                    packet = -1;
                end
            else
                packet = -1;
            end
        end
    end
    
end

