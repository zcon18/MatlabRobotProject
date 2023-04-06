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
    slams={ones(1,29)*17,ones(25,1)*5,ones(25,1)*21,ones(1,29)*5};
end

%finalize
[direction,state]=find_unexplored(direction, LV,state,map,pos);
map=updateMap(pos,map,LV); %update map before you change position TO SEE MAP LOAD IN memorySpace THEN DO image((map(:,:)+1)*128)
slams=updateSlams(pos,LV,slams);
pos=deadReckon(pos,direction);


%save
mem.state=state;
mem.map=map;
mem.pos=pos;

command=direction;


mem.slams=slams;

% Functions

function [output,output_state]=find_unexplored(direction, LV, state, map,pos) %this function uses recursion to figure out if the bot can pass in the direction it's going on to the next step. if it can then it continues in the same direction, if not it picks from the 2 directions adjacent to it on the opposite side
    if(state==1)
        scannedBlock=0;
        scannedMap=0;
        switch direction
            case 2
                scannedBlock=LV([4 5],3);
                mappedBlock=map(pos(2)+3,pos(1));
            case 4
                scannedBlock=LV(3,[1 2]);
                mappedBlock=map(pos(2),pos(1)-3);
            case 6
                scannedBlock=LV(3,[4 5]);
                mappedBlock=map(pos(2),pos(1)+3);
            case 8
                scannedBlock=LV([1 2],3);
                mappedBlock=map(pos(2)-3,pos(1));
        end
        if (sum(scannedBlock)<0)
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
                scannedBlock=LV([4 5],3);
                mappedBlock=map(pos(2)+3,pos(1));
            case 4
                scannedBlock=LV(3,[1 2]);
                mappedBlock=map(pos(2),pos(1)-3);
            case 6
                scannedBlock=LV(3,[4 5]);
                mappedBlock=map(pos(2),pos(1)+3);
            case 8
                scannedBlock=LV([1 2],3);
                mappedBlock=map(pos(2)-3,pos(1));
        end
        if (sum(scannedBlock)<0)
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
function output=updateSlams(pos,LV,slams) %do this before updating position
%bottom, left, right, top
%everything is in the reference frame of LV
    bottom=slams{1}((pos(1)-2):(pos(1)+2)); %how far down you can go looks for the least y-valued one
    left=slams{2}((pos(2)-2):(pos(2)+2)); %how far left you can go, looks for the most x-valued one
    disp(left);
    right=slams{3}((pos(2)-2):(pos(2)+2)); %how for right you can go, looks for the least x-valued one
    top=slams{4}((pos(1)-2):(pos(1)+2)); %how far up you can go, looks for the most y-valued one
    %keep in mind that the top left cor of LV is at
    %(Y,X):(pos(2)-2,pos(1)-2)
    LV([1 end], [1 end])=0; %by setting its corners to zero it means we just wont update them
    walls=(LV==-1)+(LV==1);
    for i = 1:length(LV) %rows
        for j = 1:length(LV(i,:)) %collumns
            if(walls(i,j)==1)
                y=pos(2)-3+i;
                x=pos(1)-3+j;
                if (y<bottom(j))
                    bottom(j)=y; %get the correct cell, check if its less than the current valued one, if so replace it
                end
                if(x>left(i))
                    left(i)=x;
                end
                if (x<right(i))
                    right(i)=x;
                end
                if (y>top(j))
                    top(j)=y;
                end
            end
        end
    end
    disp(left);
    if(sum(left==0)>0)
        disp("ZERO FOUND");
    end
    slams{1}((pos(1)-2):(pos(1)+2))=bottom;
    slams{2}((pos(2)-2):(pos(2)+2))=left;
    slams{3}((pos(2)-2):(pos(2)+2))=right;
    slams{4}((pos(1)-2):(pos(1)+2))=top;
    output=slams;
end