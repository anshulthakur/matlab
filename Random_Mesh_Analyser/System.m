classdef System < handle & BaseEntity
    %SYSTEM Represents a System to be installed on a node
    % A single representational entity that houses a queueing system.
    % It comprises of an Input Queue, A Job scheduler, Service Station(s)
    % and a transmit buffer. A traffic stream may be assiciated with each
    % station which acts like a locally generated packet stream (example -
    % A BTS catering to an area) along with traffic coming from other peers
    % in the topology.
    % It provides wrapper methods to get access to its internal statistics
    % and member public properties.
    
    properties
        queue;
        stations;
        scheduler;
        transmitter;
        streams = {};
    end
    
    properties (Transient)
        queue_handle;
        server_handles;
        transmitter_handles;
    end
    
    methods
        function obj = System(id, props)
            obj.id = id;
            obj.queue = Queue(props.QueueSize);
            obj.queue.id = id;
            
            obj.stations = cell(1,length(props.ServiceRates));
            for i=1:length(obj.stations)
                %Initialize server
                obj.stations{i} = Service(i, props);
                obj.stations{i}.system_id = obj.id;
            end
            obj.scheduler = Scheduler(obj.stations, obj.queue);
            obj.transmitter = Transmit(length(props.ServiceRates), ...
                                        props.AbsorptionProbability,...
                                        props.Forwarding);
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
        
        function q_len = getQueueLength(obj)
            q_len = obj.queue.NumElements;
        end
        
        function numbers = getCustomerCount(obj)
            numbers = obj.queue.NumElements;
            for i=1:length(obj.stations)
                if (obj.stations{i}.is_busy)
                    numbers = numbers +1;
                end
            end
        end
        
        function serviceTime = getDistribution(obj)
            serviceTime = [];
            for i=1:length(obj.stations)
                serviceTime = [serviceTime, obj.stations{i}.getDistribution()];
            end
        end
        
        function utilization = getUtilization(obj)
            utilization = zeros(1,length(obj.stations));
            for i=1:length(obj.stations)
                utilization(i) = 1 - (obj.stations{i}.idle_period/SimScheduler.getScheduler().getTime());
            end
        end
        
        function p = getBlockingProbabilities(obj)
            p = obj.scheduler.getBlockingProbability();
        end
    end
    
end

