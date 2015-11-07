classdef Transmit < BaseQueue & BaseEntity
    %Transmit Transmits a packet by a rule on the connected nodes
    
    properties
        neighbours;
        policy;
        buffer;
        commutator;
        drop_policy;
    end
    
    methods
        function obj = Transmit(num_servers)            
            obj.buffer = BaseQueue(num_servers);            
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
               %randmoly select next destination
               egress = datasample(obj.commutator, 1);
               if(obj.drop_policy == 1)
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
                       packet.destroy();
                   end
               else %If we can't drop, then determine if we have neighbours or not.
                   if(isempty(obj.neighbours))
                       %drop packet
                       %fprintf('\n[%d][System %d]:Drop packet.',...
                       %         current_time, obj.id);
                       packet.destroy();
                   else
                       obj.neighbours{egress}.system.enqueue(packet);
                   end
               end
           end
        end
        
        function initTx(obj, neighbours, drop_policy)            
            obj.neighbours = neighbours;
            obj.drop_policy = drop_policy;
            
            %fprintf('\n[System %d]: Drop Policy: %d, Neighbours:',obj.id, obj.drop_policy);
            %disp(neighbours);
            
            if(drop_policy == 0 && ~isempty(neighbours))
                random_dist = rand([1,numel(neighbours)]); %Can't drop.
                
            elseif(drop_policy == 0 && isempty(neighbours))
                %fprintf('\n[System %d]:Sink node',obj.id);
                random_dist = [1]; %No neighbours, so drop only.
            else
                random_dist = rand([1,numel(neighbours)+1]); %Can drop too, so, add 1
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

