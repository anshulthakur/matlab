classdef Stream < handle
    %STREAM A Packet Stream instance associated that generates packets
    %according to a given distribution.
    
    properties
        time;
        lambda;
        class;
        distribution;
        streamPacket = cell(1,1);
        lastArrival = 0;
    end
    
    methods
        function obj = Stream(time, lambda, class)
            obj.time = time; %Not utilizing for now
            obj.lambda = lambda;
            obj.class = class;
            obj.distribution = 'Poisson';
            obj.lastArrival = 0;
        end
        
        function packet = getPendingPacket(obj, time)
            if(~isa(obj.streamPacket{end}, 'Packet'))
                obj.lastArrival = obj.lastArrival + ...
                                    (-(1/obj.lambda) * log(rand(1))*1000);
                % Create a packet
                obj.streamPacket{end} = Packet(obj.lastArrival, 0);
            end
            
            %Now check if packet must actually have been generated?
            if (obj.streamPacket{end}.birth_time < time)
                   packet = obj.streamPacket{end};
                   obj.streamPacket{end} = cell(1,1);
            else
                packet = -1;
            end
        end
    end
    
end

