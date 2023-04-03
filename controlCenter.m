optimalScaningBox=zeros(23,29);
optimalScaningBox(5:end-4,5:end-4)=1; %So theres a way of doing this with a 2d convolution which even has some simularities to the porject that we are doing but I don't wanna look into it rn

sightBox=ones(5,5);
sightbox([1 5], [1 5])=0;

pos=[12,12];
newPos=posNextMove(pos,8,8);
if(optimalScaningBox(newPos(2),newPos(1))==0)
    disp("Beyond");
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

%{
NE=(5,25)
NW=(5,5)
SW=(19,5)
SE=(19,25)

optiSize={[5,25];[5,19]}

(5,5) (5,X) (5,25)
(Y,5)  (Y,X) (Y,25)
(19,5) (19,X) (19,25)

(Y+4,X)




directionStrip = [8 8 8 8 8 4 4 4 4]
direction=directionStrip(step_num)

switch direction
	case 2
		checkBlocks=local_view([4 5], [2 3 4]) 
	case 4
		checkBlocks=local_view([2 3 4], [1 2]) %change these to fit in a 2x3 matrix wiht the nearest one on top
		checkBlocks=rot90(checkBlocks);
	case 6
		checkBlocks=local_view([2 3 4], [4 5])
		checkBlocks=rot90(checkBlocks,-1);
	case 8
		checkBlocks=local_view([2 1], [2 3 4]) %I think 2,1 will re-arrange it properly
end
navigate(checkBlocks)


do if checks all pass
command=direction

function [direction,offset] evasiveManeuvers(scanZone) %2x3 matrix check if there is a solid line of blocks if so its time to turn and pick a new path
	if(scanZone(1,:)==[-1 -1 -1])||(scanZone(2,:)==[-1 -1 -1])
		%Wall time
	end
end

%%modes:
% 1 optimal: outside black border
% 2 sub-optimal: outside already mapped
% 3 backtracking: inside already mapped
% 4 pre-computed: ignore navigate

pointMap=ceil((map+1)/sum(sum(abs(map)))).*optimalScaningBox;

pointMap[min(pos(2),newPos(2)):max(pos(2),newPos(2))],[min(pos(1),newPos(1)):max(pos(1),newPos(1))]

function [score, commands] = calculate(pos,direction,pointMap???,optimalMap, depth)
	%never do a depth higher than 3 because then the calculated route can interact with itself
	if depth==4
		return [score, commands] == [0, {}];
	end
	scoreRoute1=0;
	scoreRoute2=0;
	scoreRoute3=0;
	commandsRoute1={};
	commandsRoute2={};
	commandsRoute3={};
	breakTest=True;
	switch direction
		case 2 %going down to the bottom of the screen
			for i=pos(2):optiSize{2}(2)
				if (optimalMap(i,pos(1))==-11)||(optimalMap(i,pos(1))==-12)||(optimalMap(i,pos(1))==-13) %check to see if we are going to run into an area we already explored
					commandsRoute3{end+1}=struct("direction",2 , "mode",2);
					calculate([pos(1),i],2,pointMap,optimalMap,depth+1);
					commandsRoute1{end+1}=struct("direction",4 , "mode",1);
					[scoreRoute1,commandsRoute1]=calculate([pos(1),i],4,pointMap,optimalMap,depth+1);
					commandsRoute2{end+1}=struct("direction",6 , "mode",1);
					[scoreRoute2,commandsRoute2]=calculate([pos(1),i],6,pointMap,optimalMap,depth+1);
					breakTest=False;
					break
				end
				if (optimalMap(i,[pos(1)-1:pos(1)+1])==[-1,-1,-1]) %if we are inside the explored area check if there is a 1x3 wall
					commandsRoute1{end+1}=struct("direction",4 , "mode",1);
					[scoreRoute1,commandsRoute1]=calculate([pos(1),i],4,pointMap,optimalMap,depth+1);
					commandsRoute2{end+1}=struct("direction",6 , "mode",1);
					[scoreRoute2,commandsRoute2]=calculate([pos(1),i],6,pointMap,optimalMap,depth+1);
					breakTest=False;
					break
				end
				commands{end+1}=struct("direction",2 , "mode",1);
			end
			%Only run this part if the for loop failed to break meaning it got all the way to the optiBox
			if(breakTest)
				commandsRoute1{end+1}=struct("direction",4 , "mode",1);
			`	[scoreRoute1,commandsRoute1]=calculate([pos(1),optiSize{2}(2)],4,pointMap,optimalMap,depth+1);
				commandsRoute2{end+1}=struct("direction",6 , "mode",1);
				[scoreRoute2,commandsRoute2]=calculate([pos(1),optiSize{2}(2)],6,pointMap,optimalMap,depth+1);
			end
			%find the maximum of scoreRoute 1 2 and 3 then return that routes score plus the score of getting to there and the commands of that route appended to the commands to get to there
		
		case 4
			
		case 6
		
		case 8
			for i=pos(2):optiSize{2}(1) %first one in the optibox is the upper limit of the box
				if (optimalMap(i,pos(1))==-17)||(optimalMap(i,pos(1))==-18)||(optimalMap(i,pos(1))==-19) %check to see if we are going to run into an area we already explored
					commandsRoute3{end+1}=struct("direction",8 , "mode",2);
					calculate([pos(1),i],2,pointMap,optimalMap,depth+1);
					commandsRoute1{end+1}=struct("direction",4 , "mode",1);
					[scoreRoute1,commandsRoute1]=calculate([pos(1),i],4,pointMap,optimalMap,depth+1);
					commandsRoute2{end+1}=struct("direction",6 , "mode",1);
					[scoreRoute2,commandsRoute2]=calculate([pos(1),i],6,pointMap,optimalMap,depth+1);
					breakTest=False;
					break
				end
				if (optimalMap(i,[pos(1)-1:pos(1)+1])==[-1,-1,-1]) %if we are inside the explored area check if there is a 1x3 wall
					commandsRoute1{end+1}=struct("direction",4 , "mode",1);
					[scoreRoute1,commandsRoute1]=calculate([pos(1),i],4,pointMap,optimalMap,depth+1);
					commandsRoute2{end+1}=struct("direction",6 , "mode",1);
					[scoreRoute2,commandsRoute2]=calculate([pos(1),i],6,pointMap,optimalMap,depth+1);
					breakTest=False;
					break
				end
				commands{end+1}=struct("direction",2 , "mode",1);
			end
			%Only run this part if the for loop failed to break meaning it got all the way to the optiBox
			if(breakTest)
				commandsRoute1{end+1}=struct("direction",4 , "mode",1);
			`	[scoreRoute1,commandsRoute1]=calculate([pos(1),optiSize{2}(2)],4,pointMap,optimalMap,depth+1);
				commandsRoute2{end+1}=struct("direction",6 , "mode",1);
				[scoreRoute2,commandsRoute2]=calculate([pos(1),optiSize{2}(2)],6,pointMap,optimalMap,depth+1);
			end
			%find the maximum of scoreRoute 1 2 and 3 then return that routes score plus the score of getting to there and the commands of that route appended to the commands to get to there
	end
		
end

function navigate(pos, direction, scanZone, optimalMap)
	if(direction==2)||(direction==8)
		if(scanZone(1,2) == -1)
			[rightSum,rightCommands] = calculate(pos,6,pointMap,optimalMap,1);
			[leftSum, leftCommands] = calculate(pos,4,pointMap,optimalMap,1);
			%pick the max between leftSum and rightSum
		end
	end
	if(direction==4)||(direction==6)
		if(scanZone(1,2) == -1)
			[topSum,topCommands] = calculate(pos,8,pointMap,optimalMap,1);
			[bottomSum, bottomCommands] = calculate(pos,4,pointMap,optimalMap,1);
			%pick the max between topSum and bottomSum
		end
	end
end

make

[
 0 0 0     -11 -12 -12 -12 -13     0 0 0  ;
 0 0   -11  -2  -2  -2  -2  -2  -13  0 0  ;
 0  -11 -2  -2  -2  -2  -2  -2  -2 -13 0  ;
 -11 -2 -2  -2   0   0   0  -2  -2 -2 -13 ;
 -16 -2 -2   0   0   0   0   0  -2 -2 -14 ;
 -16 -2 -2   0   0   0   0   0  -2 -2 -14 ;
 -16 -2 -2   0   0   0   0   0  -2 -2 -14 ;
 -19 -2 -2  -2   0   0   0  -2  -2 -2 -17 ;
 0  -19 -2  -2  -2  -2  -2  -2  -2 -17 0  ;
 0 0   -19  -2  -2  -2  -2  -2  -17  0 0  ;
 0 0 0     -19 -18 -18 -18 -17     0 0 0  ;
 ]
 
 
 (x-(1))(x-(-1)(x-(sqrt(2)+sqrt(2)i))
%}