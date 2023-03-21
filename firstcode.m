
%local_view=zeros(5,5);
%disp("Zack Weinstein, Harrison Cotton, Emily Keller")
optimal_moves=[1,3,7,9];
foo=[0,0,0,0];
top=local_view(1,[2:4]);
bottom=local_view(5,[2:4]);
left=local_view([2:4],1);
right=local_view([2:4],5);
if (sum(top)+sum(bottom)+sum(left)+sum(right)~=0)|(step_num == 0)
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
    foo=[foo;optimal_moves];
    disp(optimal_moves);
    n=randi(4,1);
    
    while optimal_moves(n)==0
        n=randi(4,1);
    end
    command = optimal_moves(n);

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
end