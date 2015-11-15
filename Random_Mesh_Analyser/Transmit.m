classdef Transmit < BaseQueue & BaseEntity
    %Transmit Transmits a packet by a rule on the connected nodes
    
    properties
        neighbours;
        policy;
        buffer;
        commutator;
        absorption;
        forward = 0 % 0: randomized; 1: balanced
    end
    
    methods
        function obj = Transmit(num_servers, absorption, forwarding_policy)            
            obj.buffer = BaseQueue(num_servers);
            if(isa(absorption,'char'))
                obj.absorption = rand(1);
            else
                obj.absorption = absorption;
            end
            if(strcmp(forwarding_policy,'random'))
                obj.forward = 0;
            else
                obj.forward = 1;
            end
        end
        
        function transmit(obj)
           if(obj.buffer.NumElements > 0)
               current_time = SimScheduler.getScheduler().getTime();
               %fprintf('\n[%d][System %d]',current_time, obj.id);
               %dequeue and transmit
               packet = obj.buffer.remove();
               if(~isa(packet,'Packet'))
                   %empty queue
                   fprintf('\n[%d][System %d]Not a packet!',current_time, obj.id);
                   return
               end
               if(obj.absorption == 1 || isempty(obj.neighbours))
                   %drop packet
                   %fprintf('\n[%d][System %d]:Drop packet.',...
                   %         current_time, obj.id);
                   packet.destroy(0);
               else
                   %randmoly select next destination
                   egress = datasample(obj.commutator, 1);
                   if(obj.absorption > 0)
                       if(egress ~= 1)
                           %enqueue in the next system
                           %fprintf('\n[%d][System %d]:Enqueue into System %d',...
                           %             current_time,...
                           %             obj.id, obj.neighbours{egress -1}.system.id);
                           obj.neighbours{egress -1}.system.enqueue(packet);
                       else
                           %drop packet
                           %fprintf('\n[%d][System %d]:Drop packet.',...
                           %         current_time, obj.id);
                           packet.destroy(0);
                       end
                   else %Absorption is 0. Must forward! Array is in order.
                       %fprintf('\n[%d][System %d]:Forward packet to %d',...
                       %             current_time, obj.id, obj.neighbours{egress}.id);
                       obj.neighbours{egress}.system.enqueue(packet);
                   end
               end
           end
        end
        
        function initTx(obj, neighbours)            
            obj.neighbours = neighbours;
            
            %disp(neighbours);
            
            %fprintf('\n[System %d]: Neighbours:',obj.id);
            %for i=1:numel(neighbours)
            %    fprintf(' %d', neighbours{i}.id);
            %end
            
            if(obj.absorption == 0 && ~isempty(neighbours))
                random_dist = rand([1,numel(neighbours)]); %Can't drop.                
            elseif(obj.absorption == 0 && isempty(neighbours))
                %fprintf('\n[System %d]:Sink node',obj.id);
                random_dist = [1]; %No neighbours, so drop only.
            elseif(obj.absorption ==1)
                random_dist = [1]; %Explicit Drop
            else
                if(obj.forward == 0) %randomized forwarding
                    random_dist = rand([1,numel(neighbours)]);
                else %balanced forwarding
                    random_dist = ones(1,numel(neighbours));
                    random_dist = random_dist .* (1/numel(neighbours));
                end
                random_dist = random_dist.*(1-obj.absorption);
                random_dist = [obj.absorption, random_dist];
            end
            obj.policy = random_dist./sum(random_dist); %Probability of sending to each neighbour
            obj.commutator = datasample(1:numel(random_dist),10000,...
                                'Weights', random_dist); %10000 ensures neat probability
        end
        
        function addToBuffer(obj, ~, payload)            
            %fprintf('\n[%d][System %d] Add to Tx Buffer.',...
            %        SimScheduler.getScheduler().getTime(), obj.id);
            obj.buffer.add(payload.data);
            %fprintf('\nAdd to Tx Buffer. Population: %d',obj.buffer.NumElements);
        end
        
        function event_handle = RegisterServiceDone(obj, station)
            %fprintf('\n[%d][System %d] Register Tx Buffer with Servers.',...
            %        SimScheduler.getScheduler().getTime(), obj.id);
            event_handle = addlistener(station, 'serviceDone',...
                @(src, data)obj.addToBuffer(src, data));
        end
    end
    
end

