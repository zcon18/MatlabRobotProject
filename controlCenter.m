sightBox=ones(5,5);
sightbox([1 5], [1 5])=0;

WALL=-1;
SPACE=0;
CHARGING_STATION=1;
UNEXPLORED=2;
STARTING_POS=[12,12];

optimalScaningBox=zeros(23,29);
optimalScaningBox(5:end-4,5:end-4)=UNEXPLORED; %So theres a way of doing this with a 2d convolution which even has some simularities to the porject that we are doing but I don't wanna look into it rn

optibox=[5,25;5,19]; %(X,Y)

if (step_num==0)
    map=[ones(2,29)*WALL;  ones(19,2)*WALL, ones(19,25)*UNEXPLORED, ones(19,2)*WALL;  ones(2,29)*WALL];
    map([(12-2):(12+2)],[(12-2):(12+2)])=LV;
    pos=STARTING_POS;
    slams={ones(1,29)*17,ones(23,1)*5,ones(23,1)*21,ones(1,29)*5};
end


map=updateMap(pos,map,LV); %update map before you change position TO SEE MAP LOAD IN memorySpace THEN DO image((map(:,:)+1)*128)
slams=updateSlams(pos,LV,slams);
pos=deadReckon(pos,direction);



%Functions

function newPos=posNextMove(pos,direction,steps)
%Change in X,Y based direction number given in keypad position
%Greater Y is futher down the screen
moves={[-1,1],[0,1],[1,1],[-1,0],[0,0],[1,0],[-1,-1],[0,-1],[1,-1]};
if(nargin==2) %incase number of steps isn't specified
    steps=1;
end
newPos=pos+(steps*moves{direction}); %multiple steps in calculation
end

function output_map=updateOptimalMap(directiom,pos,optimalMap)
switch direction
    case 2
        kernel=[
            16     5     5     0     0     0     0     0     5     5    14;
            16     5     5     0     0     0     0     0     5     5    14;
            16     5     5     5     0     0     0     5     5     5    14;
            10    19     5     5     5     5     5     5     5    17    10;
            10    10    19     5     5     5     5     5    17    10    10;
            10    10    10    18    18    18    18    18    10    10    10;
            ];
    case 4
        kernel=[
            10    10    10    12    12    12;
            10    10    13     5     5     5;
            10    13     5     5     5     5;
            16     5     5     5     0     0;
            16     5     5     0     0     0;
            16     5     5     0     0     0;
            16     5     5     0     0     0;
            16     5     5     5     0     0;
            10    19     5     5     5     5;
            10    10    19     5     5     5;
            10    10    10    18    18    16;
            ]

    case 6
        kernel=[
            12    12    12    10    10    10
             5     5     5    11    10    10
             5     5     5     5    11    10
             0     0     5     5     5    14
             0     0     0     5     5    14
             0     0     0     5     5    14
             0     0     0     5     5    14
             0     0     5     5     5    14
             5     5     5     5    17    10
             5     5     5    17    10    10
            18    18    18    10    10    10
            ]
        
    case 8
        kernel=[
            10    10    10    12    12    12    12    12    10    10    10;
            10    10    13     5     5     5     5     5    11    10    10;
            10    13     5     5     5     5     5     5     5    11    10;
            16     5     5     5     0     0     0     5     5     5    14;
            16     5     5     0     0     0     0     0     5     5    14;
            16     5     5     0     0     0     0     0     5     5    14;
            ];

    end
end

function tube=makeTube(direction, steps)
    if(direction == 8||2)
        tube=ones(steps,5);
        tube([1 end], [1 end])=0;
    end
    if(direction == 4||6)
        tube=ones(5,steps);
        tube([1 end], [1 end])=0;
    end
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

function commands=scanScanSlam(pos,direction,map,optibox,slams) %The way how this function works is it first spreates the pointmap into 3 parts to left/top of the robot, a middle strip, and to the right/bottom of the robot. It then scans the left/up for walls if there are non then it goes up and down/left and right scaning for more walls, then it slams on the 3rd term to the slam value , it then computes the sum if it were to go on that route, the highest sum is the direction the robot goes in
    walls=(map==-1)+(map==1); %wall, charing_station
    pointMap=(map==2); %unexplored
    if(direction==2) %then do left and right
        %it makes a matrix THE SIZE of top to bottom of the optibox then left until it reaches the
        %x-value the robot is in
        LLScoreMatrix=zeros(optibox(2,2)-optibox(2,1),pos(1));%The whole hight of the optibox
        LRScoreMatrix=zeros(optibox(2,2)-optibox(2,1),pos(1));
        RRScoreMatrix=zeros(optibox(2,2)-optibox(2,1),optibox(1,2)-pos(1));
        RLScoreMatrix=zeros(optibox(2,2)-optibox(2,1),optibox(1,2)-pos(1));
        middleURDScoreMatrix=zeros(optibox(2,2)-optibox(2,1),1);
        middleULDScoreMatrix=zeros(optibox(2,2)-optibox(2,1),1);
        runningSum=0;

        %making the left score Matrix
        LDepth=0; %be a position number 
        UDepth=0;
        for i=pos(1):-1:optibox(1,1) %left most side of the optibox
            if(walls(pos(2),i)==1) %break this intial forward reaching loop if there are any known walls directly infront of the robot
                LDepth=i; %MAYBE set this as i-1?
                break;
            end

            %Starting sum and updating pointMap before it enters the next loop
            newPM=pointMap; %resets newPM
            nievePM=newPM([pos(2)-2:pos(2)+2],[i-2:pos(1)+2]); %this will be a long tube full of potiental points for unexplored blocks
            nievePM([1 end],[1 end])=0; %makes the corners of the tube zero because you can't see them
            runningSum=sum(sum(nievePM)); %this forces runningSum to be the sum of the tube, it gets reset every time
            newPM([i-2:newPMpos(2)+2],[pos(1)-2:pos(1)+2])=0; %sets the part of newPM equaled to zero for calculating the next loop, so we don't double count points
        
            %run a for loop on depth, then going to slam numbers, checking
            %right and left, if a search starts after a slam number just set it
            %as the optibox
            for j=pos(2):-1:optibox(1,1) %going up to the top of the optibox
                if(walls(j,i)==1)
                    UDepth=j;
                    break
                end
                newNewPM=newPM;
                nievePM2=newNewPM([j-2:pos(2)+2],[i-2:i+2]); %this says that our new scaning postion is i inward therefore the horizontal box of our tube is i-2 to i+2, vertically the box starts at pos(2)+2 cause a greater y is futher doward and it is j tall because it starts at the pos(2) (y-value) and decreases.
                nievePM2([1 end], [1 end])=0; %The corners can't be counted in our sum
                runningSum2=sum(sum(nievePM2))
                newNewPM([j-2:pos(2)+2],[i-2:i+2])=0; %set the section that the tube was equaled to zero to prevent double counting
                
                %now we just need to slam it right and left
                if(i<slams{3}(j)) %in the event the right slam has been made really small just set it back equalled to the slam box
                    slams{3}(j)=optibox(1,2); %x-value maximum value MAYBE set this to S or something
                end
                slamTubeR=newNewPM([j-2:pos(2)+2],[i-2:slams{3}(j)+2]) %from the curent positon all the way back right until you reach the slam value
                slamTubeR([1 end], [1 end])=0; %don't include corners
                runningSum3=sum(sum(slamTubeR));
                LRScoreMatrix(j,i)=runningSum3+runningSum2+runingSum;

                if(i>slams{2}(j))
                    slams{2}(j)=optibox(1,1) %MAYBE set this equalled to S???
                end
                slamTubeL=newNewPM([j-2:pos(2)+2],[slams{2}(j)-2:i+2]);
                slamTubeL([1 end], [1 end])=0;
                runningSum3=sum(sum(slamTubeL));
                LLScoreMatrix(j,i)=runningSum3+runningSum2+runningSum;
            end
        end
    end
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