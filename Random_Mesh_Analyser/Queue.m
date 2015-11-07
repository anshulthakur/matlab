classdef Queue < handle & BaseEntity
    properties
        capacity; 
    end
    
    properties ( Access = private )
        elements
        nextInsert
        nextRemove
    end

    properties ( Dependent = true )
        NumElements
    end
    
    events
        Enqueue;
        Dequeue;
        Drop;
    end

    methods
        function obj = Queue(capacity)
            current_time = SimScheduler.getScheduler().getTime();
            
            if(nargin==0 || (nargin >0 && capacity==0)) %Inifinite buffer
                fprintf('\n[%d]Initialize Queue with infinite buffer capacity.', current_time);
                obj.elements = cell(1, 10);
                obj.capacity = 0;
            else
                obj.elements = cell(1,capacity);
                obj.capacity = capacity;
                fprintf('\n[%d]Initialize Queue with buffer capacity of %d.',current_time, obj.capacity );
            end
            obj.nextInsert = 1;
            obj.nextRemove = 1;
        end
        
        function add( obj, el )
            if(obj.capacity == 0)
                if obj.nextInsert == length( obj.elements )
                    obj.elements = [ obj.elements, cell( 1, length( obj.elements ) ) ];
                end
                obj.elements{obj.nextInsert} = el;
                obj.nextInsert = obj.nextInsert + 1;
            else
                if((obj.nextInsert - obj.nextRemove) == obj.capacity)
                    %Queue is full. Reject!
                    notify(obj, 'Drop');
                    %error('Queue is full');
                    return;
                end
                obj.elements{obj.nextInsert} = el;
                obj.nextInsert = obj.nextInsert + 1;
            end
            
            current_time = SimScheduler.getScheduler().getTime();
            
            el.last_wait_start = current_time;
            el.state = 0;
            % Allow some server to get the packet            
            %fprintf('\n[%d][System %d]:Enqueue', current_time, obj.id);
            notify(obj, 'Enqueue');            
        end
        
        function el = remove( obj )
            if obj.isEmpty()
                %error( 'Queue is empty' );
                %fprintf( '\nQueue is empty' );
                el = -1;
                return
            end
            el = obj.elements{ obj.nextRemove };
            obj.elements{ obj.nextRemove } = [];
            if(obj.capacity ==0)
                obj.nextRemove = obj.nextRemove + 1;
                % Trim "elements"
                if obj.nextRemove > ( length( obj.elements ) / 2 )
                    ntrim = fix( length( obj.elements ) / 2 );
                    obj.elements = obj.elements( (ntrim+1):end );
                    obj.nextInsert = obj.nextInsert - ntrim;
                    obj.nextRemove = obj.nextRemove - ntrim;
                end
            else
                obj.elements = [obj.elements, cell(1,1)];
                obj.elements = obj.elements(obj.nextRemove +1:end);
                obj.nextInsert = obj.nextInsert -1;
            end
            
            %current_time = SimScheduler.getScheduler().getTime();
                        
            el.state = 1;
            el.wait_times = [el.wait_times, ...
                SimScheduler.getScheduler().getTime() - el.last_wait_start];
            
            %fprintf('\n[%d][System %d]:Dequeue', current_time, obj.id );
            notify(obj,'Dequeue');
        end
        
        function tf = isEmpty( obj )
            tf = ( obj.nextRemove >= obj.nextInsert );
        end
        
        function n = get.NumElements( obj )
            n = obj.nextInsert - obj.nextRemove;
        end
    end
end

