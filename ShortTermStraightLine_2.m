%Zack Weinstein, Harrison Cotton, Emily Keller

%TODO: If the memorySpace ever starts a trial with a 5 in pD the robot will
%never move, so wee need to fix that <- this might be fixed now
%TODO: The robot will get stuck if it approaches a lone black diagonally
%because the corner of its FOV is invisible, so we need a way of checking
%inside the 3x3 "safety square" if our approach is still using diagonals.
%TODO: Pick a non-digonal direction when apporching a corner that the robot
%gets stuck in


%Mem needs to be called in both branches
if isfile('memorySpace.mat') %There's a chance the file won't exist so we need to make it just in case
    mem = matfile('memorySpace.mat','Writable',true); % Matfile makes it so we don't have to load a file in each time
else
    disp("memory space file does not exist, creating")
    previousDirection=1; %Prefer to go to the bottom left
    save("memorySpace.mat",'previousDirection');
    mem=matfile('memorySpace.mat','Writable',true);
end
previousDirection=mem.previousDirection; %grabs pD from memory
previousDirectionIndex=previousDirection; %converts the digonal directon to the index, it sets it to 2 on the first move but because the frame is zero this doesn't matter
%Picking the best moves
optimal_moves=[1,0,3,0,0,0,7,0,9];
top=local_view(1,[2:4]);
bottom=local_view(5,[2:4]);
left=local_view([2:4],1);
right=local_view([2:4],5);
if sum(top)<0
    optimal_moves(7)=0;
    optimal_moves(9)=0;
end
if sum(bottom)<0
    optimal_moves(1)=0;
    optimal_moves(3)=0;
end
if sum(left)<0
    optimal_moves(1)=0;
    optimal_moves(7)=0;
end
if sum(right)<0
    optimal_moves(3)=0;
    optimal_moves(9)=0;
end
if (step_num>0)&&(previousDirection~=5) %anti-backtracking, only starts after the first frame, and it had to move somewhere on the last frame
    optimal_moves(10-previousDirectionIndex)=0; %this makes it so we can't backtrack
end

%Picking from the best moves
possible_moves=[];
for i=1:2:length(optimal_moves)
    if optimal_moves(i)>0
        possible_moves=[possible_moves,optimal_moves(i)]; %this commbines all non-zero vaules into a smaller array
    end
end
%Setting command to be the one we picked
if(optimal_moves(previousDirectionIndex)==0) %Incase we can't go in a straight line we pick a new direction
    if isempty(possible_moves) %this makes it so the robot will pick a cardnal direction to go in if its in a corner
        [M,minIndex]=min([sum(top)+sum(left),sum(top)+sum(right),sum(bottom)+sum(left),sum(bottom)+sum(right)]);
        switch minIndex
            case 1
                possible_moves=[2,6];
            case 2
                possible_moves=[2,4];
            case 3
                possible_moves=[8,6];
            case 4
                possible_moves=[8,4];
        end
    end
    n=randi(length(possible_moves),1);
    previousDirection=possible_moves(n);
    
    command = possible_moves(n);
    if step_num~=25
        mem.previousDirection=previousDirection;
    else
        mem.previousDirection=3;
    end
else %Otherwise we just go in a straight line
    command = previousDirection;
end


%functions
function reversed=reverse(direction) %takes in a direction number gives the reverse direction, were the dirrection numbers are placed as if they are on e key-pad
    reversed=10-direction;
end
