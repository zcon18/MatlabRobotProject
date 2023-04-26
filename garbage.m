%Return to base will be determined by running the A* Algorthim on every
%step until length of the path is equaled to the steps remaining minus 1
%In this version of the algorthim path through blocks are zeros and
%non-pass through blocks are ones.
%The input matrixies must have int 8 entries for proformance reasons
scanZone=int8(map~=0); %every where inside the region we scanned will be either a 1 if its a wall/charger or a zero if its empty, and everywhere outside the reason we scanned is a 1. This to make sure the path doesn't take us through walls.
scanZone(12,12)=1;
scanZone(newPos1(2),newPos1(1))=1;
%We set up the goal register which is just saying our goal is to get back
%to the start
GoalRegister=int8(zeros(23,29));
GoalRegister(STARTING_POS_2,STARTING_POS_2)=1; % 13,13 is the starting postion


%Connecting Distance just determines how far of a jump we can make on each
%step which is always a 1, which connects us to 8 adjcent cells
Connecting_Distance=1;

%Calling ASTARPATH to generate the OptimalPath
OptimalPath=[];
if(step_num>0)&&sum(pos2==[13,13])~=2
OptimalPath=ASTARPATH(pos2(1),pos2(2),scanZone,GoalRegister,Connecting_Distance);
end
%OptimalPath is gives you all the coordinates from start to goal in reverse order
%Therefore when returning to base we can take the 2nd to last minus the
%last one to get the delta x and delta y of the next step we need to make
%inorder to get back to the charger on the very last move.

if(length(OptimalPath)>step_lim-2-step_num)
    directionMatrix=[7 8 9; 4 5 6; 1 2 3];
    OptimalPath2=rot90(OptimalPath,2);
    if(~isempty(OptimalPath))
    delta=[OptimalPath2(2,1)-OptimalPath2(1,1),OptimalPath2(2,2)-OptimalPath2(1,2)];
    decodeToDirection=delta+[2,2];
    direction2=directionMatrix(decodeToDirection(2),decodeToDirection(1));
    end
end
if(step_num>step_lim-3)&&sum(pos2==[13,13])==2
    direction2=5;
end
if(isequal(pos2+moveArray{direction2},newPos1)||isequal(pos2+moveArray{direction2},pos1))
    direction2=5;
end