%Authors: Zack Weinstein, Kiley Stahl
%Theory: Pick a random direction to start in. Only analyze the 3x3 space
%around the bot, and only pay attention to block in the area the bot will
%be on the next step. If there is a block there pick a direction on the
%opposite side of the keypad that isn't the direction the bot is coming
%from. If there is a block there then it will pick a direction on the
%opposite side from that block.
if step_num==0 %starting conditions: pick a random direction because of how the code is setup it won't ever go into a block on the first move
    n=5;
    while n==5 %picks a random direction (can't be 5 because it won't go anywhere)
        n=randi(9,1); 
    end
    direction=n;
end
direction=find_permeable(direction, local_view);
command=direction;
function output=find_permeable(direction, local_view) %this function uses recursion to figure out if the bot can pass in the direction it's going on to the next step. if it can then it continues in the same direction, if not it picks from the 2 directions adjacent to it on the opposite side
    blocks=[4 2; 4 3; 4 4; 3 2; 3 3; 3 4; 2 2; 2 3; 2 4]; %These are the only blocks that the bot will ever look at, the index number of the block corresponds to if you placed a keypad on the 3x3 section around the bot in local view, this means that cell with a given index number will be in the direction number of the next step
    if local_view(blocks(direction,1),blocks(direction, 2)) >= 0 %Checks if the block it's heading towards is not a wall
        output=direction;
    else %If it is a wall then select possible new directions based on the current direction
        switch direction
            case 1
                d=[6,8];
            case 2
                d=[7,9];
            case 3
                d=[4,8];
            case 4
                d=[3,9];
            case 5 %just in case a 5 somehow is picked
                d=[1,2,3,4,6,7,8,9];
                disp("what?");
            case 6
                d=[1,7];
            case 7
                d=[2,6];
            case 8
                d=[1,3];
            case 9
                d=[2,4];
        end
        direction=d(randi(length(d),1));
        output=find_permeable(direction, local_view); %then it runs the function again new direction it generated, to check if it can pass through the block in its new direction.
    end
end