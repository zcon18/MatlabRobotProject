% roomba script - PFS Feb 2023
if ( warn_msg == 1 ) | ( step_num == 0 )  
    direction = randi(8,1);
    if direction >= 5;
        direction = direction + 1;
    end
end
command = direction;
