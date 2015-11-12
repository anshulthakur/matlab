classdef Packet < handle
    %Packet A Packet (Job) to be handled in queues and servers
    
    properties
        birth_time;
        state;                  %   waiting=0; served = 1
        class;
        length;
        
        last_wait_start;
        
        last_service_start;
        finish_time;
        
        hop_count;
        
        wait_times;
        delivered = 1; %Reached end node, or lost in blocking?
    end
    
    properties(Dependent=true)
        age_in_wait;
        age_in_service;       
        age_in_network;
    end
    
    events
       deletePacket; 
    end
    
    methods
        function obj = Packet(time, length)
            %% 
            % Creates a packet object whose flow can be simulated in the topology.
            % The packet object keeps track of its own history in terms of
            % the number of hops it has traversed, waiting times and at
            % each hop, packet lifetime, time spent in service, time spent
            % in waiting queues.
            %
            % Input Parameters:
            %   Time: Time of creations (scheduler time)
            %   Length: Length of packet.
            
            if(nargin==0)
                obj.length = ceil(rand(1)*10);
            else
                obj.length = length;
                if(obj.length ==0)
                    %choose random value
                    obj.length = ceil(rand(1)*10);
                else
                    obj.length = length;
                end
            end
            
            obj.birth_time = time;
            obj.state = -1;
            obj.class = 0;
            
            obj.hop_count = 0;
            
            obj.last_wait_start = -1;
            obj.wait_times = [];
            
        end
                
        function age = get.age_in_wait(obj)
            %% 
            % Get time spent in waiting in queues
            current_time = SimScheduler.getScheduler().getTime();
            age = current_time - obj.last_wait_start; %TODO
        end
        
        function age = get.age_in_service(obj)
            %% 
            % Get time spent in being served.
            current_time = SimScheduler.getScheduler().getTime();
            age = current_time - obj.last_service_start; %TODO
        end
        
        function age = get.age_in_network(obj)
            %% 
            % Get age of the packet in the network.
            current_time = SimScheduler.getScheduler().getTime();
            age = current_time - round(obj.birth_time);
        end
        
        function destroy(obj, exception)
            %% 
            % Packet object destructor
            % The packet may be destroyed under normal drop/delivery, or exception.
            % A normal packet drop or delivery must set the exception to 0,
            % signifying that no exception occured. A value of 1 implies
            % the packet was dropped abnormally (input queue full).
            obj.delivered = ~exception;
            notify(obj, 'deletePacket');
            clear obj;
        end
    end
    
end

