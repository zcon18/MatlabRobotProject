
%local_view=zeros(5,5);
%disp("Zack Weinstein, Harrison Cotton, Emily Keller")
load('memorySpace.mat');
previousDirectionIndex=((previousDirection-1)/2)+(previousDirection<5); %converts the digonal directon to the index
optimal_moves=[1,3,7,9];
top=local_view(1,[2:4]);
bottom=local_view(5,[2:4]);
left=local_view([2:4],1);
right=local_view([2:4],5);
if sum(top)<0
    optimal_moves(3)=0;
    optimal_moves(4)=0;
end
if sum(bottom)<0
    optimal_moves(1)=0;
    optimal_moves(2)=0;
end
if sum(left)<0
    optimal_moves(1)=0;
    optimal_moves(3)=0;
end
if sum(right)<0
    optimal_moves(2)=0;
    optimal_moves(4)=0;
end
if step_num>0 %anti-backtracking
    %{
3    4           0.5    1.5           -0.5 -1.5           2   1
  X       - 2.5               *-1                 + 2.5
1    2          -1.5   -0.5            1.5  0.5           4   3
    %}
    optimal_moves((previousDirectionIndex - 2.5).*(-1) + 2.5)=0; %this makes it so we can't backtrack
end
possible_moves=[];
for i=1:length(optimal_moves)
    if optimal_moves(i)>0
        possible_moves=[possible_moves,optimal_moves(i)]; %this commbines all non-zero vaules into a smaller array
    end
end
if(optimal_moves(previousDirectionIndex)==0)
    disp(possible_moves);
    n=randi(length(possible_moves),1);
    previousDirection=possible_moves(n);
    
    command = possible_moves(n);
    save('memorySpace.mat','previousDirection');
else
    command = previousDirection;
end


%test to see if I can get git to work

%second test to see if its easier this time

%{
    for i=1:length(optimal_moves)
        
        if optimal_moves(i)>0
            command=optimal_moves(i);
            break
        end
    end 
%}
% TOP: local_view([2:4],1), BOTTOM local_view([2:4],5)
% Left local_view(1,[2:4]) Right local_view(5,[2:4])
%{
    %pick rand diagonal
    command = optimal_moves(randi(4,1))
%}