classdef System < handle & BaseEntity
    %SYSTEM Represents a System to be installed on a node
    
    properties
        queue;
        stations;
        scheduler;
        transmitter;
        streams;
        
    end
    
    properties (Transient)
        queue_handle;
        server_handles;
        transmitter_handles;
    end
    
    methods
        function obj = System(id,capacity, num_stations, schedule_policy, ...
                                                        rates)
            obj.id = id;
            obj.queue = Queue(capacity);
            obj.queue.id = id;
            
            obj.stations = cell(1,num_stations);
            for i=1:length(obj.stations)
                %Initialize server
                obj.stations{i} = Service(i, 0, rates(i), ...
                                                        [], 'exponential');
                obj.stations{i}.system_id = obj.id;
            end
            obj.scheduler = Scheduler(obj.stations, obj.queue);
            obj.transmitter = Transmit(num_stations);
            obj.transmitter.id = id;
            
            %Attach scheduler to queue
            obj.queue_handle = obj.scheduler.JoinQueue(obj.queue);
            %Attach scheduler and transmitter to servers
            for i=1:length(obj.stations)
                obj.server_handles{i} = ...
                    obj.scheduler.RegisterServiceDone(obj.stations{i});
                obj.transmitter_handles{i} = ...
                    obj.transmitter.RegisterServiceDone(obj.stations{i});
            end
            
        end       
        
        function serve(obj)
            for id=1:length(obj.stations)
                %Initialize server
                obj.stations{id}.serve();
            end            
        end
        
        function enqueue(obj, packet)
            obj.queue.add(packet);
        end
        
        function transmit(obj)
            obj.transmitter.transmit();
        end
        
        function installAdjacencies(obj, neighbours)
            obj.transmitter.initTx(neighbours);
        end
    end
    
end

