classdef Scheduler < handle & BaseEntity
    %Scheduler Schedules the packet for processing in one of the servers
    
    properties
        policy;
        servers;
        free_servers;
        queue;
        free_server_count;
        
        num_dropped;
        num_admitted;
    end
    
%    properties (Dependent=true)
%       free_server_count; 
%    end
    
    methods
        function cnt = get.free_server_count(obj)
            cnt = length(obj.free_servers);
        end
        
        function obj = Scheduler(stations, queue)
            obj.policy = 0;
            obj.servers = stations;
            obj.free_servers = stations;
            obj.queue = queue;
            obj.free_server_count = length(obj.free_servers);
            
        end
        
        function routeToServer(obj, queue)
            %current_time = SimScheduler.getScheduler().getTime();
            obj.num_admitted = obj.num_admitted +1;
            
            %dequeue from object and assign to a server
            if(obj.free_server_count > 0)
                packet = queue.remove(); %Will raise a dequeue event
                %Select a server based on policy
                %for now, choose the next available server
                obj.free_servers{1}.feed(packet);
                %fprintf('\nFeed to server %d at time %d', ...
                %                    obj.free_servers{1}.id, current_time);
                obj.free_servers = obj.free_servers(2:end);
                obj.free_server_count = obj.free_server_count -1;
            end            
        end
        
        function dropPacket(obj, queue)
            obj.num_dropped = obj.num_dropped +1;
        end
        
        function obj = JoinQueue(self, queue)
            obj(1) = addlistener(queue, 'Enqueue',...
                @(src, ~)self.routeToServer(src));
            obj(2) = addlistener(queue, 'Drop',...
                @(src, ~)self.dropPacket(src));
        end
        
        function runScheduler(obj, station, ~)     
            %current_time = SimScheduler.getScheduler().getTime();
            
            %Dequeue packet if any
            %fprintf('\nRun scheduler of node at Time %d', current_time);
            
            packet = obj.queue.remove(); %Will raise a dequeue event
            if(isa(packet, 'Packet'))
                station.feed(packet);
            else
                station.current_job{end} = cell(1,1);
                obj.free_servers = [obj.free_servers, cell(1,1)];
                obj.free_servers{end} = station;
            end            
        end
        
        function obj = RegisterServiceDone(self, station)
            obj = addlistener(station, 'serviceDone',...
                @(src, data)self.runScheduler(src, data));
        end
        
        function p = getBlockingProbability(obj)
            p = obj.num_dropped/(obj.num_dropped + obj.num_admitted);
        end
    end
    
end

