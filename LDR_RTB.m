%Author: Zack Weinstein
%Theory: Break sections of FOV into groups (NE, N, NW, W, etc). Only pay 
%attention to the group immediately in front of the bot on the next step.
%If there is a wall in any of these spaces (which can be determined using
%the sum command) mark this as impermeable and check a one of the 2 
%adjacent directions to the opposite of the current direction. Keep
%checking until you find a permeable direction.
WALL=-1;
SPACE=0;
UNEXPLORED=2;
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
end

pos=mem.pos;
map=mem.map;
LV=local_view;
LV([1 end], [1 end])=UNEXPLORED;

if step_num==0
    %set up map and pos on first step
    map=[ones(2,29)*WALL;  ones(19,2)*WALL, ones(19,25)*UNEXPLORED, ones(19,2)*WALL;  ones(2,29)*WALL];
    map([(12-2):(12+2)],[(12-2):(12+2)])=LV;
    pos=STARTING_POS;

    i=5;
    while i==5 %picks a random direction (can't be 5 because it won't go anywhere)
        i=randi(9,1);
    end
    direction=8;

    %build slams
    %bottom, left, right, top
    slams={ones(1,29)*17,ones(25,1)*5,ones(25,1)*21,ones(1,29)*5};

    %HEATMAP:
    %
    %All positive numbers:gradient to a charger
    %Walls: -1
    %Unexplored: -2
%     heatmap=[ones(2,29)*WALL;  ones(19,2)*WALL, ones(19,25)*-2, ones(19,2)*WALL;  ones(2,29)*WALL];
    


    %We set up the goal register which is just saying our goal is to get back
    %to the start
    GoalRegister=int8(zeros(23,29));

    %Find other goals
    
    startingChargerPos=[mod(find(LV==1),length(LV)),ceil(find(LV==1)/length(LV))];
    startingChargerPos=startingChargerPos+[12-2,12-2];
    GoalRegister(startingChargerPos(1)-1,startingChargerPos(2))=1;
    GoalRegister(startingChargerPos(1)+1,startingChargerPos(2))=1;
    GoalRegister(startingChargerPos(1),startingChargerPos(2)-1)=1;
    GoalRegister(startingChargerPos(1),startingChargerPos(2)+1)=1;
end

%finalize
direction=find_permeable(direction, LV);

%Return to base will be determined by running the A* Algorthim on every
%step until length of the path is equaled to the steps remaining minus 1
%In this version of the algorthim path through blocks are zeros and
%non-pass through blocks are ones.
%The input matrixies must have int 8 entries for proformance reasons
scanZone=int8(map~=0); %every where inside the region we scanned will be either a 1 if its a wall/charger or a zero if its empty, and everywhere outside the reason we scanned is a 1. This to make sure the path doesn't take us through walls.

%Connecting Distance just determines how far of a jump we can make on each
%step which is always a 1, which connects us to 8 adjcent cells
Connecting_Distance=1;

%Calling ASTARPATH to generate the OptimalPath
OptimalPath=[];
if(step_num>0)&&~(GoalRegister(pos(2),pos(1)))
OptimalPath=ASTARPATH(pos(1),pos(2),scanZone,GoalRegister,Connecting_Distance);
end
%OptimalPath is gives you all the coordinates from start to goal in reverse order
%Therefore when returning to base we can take the 2nd to last minus the
%last one to get the delta x and delta y of the next step we need to make
%inorder to get back to the charger on the very last move.
disp(length(OptimalPath)+1>100-step_num);
if(length(OptimalPath)>100-step_num)
    directionMatrix=[7 8 9; 4 5 6; 1 2 3];
    OptimalPath2=rot90(OptimalPath,2);
    delta=[OptimalPath2(2,1)-OptimalPath2(1,1),OptimalPath2(2,2)-OptimalPath2(1,2)];
    decodeToDirection=delta+[2,2];
    direction=directionMatrix(decodeToDirection(2),decodeToDirection(1));
end

if(step_num>=95)&&GoalRegister(pos(2),pos(1))
    direction=5;
end
map=updateMap(pos,map,LV); %update map before you change position TO SEE MAP LOAD IN memorySpace THEN DO image((map(:,:)+1)*128)

slams=updateSlams(pos,local_view,slams);
pos=deadReckon(pos,direction);


%save
mem.map=map;
mem.pos=pos;
command=direction;

mem.slams=slams;


% Functions

function output=find_permeable(direction, LV) %this function uses recursion to figure out if the bot can pass in the direction it's going on to the next step. if it can then it continues in the same direction, if not it picks from the 2 directions adjacent to it on the opposite side
    % FOV Groups
    LV=LV.*(LV~=1)+(LV==1)*-1;
    NE=LV(2,4);
    N =LV([1 2],3);
    NW=LV(2,2);
    W = LV(3,[1 2]);
    SW=LV(4,2);
    S = LV([4 5],3);
    SE=LV(4,4);
    E = LV(3,[4 5]);
    groups={SW; S; SE; W; [3 3]; E; NW; N; NE}; %These are the only block groups that the bot will ever look at, the index number of the block corresponds to if you placed a keypad on the 3x3 section around the bot in local view, this means that cell with a given index number will be in the direction number of the next step
    if sum(sum(groups{direction},"omitnan")) >= 0 %Checks if the block it's heading towards is not a wall
        output=direction;
    else %If it is a wall then select possible new directions based on the current direction
        switch direction
            case 1
                bounceDirection=[6,8];
            case 2
                bounceDirection=[7,9];
            case 3
                bounceDirection=[4,8];
            case 4
                bounceDirection=[3,9];
            case 5 %just in case a 5 somehow is picked
                bounceDirection=[1,2,3,4,6,7,8,9];
                disp("what?");
            case 6
                bounceDirection=[1,7];
            case 7
                bounceDirection=[2,6];
            case 8
                bounceDirection=[1,3];
            case 9
                bounceDirection=[2,4];
        end
        direction=bounceDirection(randi(length(bounceDirection),1));
        output=find_permeable(direction, LV); %then it runs the function again new direction it generated, to check if it can pass through the block in its new direction.
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
            pos_new=pos+[0,0];
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

function updateGoalRegister()
end

function output=updateSlams(pos,LV,slams) %do this before updating position
%bottom, left, right, top
%everything is in the reference frame of LV
    bottom=slams{1}((pos(1)-2):(pos(1)+2)); %how far down you can go looks for the least y-valued one
    left=slams{2}((pos(2)-2):(pos(2)+2)); %how far left you can go, looks for the most x-valued one
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
    if(sum(left==0)>0)
        disp("ZERO FOUND");
    end
    slams{1}((pos(1)-2):(pos(1)+2))=bottom;
    slams{2}((pos(2)-2):(pos(2)+2))=left;
    slams{3}((pos(2)-2):(pos(2)+2))=right;
    slams{4}((pos(1)-2):(pos(1)+2))=top;
    output=slams;
end

function OptimalPath=ASTARPATH(StartX,StartY,MAP,GoalRegister,Connecting_Distance)
%Version 1.0
% By Einar Ueland 2nd of May, 2016
%FINDING ASTAR PATH IN AN OCCUPANCY GRID
%nNeighboor=3;
% Preallocation of Matrices
[Height,Width]=size(MAP); %Height and width of matrix
GScore=zeros(Height,Width);           %Matrix keeping track of G-scores 
FScore=single(inf(Height,Width));     %Matrix keeping track of F-scores (only open list) 
Hn=single(zeros(Height,Width));       %Heuristic matrix
OpenMAT=int8(zeros(Height,Width));    %Matrix keeping of open grid cells
ClosedMAT=int8(zeros(Height,Width));  %Matrix keeping track of closed grid cells
ClosedMAT(MAP==1)=1;                  %Adding object-cells to closed matrix
ParentX=int16(zeros(Height,Width));   %Matrix keeping track of X position of parent
ParentY=int16(zeros(Height,Width));   %Matrix keeping track of Y position of parent
%%% Setting up matrices representing neighboors to be investigated
NeighboorCheck=ones(2*Connecting_Distance+1);
Dummy=2*Connecting_Distance+2;
Mid=Connecting_Distance+1;
for i=1:Connecting_Distance-1
NeighboorCheck(i,i)=0;
NeighboorCheck(Dummy-i,i)=0;
NeighboorCheck(i,Dummy-i)=0;
NeighboorCheck(Dummy-i,Dummy-i)=0;
NeighboorCheck(Mid,i)=0;
NeighboorCheck(Mid,Dummy-i)=0;
NeighboorCheck(i,Mid)=0;
NeighboorCheck(Dummy-i,Mid)=0;
end
NeighboorCheck(Mid,Mid)=0;
[row, col]=find(NeighboorCheck==1);
Neighboors=[row col]-(Connecting_Distance+1);
N_Neighboors=size(col,1);
%%% End of setting up matrices representing neighboors to be investigated
%%%%%%%%% Creating Heuristic-matrix based on distance to nearest  goal node
[col, row]=find(GoalRegister==1);
RegisteredGoals=[row col];
Nodesfound=size(RegisteredGoals,1);
for k=1:size(GoalRegister,1)
    for j=1:size(GoalRegister,2)
        if MAP(k,j)==0
            Mat=RegisteredGoals-(repmat([j k],(Nodesfound),1));
            Distance=(min(sqrt(sum(abs(Mat).^2,2))));
            Hn(k,j)=Distance;
        end
    end
end
%End of creating Heuristic-matrix. 
%Note: If Hn values is set to zero the method will reduce to the Dijkstras method.
%Initializign start node with FValue and opening first node.
FScore(StartY,StartX)=Hn(StartY,StartX);         
OpenMAT(StartY,StartX)=1;   
while 1==1 %Code will break when path found or when no path exist
    MINopenFSCORE=min(min(FScore));
    if MINopenFSCORE==inf;
    %Failuere!
    OptimalPath=[inf];
    RECONSTRUCTPATH=0;
     break
    end
    [CurrentY,CurrentX]=find(FScore==MINopenFSCORE);
    CurrentY=CurrentY(1);
    CurrentX=CurrentX(1);
    if GoalRegister(CurrentY,CurrentX)==1
    %GOAL!!
        RECONSTRUCTPATH=1;
        break
    end
    
  %Remobing node from OpenList to ClosedList  
    OpenMAT(CurrentY,CurrentX)=0;
    FScore(CurrentY,CurrentX)=inf;
    ClosedMAT(CurrentY,CurrentX)=1;
    for p=1:N_Neighboors
        i=Neighboors(p,1); %Y
        j=Neighboors(p,2); %X
        if CurrentY+i<1||CurrentY+i>Height||CurrentX+j<1||CurrentX+j>Width
            continue
        end
        Flag=1;
        if(ClosedMAT(CurrentY+i,CurrentX+j)==0) %Neiboor is open;
            if (abs(i)>1||abs(j)>1);   
                % Need to check that the path does not pass an object
                JumpCells=2*max(abs(i),abs(j))-1;
                for K=1:JumpCells;
                    YPOS=round(K*i/JumpCells);
                    XPOS=round(K*j/JumpCells);
            
                    if (MAP(CurrentY+YPOS,CurrentX+XPOS)==1)
                        Flag=0;
                    end
                end
            end
             %End of  checking that the path does not pass an object
            if Flag==1;           
                tentative_gScore = GScore(CurrentY,CurrentX) + sqrt(i^2+j^2);
                if OpenMAT(CurrentY+i,CurrentX+j)==0
                    OpenMAT(CurrentY+i,CurrentX+j)=1;                    
                elseif tentative_gScore >= GScore(CurrentY+i,CurrentX+j)
                    continue
                end
                ParentX(CurrentY+i,CurrentX+j)=CurrentX;
                ParentY(CurrentY+i,CurrentX+j)=CurrentY;
                GScore(CurrentY+i,CurrentX+j)=tentative_gScore;
                FScore(CurrentY+i,CurrentX+j)= tentative_gScore+Hn(CurrentY+i,CurrentX+j);
            end
        end
    end
end
k=2;
if RECONSTRUCTPATH
    OptimalPath(1,:)=[CurrentY CurrentX];
    while RECONSTRUCTPATH
        CurrentXDummy=ParentX(CurrentY,CurrentX);
        CurrentY=ParentY(CurrentY,CurrentX);
        CurrentX=CurrentXDummy;
        OptimalPath(k,:)=[CurrentY CurrentX];
        k=k+1;
        if (((CurrentX== StartX)) &&(CurrentY==StartY))
            break
        end
    end
end
end