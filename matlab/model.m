classdef model    < handle
 properties
     samplingTime = 60;
    m_utilization, m_servers, m_num_users;
    price_per_vm_hour;
    vm_instantiation_time;
 end
 
 methods
     function obj=model
         obj.samplingTime = 60;
         obj.price_per_vm_hour=0.08; %dollars
         obj.vm_instantiation_time=8;  %minutes
     end
     
    function [m_x,d_x]=linearize(obj,x)
        m_x = mean(x);  
        d_x = x-m_x;  
    end

    function d_x=linearize_around(obj,x,m_x)
        d_x = x-m_x;  
    end

    % transfer function model of the behavior: workload+servers-> utilization
    % x=[num_users; num_servers]
    % y = avg_utilization
    % State-space model:  
    %         x(t+Ts) = A x(t) + B u(t) + K e(t)
    %         y(t) = C x(t) + D u(t) + e(t)
    function mm=identify_system(obj,data)        
        A=[1,-1; 0,1];
        B=[2,3;4,5];
        K=[4;5];
        C=[1,0];
        D=[1 1];

        m=idss(A,B,C,D,K,'Ts',obj.samplingTime);
        %m1=init(m);
        %m.As=[NaN,NaN;NaN,NaN];
        % m.Bs=[NaN,3;NaN,5];
        % m.Ks=[NaN;5];
        % m.Cs=[NaN,NaN];
        % m.Ds=[NaN NaN];
        % m.x0s=[0; 0 ;1];
        m1=init(m);
        mm=pem(data,m1);      
    end

    
    function u=combineInputs(obj, d_servers_test , d_num_users)
        u =  [d_servers_test  d_num_users]; 
    end
    
    function mm=identifyModel(obj)
        load a_sample.mat
        intrvl=(1:219);

        % linearization 
        utilization=utilization(1,intrvl)' ;
        servers=servers(1,intrvl)' ;
        num_users= num_users(intrvl)'; 
        [obj.m_utilization,d_utilization]= obj.linearize(utilization);
        [obj.m_servers, d_servers] = obj.linearize(servers);
        [obj.m_num_users,d_num_users] = obj.linearize(num_users); 

        u =  [d_servers  d_num_users];
        y = d_utilization;
        % % u =  [servers  num_users];
        % % y = utilization;
        data=iddata(y,  u ,obj.samplingTime); 
        mm=obj.identify_system(data);        
    end
    
    function plot_compare_simple(obj,y1,y2)
        plot(obj.m_utilization + y1.OutputData,'g--');        hold on; 
        plot(obj.m_utilization + y2.OutputData,'r--');      
    end
    
    function plotit(obj,y,yn)
%         scatter(data.OutputData,y.OutputData);
%         plot( y.OutputData,'r--'); hold on; plot(data.OutputData);

        subplot(3,1,1); 
        plot(m_utilization + y.OutputData,'g--');        hold on; 
        plot(m_utilization + yn.OutputData,'r--');         hold on; 
        plot(m_utilization +data.OutputData);
        title('measured/modeled Utilizations')

        subplot(3,1,2); 
        plot(m_servers+data.InputData(:,1))
        title('#Servers')

        subplot(3,1,3); 
        plot(m_num_users+data.InputData(:,2))
        title('#Users')
    end

    % servers variable is a sequence over an interval of minute unit 
    % we are going to sweep through the time
    function servers=per_hour_cost_filter(obj,servers_) 
       % servers = [ones(1,45) 2.*ones(1,20)];
        servers=[0 servers_ zeros(1,60)];        
        T =size(servers , 2); 
         for t=1:T+60             
                if (t<T && servers(t+1)>servers(t)) %any time there is a scaleup
                    disp('hi')
                    % make sure the result of scaleup is accounted for, for 60 minutes
                    servers(t+1:t+60) = max(servers(t+1:t+60),servers(t+1)); 
                end
         end         
    end
    
    function cost_=cost(obj,servers_)
        hours=(sum(obj.per_hour_cost_filter(servers_))/60);
        cost_ = hours * obj.price_per_vm_hour;
    end
    
    % response time for a specific service rate
    function rt_=rt_static(obj,util,mu)
        rt_=(1/(1-util))*(1/mu);
    end    
    
    % this gives you almost the cdf
    % to get inverse sample for a population of users 
    % use 1-prob as a cdf 
    function prob_=prob_of_rt_more_than(obj,rt,T)
        prob_ = exp(1).^(-T/rt);
    end
    
    % this will take effect in 8 minutes
    function how_many_to_add=decide(obj)
        
    end
    
    function simuate(obj)
        intrvl=(1:219);
        obj.vm_instantiation_time;
    end
        
    function mm=all(obj)
        intrvl=(1:219);
        mm=obj.identifyModel;
        
        load a_sample.mat        
        d_num_users = obj.linearize_around(num_users(intrvl)' , obj.m_num_users);        

        % modeled utilization with a new sequence of server num
        d_servers_test1= obj.linearize_around(([3.*ones(1,100) 5.*ones(1,119)]   )',obj.m_servers);
        u = obj.combineInputs(d_servers_test1,  d_num_users);
        data=iddata([],  u , obj.samplingTime);                         
        y = sim(mm,data); % simulates with input data
        
         % modeled utilization with original sequence of server num
        d_servers_test2= obj.linearize_around(servers(1,intrvl)', obj.m_servers);
        u = obj.combineInputs(d_servers_test2,  d_num_users);
        data=iddata([],  u , obj.samplingTime);                         
        y_orig = sim(mm,data); % simulates with input data

        % original utilization from the dataset
        utilization=utilization(1,intrvl)' ;
        [obj.m_utilization,d_utilization]= obj.linearize(utilization);
        y = d_utilization;
        data=iddata(y,  [] ,obj.samplingTime); 

        obj.plot_compare_simple(data,y_orig);
        
        % yn = sim(mm,data,'noise'); % simulates with input data with noise       
    end    
    
 end
end

