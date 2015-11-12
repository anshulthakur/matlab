classdef Service < handle & BaseEntity
    %Service A representation of a server station having some service time
    % distribution
    % Currently, only Exponential server is supported.
    % A server whose service depends only on the packet length could also
    % be implemented with little changes, where, on fixing the packet
    % length, the server becomes deterministic.
    % Current exponential server does not take into account the packet
    % length. There is another variant possible where the packet length
    % varies exponentially while the rate of server is fixed at 1 unit of
    % packet length per tick. That would also be an exponential server
    % (which becomes a Deterministic server when packet length is fixed).
        
    properties
        distribution;
        type;
        classes;    % Classes of traffic supported
        rate;       % Per class rate
        variance;   % Per class variance
        
        service_times;
        
        system_id;
    end
    properties %(Access = private)
       busy_period;
       idle_period;
       is_busy;
       current_job;
       
    end
    
    events
       serviceDone; 
    end
    
    methods
        function service = Service(id, classes, rates, variances, service_type)
            %Service Initializes an instance of server with requested
            %service parameters
            error_msg = 'Error creating Service class';
            msg_id = 'Service:badInputs';
            exception = MException(msg_id,error_msg);
            
            if(~isa(id, 'double') || (isa(id, 'double') && id <= 0))
                throw(exception)
            else
                service.id = id;
            end
            
            if(~isa(classes, 'double') || (isa(classes, 'double') && numel(classes) == 0))
                throw(exception)
            else
                service.classes = classes;
            end
            
            if(isa(rates, 'double') && (numel(service.classes) ~= numel(rates)))
                throw(exception)
            else
                service.rate = rates;
            end
            
            if((~isa(service_type, 'char')))
                throw(exception)
            else
                if(strcmp(service_type,'exponential'))
                    service.type = service_type;
                    service.distribution = 'exponential'; %Modify
                else
                    throw(exception); %Not identified
                end
            end
            
            
            if((~isa(variances, 'double')) || ...
                    (numel(variances)==0 && ~strcmp('exponential',service.type)))
                % Variances must be provided if model is not exponential
                throw(exception)
            else
                service.variance = variances;
            end
            
            service.current_job = [service.current_job, cell(1,1)];
            service.idle_period = 0;
            service.busy_period = 0;
            
            service.is_busy = false;
        end
        
        function feed(obj, packet)
            %%
            % Feed the packet into the server.
            % This method computes the service time of the packet 
            
            current_time = SimScheduler.getScheduler().getTime();
            
            %Time to completion
            packet.last_service_start = current_time;
            packet.hop_count = packet.hop_count+1;
            %packet.finish_time = packet.last_service_start + packet.length;
            packet.finish_time = current_time +(( -(1/obj.rate) * log(rand(1)))*1000);
            obj.current_job = cell(1,1);            
            obj.current_job{end} = packet;
            
            %fprintf('\n[%d][System %d]:Added packet of length %d to server id:%d',...
            %              current_time, obj.system_id, obj.current_job{end}.length, obj.id);
            %fprintf('\n[%d][System %d]:Start Time: %d\t Finish Time: %d\t Serve Time: %d',...
            %    current_time, obj.system_id, ...
            %    obj.current_job{end}.last_service_start, ...
            %    obj.current_job{end}.finish_time,...
            %    packet.finish_time - packet.last_service_start);
            
            obj.is_busy = true;
            obj.service_times = [obj.service_times, round(packet.finish_time - packet.last_service_start)];
        end
        
        function serve(obj)
            %%
            % Checks if a packet is in service at time instant. If service
            % time has expired, the job is marked as complete and a
            % serviceDone signal is raised. If the station is idle the idle
            % time counters are incremented.
            
            current_time = SimScheduler.getScheduler().getTime();

            %fprintf('\n Server: %d\tTime: %d',obj.id, current_time);
            if(~obj.is_busy)
                %fprintf('\nIdle');
                obj.idle_period = obj.idle_period+1;
                return;
            end
            
            %fprintf('\nCurrent Job Stats:\nStart Time: %d\t Finish Time: %d',...
            %    obj.current_job{end}.last_service_start, ...
            %                        obj.current_job{end}.finish_time);
            %fprintf('\n[%d][System %d]', current_time, obj.system_id);            
            
            if obj.current_job{end}.finish_time <= current_time
                obj.busy_period = obj.busy_period + ...
                    obj.current_job{end}.age_in_service;
                %fprintf('\n[%d][System %d]:Finished service on server id:%d',...
                %                       current_time, obj.system_id, obj.id);
                obj.is_busy = false;
                obj.current_job{end}.state = 0;
                notify(obj, 'serviceDone', EventData(obj.current_job{end}));                
            end
        end
        
        function serviceTime = getDistribution(obj)
            serviceTime = obj.service_times;
        end
    end
    
end

