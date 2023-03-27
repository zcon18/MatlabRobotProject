%Author: Zack Weinstein
%Theory: Break sections of FOV into groups (NE, N, NW, W, etc). Only pay 
%attention to the group immediately in front of the bot on the next step.
%If there is a wall in any of these spaces (which can be determined using
%the sum command) mark this as impermeable and check a one of the 2 
%adjacent directions to the opposite of the current direction. Keep
%checking until you find a permeable direction.

WALL=-1;
SPACE=0;
UNEXPLORED=1;
STARTING_POS=[12,12];

%Mem needs to be called in both branches
if isfile('memorySpace.mat') %There's a chance the file won't exist so we need to make it just in case
    mem = matfile('memorySpace.mat','Writable',true); % Matfile makes it so we don't have to load a file in each time
else
    disp("memory space file does not exist, creating")
    map=[ones(2,29)*WALL;  ones(19,2)*WALL, ones(19,25)*UNEXPLORED, ones(19,2)*WALL;  ones(2,29)*WALL];
    save("memorySpace.mat",'map');
    mem=matfile('memorySpace.mat','Writable',true);
end
map=mem.map;
if step_num==0
    position=STARTING_POS;
    map([(12-2):(12+2)],[(12-2):(12+2)])=rmmissing(local_view);
    i=5;
    while i==5 %picks a random direction (can't be 5 because it won't go anywhere)
        i=randi(9,1); 
    end
    direction=i;
end

direction=find_permeable(direction, local_view);
command=direction;
function output=find_permeable(direction, local_view) %this function uses recursion to figure out if the bot can pass in the direction it's going on to the next step. if it can then it continues in the same direction, if not it picks from the 2 directions adjacent to it on the opposite side
    % FOV Groups
    NE=rmmissing(local_view([1 2],[4 5]));
    N =local_view([1 2],3);
    NW=rmmissing(local_view([1 2],[1 2]));
    W = local_view(3,[1 2]);
    SW=rmmissing(local_view([4 5],[1 2]));
    S = local_view([4 5],3);
    SE=rmmissing(local_view([4 5],[4 5]));
    E = local_view(3,[4 5]);
    groups={SW; S; SE; W; [3 3]; E; NW; N; NE}; %These are the only block groups that the bot will ever look at, the index number of the block corresponds to if you placed a keypad on the 3x3 section around the bot in local view, this means that cell with a given index number will be in the direction number of the next step
    if sum(sum(groups{direction})) >= 0 %Checks if the block it's heading towards is not a wall
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
        output=find_permeable(direction, local_view); %then it runs the function again new direction it generated, to check if it can pass through the block in its new direction.
    end
end