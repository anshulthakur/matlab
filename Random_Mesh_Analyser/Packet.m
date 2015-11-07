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
            current_time = SimScheduler.getScheduler().getTime();
            age = current_time - obj.last_wait_start; %TODO
        end
        
        function age = get.age_in_service(obj)
            current_time = SimScheduler.getScheduler().getTime();
            age = current_time - obj.last_service_start; %TODO
        end
        
        function age = get.age_in_network(obj)
            current_time = SimScheduler.getScheduler().getTime();
            age = current_time - round(obj.birth_time);
        end
        
        function destroy(obj, exception)            
            obj.delivered = ~exception;
            notify(obj, 'deletePacket');
            clear obj;
        end
    end
    
end

