classdef GraphNode
    %This is a class for a single node
    %   Bruh we still need to use A* to update the visible field
    
    properties
        parent;
        col;
        row;
        gCost;
        start;
        goal;
        solid;
        checked;
    end
    
    methods
        function obj = GraphNode(rowin,colin)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.row=rowin;
            obj.col=colin;
        end
        
    end
end

