
WALL=-1;
SPACE=0;
CHARGING_STATION=1;
UNEXPLORED=2;
STARTING_POS=[12,12];

optibox.bottom=19;
optibox.top=5;
optibox.left=5;
optibox.right=25;

if (step_num==0)
    map=[ones(2,29)*WALL;  ones(19,2)*WALL, ones(19,25)*UNEXPLORED, ones(19,2)*WALL;  ones(2,29)*WALL];
    LV=local_view;
    LV([1 end], [1 end])=UNEXPLORED;
    map([(12-2):(12+2)],[(12-2):(12+2)])=LV;
    pos=STARTING_POS;
    slams={ones(1,29)*17,ones(23,1)*5,ones(23,1)*21,ones(1,29)*5};
    direction=randi(4,1)*2;
    disp("Starting: "+direction);
    [direction,directions]=calculate(pos,direction,map,optibox);
end

%Do the code

map=updateMap(pos,map,LV); %update map before you change position TO SEE MAP LOAD IN memorySpace THEN DO image((map(:,:)+1)*128)
[direction,directions]=navigate(pos,directions,LV,step_num+1,map,optibox)
pos=deadReckon(pos,direction);
command=direction;

%Functions

function [output, directions]=navigate(pos, directions, LV, step, map, optibox)
    LV=LV.*(LV~=1)+(LV==1)*-1; %make charges walls too
    NE=LV(2,4);
    N =LV([1 2],3);
    NW=LV(2,2);
    W = LV(3,[1 2]);
    SW=LV(4,2);
    S = LV([4 5],3);
    SE=LV(4,4);
    E = LV(3,[4 5]);
    groups={SW; S; SE; W; [3 3]; E; NW; N; NE}; %These are the only block groups that the bot will ever look at, the index number of the block corresponds to if you placed a keypad on the 3x3 section around the bot in local view, this means that cell with a given index number will be in the direction number of the next step
    disp("Step: "+step)
    disp("Directions: "+directions);
    if sum(sum(groups{directions(step)},"omitnan")) >= 0 %Checks if the block it's heading towards is not a wall
        if(directions(step+1)~=directions(step))
            [output,d]=calculate(pos, directions(step), map, optibox);
            directions=[directions(1:step),d]; %kill current line add new one
        else
            output=directions(step);
            directions=directions;
        end
    else %If it is a wall then select possible new directions based on the current direction
        [output,d]=calculate(pos, directions(step), map, optibox);
        directions=[directions(1:step),d]; %kill current line add new one
    end
end

function [output,newDirections]=calculate(pos, direction, map, optibox)
%Left and right check
    if(direction==2)||(direction==8)
        scoreGrid=zeros(23,29); %This is where all the point estimations go
        pointMap=(map==2); %UNEXPLORED
        walls=(map==-1)+(map==1); %WALL and CHARGING STATION
        for i=pos(1):-1:optibox.left
            if(walls(pos(2),i)==1)
                break;
            end
            pointMap1=pointMap([pos(2)-2:pos(2)+2],[i-2:pos(1)+2]); %odd number pointMaps are very different from even number pointMaps
            pointMap1([1 end], [1 end])=0; %gets rid of corners
            sum1=sum(sum(pointMap1));
            topBound=optibox.top; %topBound makes the scan go all the way up and down until it hits a wall
            for j=pos(2):-1:optibox.top
                if(walls(j,i)==1)
                    topBound=j-1;
                end
            end
            bottomBound=optibox.bottom;
            for j=pos(2):optibox.bottom
                if(walls(j,i)==1)
                    bottomBound=j+1;
                end
            end
            scoreGrid([topBound:bottomBound],[i])=sum1;
            pointMap2=pointMap;
            pointMap2([pos(2)-2:pos(2)+2],[i-2:pos(1)+2])=0;
            for j=topBound:pos(2)
                pointMap3=pointMap2([j-2:pos(2)+2],[i-2:i+2]);
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(j,i)=scoreGrid(j,i)+sum(sum(pointMap3));
            end
            for j=pos(2):bottomBound
                pointMap3=pointMap2([pos(2)-2:j+2],[i-2:i+2]);
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(j,i)=scoreGrid(j,i)+sum(sum(pointMap3));
            end
        end
        for i=pos(1):optibox.right
            if(walls(pos(2),i)==1)
                break;
            end
            pointMap1=pointMap([pos(2)-2:pos(2)+2],[pos(1)-2:i+2]); %odd number pointMaps are very different from even number pointMaps
            pointMap1([1 end], [1 end])=0; %gets rid of corners
            sum1=sum(sum(pointMap1));
            topBound=optibox.top; %topBound makes the scan go all the way up and down until it hits a wall
            for j=pos(2):-1:optibox.top
                if(walls(j,i)==1)
                    topBound=j-1;
                end
            end
            bottomBound=optibox.bottom;
            for j=pos(2):optibox.bottom
                if(walls(j,i)==1)
                    bottomBound=j+1;
                end
            end
            scoreGrid([topBound:bottomBound],[i])=sum1;
            pointMap2=pointMap;
            pointMap2([pos(2)-2:pos(2)+2],[i-2:pos(1)+2])=0;
            for j=topBound:pos(2)
                pointMap3=pointMap2([j-2:pos(2)+2],[i-2:i+2]);
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(j,i)=scoreGrid(j,i)+sum(sum(pointMap3));
            end
            for j=pos(2):bottomBound
                pointMap3=pointMap2([pos(2)-2:j+2],[i-2:i+2]);
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(j,i)=scoreGrid(j,i)+sum(sum(pointMap3));
            end
        end
        scoreGrid
        sumMax=max(max(scoreGrid));
        x_max=find(max(scoreGrid)==sumMax);
        y_max=find(max(scoreGrid,[],2)==sumMax);
        disp(y_max);
        disp(x_max);
        delta=[y_max(1),x_max(1)]-[pos(2),pos(1)];
        disp(delta);
        disp(delta(1,2));
        %We want to go left or right then up or down first
        LRdirectionMatrix=[4 8 6; 4 5 6; 4 2 6];
        direction1=LRdirectionMatrix(delta(1,2)/abs(delta(1,2))+3,delta(1,1)/abs(delta(1,1))+3); %We only care wether or not x is postive or negative
        UPdirectionMatrix=[8 8 8; 4 5 6; 2 2 2];
        direction2=UPdirectionMatrix(delta(1,2)/abs(delta(1,2))+3,delta(1,1)/abs(delta(1,1))+3)
        newDirections=[direction1*abs(delta(1,1)),direction2*abs(delta(1,2))];
        output=newDirections(1);
    end
    if(direction==4)||(direction==6)
        scoreGrid=zeros(23,29);
        pointMap=(map==2); %UNEXPLORED
        walls=(map==-1)+(map==1); %WALL and CHARGING STATION
        for i=pos(2):-1:optibox.top
            if(walls(i,pos(1))==1)
                break;
            end
            pointMap1=pointMap([i-2:pos(2)+2],[pos(1)-2:pos(2)+2]); %odd number pointMaps are very different from even number pointMaps
            pointMap1([1 end], [1 end])=0; %gets rid of corners
            sum1=sum(sum(pointMap1));
            leftBound=optibox.left; %topBound makes the scan go all the way up and down until it hits a wall
            for j=pos(1):-1:optibox.left
                if(walls(i,j)==1)
                    leftBound=j-1;
                end
            end
            rightBound=optibox.right;
            for j=pos(1):optibox.bottom
                if(walls(i,j)==1)
                    rightBound=j+1;
                end
            end
            scoreGrid([i],[leftBound:rightBound])=sum1;
            pointMap2=pointMap;
            pointMap2([i-2:pos(2)+2],[pos(1)-2:pos(1)+2])=0;
            for j=leftBound:pos(1)
                pointMap3=pointMap2([i-2:i+2],[j-2:pos(1)+2]); %%HERE
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(i,j)=scoreGrid(i,j)+sum(sum(pointMap3));
            end
            for j=pos(2):rightBound
                pointMap3=pointMap2([i-2:i+2],[pos(1)-2:j+2]);
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(i,j)=scoreGrid(i,j)+sum(sum(pointMap3));
            end
        end
        for i=pos(1):optibox.bottom
            if(walls(i,pos(1))==1)
                break;
            end
            pointMap1=pointMap([pos(2)-2:i+2],[pos(1)-2:pos(1)+2]); %odd number pointMaps are very different from even number pointMaps
            
            if(isempty(pointMap1))
                continue;
            else
                pointMap1([1 end], [1 end])=0; %gets rid of corners
            end
            sum1=sum(sum(pointMap1));
            for j=pos(1):-1:optibox.left
                if(walls(i,j)==1)
                    leftBound=j-1;
                end
            end
            rightBound=optibox.right;
            for j=pos(1):optibox.bottom
                if(walls(i,j)==1)
                    rightBound=j+1;
                end
            end
            scoreGrid([i],[leftBound:rightBound])=sum1;
            pointMap2=pointMap;
            pointMap2([i-2:pos(2)+2],[pos(1)-2:pos(1)+2])=0;
            for j=leftBound:pos(1)
                pointMap3=pointMap2([i-2:i+2],[j-2:pos(1)+2]); %%HERE
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(i,j)=scoreGrid(i,j)+sum(sum(pointMap3));
            end
            for j=pos(2):rightBound
                pointMap3=pointMap2([i-2:i+2],[pos(1)-2:j+2]);
                pointMap3([1 end],[1 end]); %remove corners
                scoreGrid(i,j)=scoreGrid(i,j)+sum(sum(pointMap3));
            end
        end
        scoreGrid
        sumMax=max(max(scoreGrid));
        x_max=find(max(scoreGrid)==sumMax);
        y_max=find(max(scoreGrid,[],2)==sumMax);
        delta=[y_max(1),x_max(1)]-[pos(2),pos(1)];
        disp(delta);
        disp(delta(1,2));
        %We want to go up or down first then left or right;
        LRdirectionMatrix=[4 8 6; 4 5 6; 4 2 6];
        UPdirectionMatrix=[8 8 8; 4 5 6; 2 2 2];
        direction1=UPdirectionMatrix(delta(1,2)/abs(delta(1,2))+3,(delta(1,1)/abs(delta(1,1)))+3);
        direction2=LRdirectionMatrix(delta(1,2)/abs(delta(1,2))+3,delta(1,1)/abs(delta(1,1))+3); %We only care wether or not x is postive or negative
        newDirections=[direction1*abs(delta(1,1)),direction2*abs(delta(1,2))];
        output=newDirections(1);
    end
end

function output=updateMap(pos, map, LV)
    LV_new=LV;
    LV_new([1 end], [1 end])=0;
    temp=[map(pos(2)-2,pos(1)-2) 0 0 0 map(pos(2)-2,pos(1)+2); 0 0 0 0 0; 0 0 0 0 0; 0 0 0 0 0; map(pos(2)+2,pos(1)-2) 0 0 0 map(pos(2)+2,pos(1)+2)]; %A greater Y corresponds to a lower height therefore the NE and NW corners have lower Y values than SE and SW, also the Y value goes first in arrays
    map([(pos(2)-2):(pos(2)+2)],[(pos(1)-2):(pos(1)+2)])=LV_new+temp;
    output=map;
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

function newPos=posNextMove(pos,direction,steps)
%Change in X,Y based direction number given in keypad position
%Greater Y is futher down the screen
moves={[-1,1],[0,1],[1,1],[-1,0],[0,0],[1,0],[-1,-1],[0,-1],[1,-1]};
if(nargin==2) %incase number of steps isn't specified
    steps=1;
end
newPos=pos+(steps*moves{direction}); %multiple steps in calculation
end

