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
        packetLength = 0;
    end
    
    methods
        function obj = Stream(props)
            obj.time = props.GenerationTime * 1000;
            obj.lambda = props.lambda;
            obj.class = props.class;
            obj.distribution = props.StreamType;
            obj.lastArrival = 0;
            obj.packetLength = props.packetLength;
        end
        
        function packet = getPendingPacket(obj, time)
            if(time < obj.time) %Check if packet must be generated?
                if(~isa(obj.streamPacket{end}, 'Packet'))
                    obj.lastArrival = obj.lastArrival + ...
                                        (-(1/obj.lambda) * log(rand(1))*1000);
                    % Create a packet
                    obj.streamPacket{end} = Packet(obj.lastArrival, obj.packetLength);
                end

                %Now check if packet must actually have been generated?
                if (obj.streamPacket{end}.birth_time < time)
                       packet = obj.streamPacket{end};
                       obj.streamPacket{end} = cell(1,1);
                else
                    packet = -1;
                end
            else
                fprintf('\nStream terminated.');
                packet = -1;
            end
        end
    end
    
end

