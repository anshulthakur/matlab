classdef Service < handle
    %Service A representation of a server having some service time
    % distribution
        
    properties
        distribution;
        type;
        classes;    % Classes of traffic supported
        rate;       % Per class rate
        variance;   % Per class variance
        id;
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
            current_time = SimScheduler.getScheduler().getTime();
            
            %Time to completion
            packet.last_service_start = current_time;
            packet.finish_time = packet.last_service_start + packet.length;
            obj.current_job{end} = packet;
            fprintf('\nAdded packet of length %d to server id:%d at Time %d\n',...
                                                  obj.current_job{end}.length, obj.id, current_time);
            fprintf('Start Time: %d\t Finish Time: %d',...
                obj.current_job{end}.last_service_start, obj.current_job{end}.finish_time);  
            obj.is_busy = true;
        end
        
        function serve(obj)            
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
                                
            if obj.current_job{end}.finish_time == current_time
                obj.busy_period = obj.busy_period + ...
                    obj.current_job{end}.age_in_service;
                fprintf('\nFinished service on server id:%d at Time %d',...
                                                    obj.id, current_time);
                obj.is_busy = false;
                obj.current_job{end}.state = 0;
                notify(obj, 'serviceDone');
                obj.current_job{end} = cell(1,1);
            end
        end
    end
    
end
