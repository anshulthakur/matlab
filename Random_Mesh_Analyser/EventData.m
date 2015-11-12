classdef (ConstructOnLoad) EventData < event.EventData
    %EventData Class to pass additional data to Event Listeners on notify.
    
    properties
        data;
    end
    
    methods
        function obj = EventData(data)
            obj.data = data;
        end
    end
    
end

