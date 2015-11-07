classdef BaseQueue < handle
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
    
    methods
        function obj = BaseQueue(capacity)
            if(nargin==0) %Inifinite buffer
                obj.elements = cell(1, 10);
                obj.capacity = 0;
            else
                obj.elements = cell(1,capacity);
                obj.capacity = capacity;
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
                    error('Queue is full');
                end
                obj.elements{obj.nextInsert} = el;
                obj.nextInsert = obj.nextInsert + 1;               
            end
        end
        
        function el = remove( obj )
            if obj.isEmpty()
                %error( 'Queue is empty' );
                fprintf('\nQueue empty');
                el = -1;
                return;
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
        end
        
        function tf = isEmpty( obj )
            tf = ( obj.nextRemove >= obj.nextInsert );
        end
        
        function n = get.NumElements( obj )
            n = obj.nextInsert - obj.nextRemove;
        end
    end
    
end

