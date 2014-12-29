classdef draw_result
    properties
                header = {'month' 'day' 'hour' 'minute' 'reqnum'};
                m=struct('month', 1 ,'day', 2,'hour', 3,'minute', 4,'reqnum', 5)
    end
    
    methods
        function res=cum_and(obj,m)
            [i j]=size(m);
            res=ones(i,1);
            for k =1:j
                res = res & m(:,k); 
            end                
        end
        
        function res=cum_or(obj,m)
            [i j]=size(m);
            res=zeros(i,1);
            for k =1:j
                res = res | m(:,k); 
            end                
        end
        
        function num=count(obj,m)
            num=size(m,1);
        end
        
        function res=select(obj,m,col_gr,val)
            res = [];
            for k=1:size(m,1)
                if obj.cum_and(m(k,col_gr)==val)
                    res = [res ; m(k,:)];
                end
            end
        end
        
        function [table]=project(obj,m,col_gr)
            B = sortrows(m,col_gr);
            sortedbuckets=B(:,col_gr);
            table = unique(sortedbuckets,'rows');
        end
        
        function [table]=groupby(obj,m,col_gr,col_val)
            B = sortrows(m,col_gr);
            sortedbuckets=B(:,col_gr);
            n=size(sortedbuckets,1);
            distinctbuckets(:,1:n) = 1;
            distinctbuckets(2:n) = obj.cum_or( sortedbuckets(1:n-1,:) ~= sortedbuckets(2:n,:) );
            uniquebuckets=cumsum(distinctbuckets);
            total=accumarray(uniquebuckets',B(:,col_val));
            table = [unique(sortedbuckets,'rows') total];
        end
        
        function [data]=load_data(obj,file)     
            fid = fopen(strcat('../data/', file));
            tline = fgetl(fid);
            data = [];
            while (ischar(tline))
                [tok mat] = regexp(tline,'(\d+)?-(\d+)?-(\d+)?-(\d+)?\t(\d+)?','tokens', 'match');
                if (~(isempty(tok)))       
                    data = [ data ; str2num(char(tok{:}))'];
                end    
                tline = fgetl(fid);
            end
            fclose(fid);
        end
    
        function test_groupby(obj)
            m=[4    15    22    36   133
                 4    15    22    37   155
                 4    15    23    52   137
                 4    15    23    53   126
                 4    15    23    54   148 ]; 
              
              obj.groupby(m,(1:3),5)
        end %test groupby
        
        function [coefs,sols]=testall(obj)
                m= obj.load_data;
                % res=obj.groupby(m,(1:3),5);                
                %k=1;
                coefs = [];
                sols = [];
                for k=sortrows(obj.project(m,(1:3)))'   
                     res = sortrows(obj.select(m,(1:3),k'),(1:4));
                     %res = sortrows(res,(1:4));   
                     coef = corrcoef(res(:,4),res(:,5));
                     coefs = [coefs coef(1,2)];                     
                     
                     X1 = [ones(size(res,1),1) res(:,4)];
                     y = res(:,5);
                     sol = (X1\y);
                     sols = [sols sol(2,1)]; %(1,1) is the 1s coef
                end                
        end
        
        function plotit(obj)           
                hours = 24;
                m= obj.load_data('day41_per_minute.txt');
                header = {'month' 'day' 'hour' 'minute' 'reqnum'};
                lab=struct('month', 1 ,'day', 2,'hour', 3,'minute', 4,'reqnum', 5)
                u=UtilityLib();
                handle = figure;
                
                subplot(3,hours,1:2*hours) 
                between = (3 * 60 : 15 *60) ;
                plot(m(between ,lab.reqnum));                
                title('Number of users over time');
                xlabel('Time(minutes)');
                ylabel('Number of users');
                %axis([0 length(res) 0 6])

                pl_num = 2*hours+1;
                coefs = [];
                sols = [];                                
                temp = sortrows(obj.project(m,(1:3)));
                for k=   temp((1:hours),:)'
                    subplot(3,hours,pl_num); 
                    pl_num = pl_num +1;                    
                     res = sortrows(obj.select(m,(1:3),k'),(1:4));
                     %res = sortrows(res,(1:4));   
                     coef = corrcoef(res(:,4),res(:,5));
                     coefs = [coefs coef(1,2)];                     
                     
                     X1 = [ones(size(res,1),1) res(:,4)];
                     y = res(:,5);
                     sol = (X1\y);
                     sols = [sols sol(2,1)]; %(1,1) is the 1s coef
                     line([0;1],[sol(1,1); sol(1,1)+sol(2,1)],[1;1]);
                     axis([0 1 sol(1,1)-1 sol(1,1)+1])
                      set(gca,'YTick',[]); set(gca,'YColor','w');
                      set(gca,'XTick',[]); set(gca,'XColor','w');
                end                

                %set(gca,'Visible','off')
                %u.print_figure(handle,9,7,strcat('./result/figure/',filestr,'/array_instance_number_time'));
        end %plotit 

        % draw_result().get_raw_form('day41-raw.txt','day41_per_minute.txt' )
        function get_raw_form(obj,infile,outfile)           
                hours = 24;
                m= obj.load_data(infile);
                header = {'month' 'day' 'hour' 'minute' 'reqnum'};
                lab=struct('month', 1 ,'day', 2,'hour', 3,'minute', 4,'reqnum', 5)
                
                fid = fopen(outfile,'w');
                between = (3 * 60 : 15 *60) ;              
               fprintf(fid, '%14.0d', m(between,lab.reqnum)); 
               fclose(fid)
        end
   
        function test_plot(obj)
            obj
             subplot(2,4,1:4)
              subplot(2,4,5)
        end
        
    end %static methods
end %class



