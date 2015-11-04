classdef (ConstructOnLoad) EventData < event.EventData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data;
    end
    
    methods
        function obj = EventData(data)
            obj.data = data;
        end
    end
    
end

