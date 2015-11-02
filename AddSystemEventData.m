classdef (ConstructOnLoad) AddSystemEventData < event.EventData
    %ADDSYSTEMEVENT Data passed when new system is added to topology
    
    properties
        system = cell(1,1);
    end
    
    methods
        function obj = AddSystemEventData(sys)            
            obj.system{end} = sys;
            fprintf('\nAdding system %d',obj.system{end}.id);
        end
    end    
end
