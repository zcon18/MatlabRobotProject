function zzz = robot_5(varargin)
%% EGR 106H 2023 robot search program
% new version to align rox/col notation and x/y location
% version 5 - metric is still explored area
%       add bonus points
%       two bots
% Mar 2023
% argument 1 - filename
% argument 2 - map number
% argument 3 - 0 to skip graphics entirely, 1 or missing for slow, 2 for fast graphics

% shut off functions that might help them cheat
who  = 0;
whos = 0;

%% check for a filename
if nargin==0
    disp('you need to include your filename')
else

    %% initialize internal variables relevant to this version

    zstep_lim = 20;   % length of search
    zzz = 0;              % final score for fast version
    zpenalty = 20;    % warning penalty

    % load world - all maps are 23 rows, 29 columns with a
    %      wall of thickness 2 all around
    load map5

    zh = hor;
    zv = vert;
    zrobot_r = bot_r;
    zrobot_c = bot_c;

    if nargin >= 2
        zchoice = varargin{2};
    else
        zk = size(worlds,3);
        zchoice = 0;
        while ~ismember(zchoice,1:zk)
            zchoice = input([num2str(zk),' maps are available; which one? ']);
        end
    end
    zworld = worlds(:,:,zchoice);

    clear worlds vert hor bot_r bot_c

    if nargin == 3  % 0 for none, 1 for normal, 2 for fast
        zshowgraphics = varargin{3};
    else
        zshowgraphics = 1;
    end

    %% draw the world
    if zshowgraphics
        figure(20)
        plot([0,0,zh,zh,0]+.5,[0,-zv,-zv,0,0]-.5,'k','linewidth',3)
        hold on
        zdx = .5*[ -1 1 1 -1];
        zdy = .5*[ -1 -1 1 1];
        for zr = 1:zv
            for zc = 1:zh
                zindex = (zc-1)*zv + zr;
                switch zworld(zr,zc)
                    case 20  % add black? for collectibles
                        zmap_h(zindex) = fill(zc+zdx,-zr+zdy,1*[1 1 1],'linewidth',1);
                    case 10  % add green for bonus points
                        zmap_h(zindex) = fill(zc+zdx,-zr+zdy,1*[0 1 0],'linewidth',1);
                    case 1  % add dark blue for charging stations
                        zmap_h(zindex) = fill(zc+zdx,-zr+zdy,1*[0 0 1],'linewidth',1);
                    case -1  % add dark gray for forbidden areas
                        zmap_h(zindex) = fill(zc+zdx,-zr+zdy,.5*[1 1 1],'linewidth',1);
                    case 0   % shown as white on map
                        zmap_h(zindex) = fill(zc+zdx,-zr+zdy,1*[1 1 1],'linewidth',1);
                end
            end
        end
        axis equal
        axis off
        % add the robots
        zsi = .5*sind(0:45:360);
        zco = .5*cosd(0:45:360);
        zrobot_h(1) = fill(zrobot_r(1)+zsi,-zrobot_c(1)+zco,'r');
        zrobot_h(2) = fill(zrobot_r(2)+zsi,-zrobot_c(2)+zco,'r');
        % add the warning block
        zwarn_h = text(zh-4,1.5,'Warning','Fontsize',24);
        set(zwarn_h,'color',[1 0 0],'FontWeight','bold')
        set(zwarn_h,'color',[1 1 1])
    end

    %% create other internal variables
    zcolor = zworld;
    zmovemap = [ 9 14 19 8 13 18 7 12 17 ];
    zmove = [ 1-zv, 1, 1+zv, -zv, 0, zv, -(1+zv), -1, zv-1 ];

    zscore = 0;              % dual variables just to keep them honest
    score = zscore;
    zwarn_msg = [ 0 0 ];
    warn_msg = zwarn_msg;
    zcrash_msg = 0;
    step_lim = zstep_lim;
    step_num = 0;

    zbot_index_now = (zrobot_c-1)*zv + zrobot_r;
    zworld(zbot_index_now) = 5;

    %% main loop
    if zshowgraphics
        disp(' press any key to start ')
        pause
    end

    for zstep = 0:(zstep_lim-1)

        step_num = zstep; % dual variables just to keep them honest

        % color the visible world
        for zz = 1:2
            for zr = -2:2
                for zc = -2:2
                    if abs(zr)+abs(zc) == 4
                        continue
                    end
                    zindex = (zrobot_c(zz)+zc-1)*zv + zrobot_r(zz)  + zr;
                    switch zcolor(zrobot_r(zz)+zr,zrobot_c(zz)+zc)
                        case -1 % already a wall
                        case 10 % bonus cell
                        case -2 % already colored
                        case 1  % a charger
                        case 5 % bots don't show up in color, only in world
                        case 0  % color as yellow and update zcolor and score
                            if zshowgraphics
                                set(zmap_h(zindex),'FaceColor',.5*[1 1 0])
                                set(zmap_h(zindex),'FaceAlpha',.5)
                            end
                            zcolor(zrobot_r(zz)+zr,zrobot_c(zz)+zc) = -2;
                            zscore = zscore + 1;
                            score = zscore;
                    end
                end
            end
        end

        % update title block
        if zshowgraphics
            ztitle = [ 'Step ',num2str(zstep),', Score ',num2str(zscore)];
            title(ztitle,'fontsize',24)
        end

        % read the local area
        for zz = 1:2
            local_view(zz,1:5,1:5) = zworld(zrobot_r(zz)+(-2:2),zrobot_c(zz)+(-2:2));
        end
        % NaN its corners
        local_view(1,[1,5],[1,5]) = NaN;
        local_view(2,[1,5],[1,5]) = NaN;

        if zshowgraphics
            drawnow
        end

        % call control script - expected output is only "command"
        eval( varargin{1} )
        if ~exist('command')
            disp('your file needs to generate a command variable')
        elseif ~( length(command)==2 )
            disp('your command needs to have 2 entries')
        elseif ~all( ismember(command,1:9) )
            disp('the commands are not appropriate integer values')
        end

        %% now that the script has run, check for good stuff

        % clear a warning if there is one
        if zshowgraphics
            set(zwarn_h,'color',[1 1 1])
        end

        % check the commands against the fixed map
        zwarn_msg = [ 1 1 ];   % start with it set 
        if all( ismember(command,1:9) )
            zbot_index_next = zbot_index_now + zmove(command);
            znext = zworld(zbot_index_next);
            % is the next cell vacant or bonus or a crash?
            if ismember(znext(1),[0 10]) | command(1)==5
                zwarn_msg(1) = 0;
                if ismember(znext(2),[0 10]) | command(2)==5
                    zwarn_msg(2) = 0;
                    if zbot_index_next(1) == zbot_index_next(2)
                        zcrash_msg = 1;
                    end
                end
            end
        end

        % penalize a bad move 
        if any( zwarn_msg == 1)
            zscore = zscore - zpenalty*sum(zwarn_msg);
            score = zscore;
            if zshowgraphics
                set(zwarn_h,'color',[1 0 0 ])
                pause(1)
            end
        end

        % move robots in step, constructing trails
        if all( zwarn_msg == 0 )
            for zz = 1:2
                znew_r = zrobot_r(zz);
                znew_c = zrobot_c(zz);
                switch command(zz)
                    case 1 % SW
                        znew_r  = zrobot_r(zz) + 1;
                        znew_c = zrobot_c(zz) -1;
                    case 2 % S
                        znew_r  = zrobot_r(zz) + 1;
                    case 3 % SE
                        znew_r  = zrobot_r(zz) + 1;
                        znew_c = zrobot_c(zz) +1;
                    case 4 % W
                        znew_c = zrobot_c(zz) -1;
                    case 5 % no move
                    case 6 % E
                        znew_c = zrobot_c(zz) +1;
                    case 7 % NE
                        znew_r  = zrobot_r(zz) - 1;
                        znew_c = zrobot_c(zz) -1;
                    case 8 % N
                        znew_r  = zrobot_r(zz) - 1;
                    case 9 % NE
                        znew_r  = zrobot_r(zz) - 1;
                        znew_c = zrobot_c(zz) +1;
                end

                % clear out new cell if bonus
                if znext(zz) == 10;
                    zcolor(zbot_index_next(zz)) = 0;
                    zworld(zbot_index_next(zz)) = 0;
                    zscore = zscore + 10;
                    score = zscore;
                end

                % draw a trail
                if zshowgraphics
                    ztraj_row = linspace(-zrobot_r(zz),-znew_r,11);
                    ztraj_col = linspace(zrobot_c(zz),znew_c,11);
                    for zk = 1:11
                        set(zrobot_h(zz),'XData',ztraj_col(zk)+zsi,'YData',ztraj_row(zk)+zco)
                        if zshowgraphics==1
                            pause(.1)
                        end
                        if zk >= 2
                            plot(ztraj_col([zk-1,zk]),ztraj_row([zk-1,zk]),'b','linewidth',4)
                        end
                    end
                end
                zrobot_r(zz) = znew_r;
                zrobot_c(zz) = znew_c;
            end

            % update world
            zworld(zbot_index_now) = 0;
            zworld(zbot_index_next) = 5;
            zbot_index_now = zbot_index_next;

            % penalize a crash and end the simulation 
            if zcrash_msg == 1
                zscore = 0;
                score = 0 ;
                break
            end

        end
    end % end of step loop

    if zcrash_msg == 1
        text(1,-12,'CRASH','Fontsize',200)
        disp('CRASH')
    end


    %% check that the final position is next to a charger
    if zcrash_msg == 0
        [zcr,zcc] = find(zworld==1);
        for zz = 1:2
            zdelr = abs( zrobot_r(zz)-zcr);
            zdelc = abs( zrobot_c(zz)-zcc);
            zdel = zdelc + zdelr;
            if all(zdel~=1)
                disp(' ')
                disp(['-- DEAD BATTERY -- bot # ',num2str(zz)])
                disp(' ')
                zscore = zscore - 100;
            end
        end
    end

    %% update title block for the end
    if zshowgraphics
        ztitle = [ 'Step ',num2str(zstep+1),', Score ',num2str(zscore)];
        title(ztitle,'fontsize',24)
        hold off
        zzz = [];
    else
        zzz = zscore;
    end

end


