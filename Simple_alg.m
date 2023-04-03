WALL=-1;
SPACE=0;
UNEXPLORED=1;
STARTING_POS=[12,12];

%Mem needs to be called in both branches
%TODO: CHECK IF map and pos exsit within an existing memorySpace.mat file
%or else code will break
if isfile('memorySpace.mat') %There's a chance the file won't exist so we need to make it just in case
    mem = matfile('memorySpace.mat','Writable',true); % Matfile makes it so we don't have to load a file in each time
else
    disp("memory space file does not exist, creating")
    map=[ones(2,29)*WALL;  ones(19,2)*WALL, ones(19,25)*UNEXPLORED, ones(19,2)*WALL;  ones(2,29)*WALL];
    save("memorySpace.mat",'map');
    mem=matfile('memorySpace.mat','Writable',true);
    mem.pos=STARTING_POS;
    mem.state=1;
end

state=mem.state;
pos=mem.pos;
map=mem.map;
LV=local_view;
LV(isnan(LV))=UNEXPLORED;

if step_num==0
    %set up map and pos on first step
    map=[ones(2,29)*WALL;  ones(19,2)*WALL, ones(19,25)*UNEXPLORED, ones(19,2)*WALL;  ones(2,29)*WALL];
    map([(12-2):(12+2)],[(12-2):(12+2)])=LV;
    pos=STARTING_POS;
    state=1;

    direction=2*randi(4);
end

%finalize
[direction,state]=find_unexplored(direction, LV,state,map,pos);
map=updateMap(pos,map,LV); %update map before you change position TO SEE MAP LOAD IN memorySpace THEN DO image((map(:,:)+1)*128)
pos=deadReckon(pos,direction);


%save
mem.state=state;
mem.map=map;
mem.pos=pos;

command=direction;

% Functions

function [output,output_state]=find_unexplored(direction, LV, state, map,pos) %this function uses recursion to figure out if the bot can pass in the direction it's going on to the next step. if it can then it continues in the same direction, if not it picks from the 2 directions adjacent to it on the opposite side
    if(state==1)
        scannedBlock=0;
        scannedMap=0;
        switch direction
            case 2
                scannedBlock=LV(5,3);
                mappedBlock=map(pos(2)+3,pos(1));
            case 4
                scannedBlock=LV(3,1);
                mappedBlock=map(pos(2),pos(1)-3);
            case 6
                scannedBlock=LV(3,5);
                mappedBlock=map(pos(2),pos(1)+3);
            case 8
                scannedBlock=LV(1,3);
                mappedBlock=map(pos(2)-3,pos(1));
        end
        if (scannedBlock==-1)
            output=10-direction;
            output_state=2;
        else
            output=direction;
            output_state=1;
        end
    elseif (state==2)
        switch direction
            case 2
                direction = 4;
            case 4
                direction = 8;
            case 6
                direction = 2;
            case 8
                direction = 6;
        end
        switch direction
            case 2
                scannedBlock=LV(5,3);
                mappedBlock=map(pos(2)+3,pos(1));
            case 4
                scannedBlock=LV(3,1);
                mappedBlock=map(pos(2),pos(1)-3);
            case 6
                scannedBlock=LV(3,5);
                mappedBlock=map(pos(2),pos(1)+3);
            case 8
                scannedBlock=LV(1,3);
                mappedBlock=map(pos(2)-3,pos(1));
        end
        if (scannedBlock==-1)
            state=1;
            [output,output_state]=find_unexplored(direction, LV, state, map,pos);
        else
            output=direction;
            output_state=1;
        end
    end
end

function output=deadReckon(pos,direction)
    switch direction %even though 9 goes further upwards a greater y vaule correspondes to being lower on the map so 7 to 9 have negative vaules attached
        case 1
            pos_new=pos+[-1,1];
        case 2
            pos_new=pos+[0,1];
        case 3
            pos_new=pos+[1,1];
        case 4
            pos_new=pos+[-1,0];
        case 5
            disp("what?");
        case 6
            pos_new=pos+[1,0];
        case 7
            pos_new=pos+[-1,-1];
        case 8
            pos_new=pos+[0,-1];
        case 9
            pos_new=pos+[1,-1];
    end
    output=pos_new;
end

function output=updateMap(pos, map, LV)
    LV_new=LV;
    LV_new([1 end], [1 end])=0;
    temp=[map(pos(2)-2,pos(1)-2) 0 0 0 map(pos(2)-2,pos(1)+2); 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; map(pos(2)+2,pos(1)-2) 0 0 0 map(pos(2)+2,pos(1)+2)]; %A greater Y corresponds to a lower height therefore the NE and NW corners have lower Y values than SE and SW, also the Y value goes first in arrays
    map([(pos(2)-2):(pos(2)+2)],[(pos(1)-2):(pos(1)+2)])=LV_new+temp;
    output=map;
end