classdef draw_result
    properties
         % rt;   through;  tt; num_interact; Intrvl; num_users; errors; 
         metrics;
    end
    methods
        function obj = draw_result()
            i =0;
%             obj.rt=i+1; obj.through=i+2; obj.tt=i+3; obj.num_interact=i+4; obj.Intrvl=i+5; obj.num_users=i+6; obj.errors=i+7; 
            obj.metrics = struct('rt',i+1, 'through',i+2, 'tt',i+3, 'num_interact',i+4, 'Intrvl',i+5, 'num_users',i+6, 'errors',i+7 );
        end
      
        function res=parse_rbe_log(obj,infile,metric)
            fid = fopen(infile);
            saas_measure = [0 0 0 0 0 0 0];
            tline = fgetl(fid);
            res = [];
            while (ischar(tline))
                     [tok mat] = regexp(tline,'rt:(\d*\.?\d+)?,through:(\d*\.?\d+)?,tt:(\d*\.?\d+)?,num_interact:(\d+),Intrvl:(\d+),num_users:(\d+),errors:(\d+)','tokens', 'match'); 
                      if (~(isempty(tok)))                             
                            saas_measure = str2num(char(tok{1}))';
                      end

                    if isempty(res)
                        res = [saas_measure];
                    else
                        res = [res ; saas_measure];
                    end
                    tline = fgetl(fid);
            end        
        end %function

        function ret_=draw_rbe_metric_with_regression(obj,metric,varargin)
            u=UtilityLib();  
            delta = 15; %each 15 minutes            
            handle = figure;
           color_num =1;
            for k= 1 : size(varargin,2)          
                res=obj.parse_rbe_log(varargin{k}, metric);
                a_result=res((1:2:size(res,1)), getfield(obj.metrics,metric)); 
                a_result = a_result(1:219) % limit it to 220 samples
                a_result(a_result<0) = NaN;
                 plot(a_result, u.color{color_num});
                 tans_ = [];
                 sample_per_reg= 15;
                 for x1=1:delta:length(a_result)-delta
                    x2=x1+delta-1;
                    d=obj.regress((1:delta)',a_result(x1:x2));
                    intercept = d(1,1);
                    tan = d(2,1);                                    
                    line([x1; x2],[tan*1+intercept; tan*delta+intercept],...     
                            'Color',u.color{color_num},...
                            'LineStyle',u.lnstyle{color_num},...
                            'LineWidth',2,...
                            'Marker','s',...
                            'MarkerEdgeColor','k',...
                            'MarkerFaceColor','g',...
                            'MarkerSize',6);         
                        tans_=[tans_ tan];
                 end
                 hold on;
                color_num = color_num+1;
                atan(tans_)*180/pi;
                axis([0 size(a_result,1)  250 max(a_result)]) %hack
                ret_=a_result';
            end
        
        
            title('#Users');
            xlabel('Time');
            ylabel('Number of Users');           
            u.print_figure(handle,9,7,strcat(config().log_files.result_dir,'rbe-regression-',metric));
    end

        function draw_rbe_metric(obj,metric,varargin)
                u=UtilityLib();              
                handle = figure;
                % plotting response times
                color_num =1;
                res=[];                
                for k= 1 : size(varargin,2) 
                     res=obj.parse_rbe_log(varargin{k}, metric);
                     %res=res((1:2:6)) %hack-remove                    
                    plot(res(:, getfield(obj.metrics,metric)),u.color{color_num});
                    axis([0 size(res,1)  300 max(res(:, getfield(obj.metrics,metric)))]) %hack
                    hold on;
                     color_num = color_num+1;
                end                
                title('#Users');
                xlabel('Time');
                ylabel(metric);           
                 %legend('policy set 1','policy set 2','policy set 3');
                if strcmp(metric,'rt'); axis([0 size(res,1)  0 20]); end;
                u.print_figure(handle,9,7,strcat(config().log_files.result_dir,'rbe-',metric));
        end
        
        
%----------------------------------------------------------------------        
        function a_result =  parse_right_log(obj,info,file)
                    cmd = ['../strategytrees/parse_log.rb ', ' get_all_log ', info, ' ', file];
                    [status,result] = system(cmd);          
                    [a_result] = strread(result);              
                    % u.print_figure(handle,9,7,strcat('../rightscale/result/figure/','/response_time'));
        end %function
           
        % column vector X and Y
        function sol = regress(obj,X,Y)                                                   
                     X1 = [ones(size(X,1),1) X];
                     Y2=Y;
                     windowSize = 5;
                     Y2(isnan(Y))=0;
                     Y2 = filter(ones(1,windowSize)/windowSize,1,Y2')';
                     Y(isnan(Y))=Y2(isnan(Y));    
                     sol = (X1\Y);
                     % sols = [sols sol(2,1)]; %(1,1) is the 1s coef                    
        end
   
        function tans_=draw_metric_with_regression(obj,metric,varargin )          
            u=UtilityLib();  
            delta = 15;            
            handle = figure;
           color_num =1;
            for k= 1 : size(varargin,2)          
                a_result = obj.parse_right_log(metric,varargin{k});
                a_result = a_result(1:220); %% hack, remove                
                
                a_result(a_result<0) = NaN;
                 plot(a_result, u.color{color_num});
                 tans_ = [];
                 sample_per_reg= 15;
                 for x1=1:delta:length(a_result)-delta
                    x2=x1+delta-1;
                    d=obj.regress((1:delta)',a_result(x1:x2)');
                    intercept = d(1,1);
                    tan = d(2,1);                                    
                    line([x1; x2],[tan*1+intercept; tan*delta+intercept],...     
                            'Color',u.color{color_num},...
                            'LineStyle',u.lnstyle{color_num},...
                            'LineWidth',2,...
                            'Marker','s',...
                            'MarkerEdgeColor','k',...
                            'MarkerFaceColor','g',...
                            'MarkerSize',6);         
                        tans_=[tans_ tan];
                 end
                 hold on;
                color_num = color_num+1;
                 atan(tans_)*180/pi;
            end

                title('# Session over time');
                xlabel('Time');
                ylabel('# Session');           
                 %legend('policy set 1','policy set 2','policy set 3');
                 u.print_figure(handle,9,7,strcat(config().log_files.result_dir,'manager-sessions'));
        end

            function ret_=draw_cpu_idle(obj,varargin)
                u=UtilityLib();              
                handle = figure;
                color_num =1;     
                ret_=[];
                for k= 1 : size(varargin,2) 
                    a_result = obj.parse_right_log('cpu-idle', varargin{k});
                    a_result(a_result<0) = NaN;
                   % a_result =  100 - a_result; % convert cpu-idle to cpu-utilization
                    %plot(a_result, u.color{color_num});        
                    MeanFCN = @(x) sum(x) ./ length(x) ;
                    a_result = slidefun(MeanFCN,6,a_result)
                    utilization = 100-a_result; %idle time
                    plot(utilization, strcat(u.lnstyle{color_num},u.color{color_num}),...
                            'LineWidth',2,...
                            'MarkerEdgeColor','k',...
                            'MarkerFaceColor','g',...
                            'MarkerSize',10);     
                    hold on;
                    color_num = color_num+1;
                    if isempty(ret_)
                        ret_=utilization(1:219);
                    else
                        ret_(k,:)=utilization(1:219); 
                    end
                end
                title('CPU idle');
                xlabel('Time');
                ylabel('CPU idle');           
                legend('policy set 1','policy set 2','policy set 3');
                axis([0 length(a_result) 0 100]);
                u.print_figure(handle,9,7,strcat(config().log_files.result_dir,'manager-sessions'));               
        end
        
        
        function tans_=draw_sessions(obj,varargin)
                u=UtilityLib();              
                handle = figure;
                color_num =1;
                for k= 1 : size(varargin,2) 
                    a_result = obj.parse_right_log('sessions', varargin{k});
                    a_result(a_result<0) = NaN;
                    plot(a_result, u.color{color_num});                     
                    hold on;
                    color_num = color_num+1;
                end
                title(strcat('# ', 'sessions', 'over time'));
                xlabel('Time');
                ylabel(strcat('# ', 'sessions'));           
                 legend('policy set 1','policy set 2','policy set 3');
                 u.print_figure(handle,9,7,strcat(config().log_files.result_dir,'manager-sessions'));
        end

        function ret_=draw_servers(obj,varargin )      
                u=UtilityLib();              
                handle = figure;
                color_num =1;
                a_result =[]
                ret_=[];
                for k= 1 : size(varargin,2) 
                    a_result = obj.parse_right_log('servers', varargin{k});                         
                    a_result(a_result<0) = NaN;
                    plot(a_result+2, strcat(u.lnstyle{color_num},u.color{color_num}),...
                            'LineWidth',3,...
                            'MarkerEdgeColor','k',...
                            'MarkerFaceColor','g',...
                            'MarkerSize',10);     
                    hold on;
                    color_num = color_num+1;
                    if isempty(ret_)
                        ret_=a_result(1:219);
                    else
                        ret_(k,:)=a_result(1:219); 
                    end
                end
                title('Number of servers over time');
                xlabel('Time');
                ylabel(strcat('# ', 'servers'));           
                legend('policy set 1','policy set 2','policy set 3');
                axis([0 length(a_result) 1 7]);
                u.print_figure(handle,9,7,strcat(config().log_files.result_dir,'manager-servers')); 
                ret_=ret_+2;
        end

        function [num_users,utilization,servers] = test(obj)                        
%             [s,mess,messid] = mkdir(config().log_files.result_dir);
%             mess
%             [s,mess,messid] = mkdir(strcat(config().log_files.result_dir,'/figure'));
%             mess
 
            %            rt;   through;  tt; num_interact; Intrvl;
            %            num_users; errors; 
            f1=config().log_files.rbelog(1); f1=f1{:};
%            f2=config().log_files.rbelog(2); f2=f2{:};
%            f3=config().log_files.rbelog(3); f3=f3{:};
%             obj.draw_rbe_metric('rt',f1,f2,f3);
%             obj.draw_rbe_metric('through',f1,f2,f3);
%             obj.draw_rbe_metric('num_interact',f1,f2,f3);
%             obj.draw_rbe_metric('Intrvl',f1,f2,f3);
%             obj.draw_rbe_metric('num_users',f1,f2,f3);
             %obj.draw_rbe_metric('num_users',f1);
             num_users = obj.draw_rbe_metric_with_regression('num_users',f1);  
%             obj.draw_rbe_metric('errors',f1,f2,f3);


             f1=config().log_files.managerlog(1); f1=f1{:};
             f2=config().log_files.managerlog(2); f2=f2{:};
             f3=config().log_files.managerlog(3); f3=f3{:};
             %obj.draw_metric_with_regression('sessions',f1)
             utilization = obj.draw_cpu_idle(f1,f2,f3);
             %obj.draw_sessions(f1,f2,f3); 


             f1=config().log_files.managerlog(1); f1=f1{:};
             f2=config().log_files.managerlog(2); f2=f2{:};
             f3=config().log_files.managerlog(3); f3=f3{:};
             servers=obj.draw_servers(f1,f2,f3); 
            
        end %function
    end %methods 
        
end %class





% plot(res(:,instnum));
% title('Number of array instances');
% xlabel('Time');
% ylabel('Number of instances');
% axis([0 length(res) 0 6])
% u.print_figure(handle,9,7,strcat('./result/figure/',filestr,'/array_instance_number_time'));
% 
% plot(mean(res(:,utils)'));
% title('Average idle time over time');
% xlabel('Time');
% ylabel('CPU idle time');
% u.print_figure(handle,9,7,strcat('./result/figure/',filestr,'/avg_idle_ti
% me_over_time'));

% plot(res(:, through) );
% title('throughput over time');
% xlabel('Time');
% ylabel('Throughput (conn/sec)');
% u.print_figure(handle,9,7,strcat('./result/figure/',filestr,'/throughput_over_time'));
% 
% plot(res(:, num_users) );
% title('number of user over time');
% xlabel('Time');
% ylabel('Number of Users');
% u.print_figure(handle,9,7,strcat('./result/figure/',filestr,'/workload_over_time'));
% 
% plot(res(:, errors) );
% title('Errors  over time');
% xlabel('Time');
% ylabel('Error num');
% u.print_figure(handle,9,7,strcat('./result/figure/',filestr,'/error_over_time'));
 
%                 plot(w(:,ii) , strcat(color{ii},'-'));
%                 hold on;
%           legend('app1','app2','app3',3);

%draw_result.new().draw_rbe_metric('../myrbe/dist/log/Sun-Dec-05-02:18:06-UTC-2010.log') 
