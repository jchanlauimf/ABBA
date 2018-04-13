function [b] = simulation_results_interbank(a,start_points, end_points, idx)
    
    b=[];
    for i=1:100,
        aux_mat = a(start_points(i,idx):end_points(i,idx),:);
        [m,n]=size(aux_mat);
        aux_mat = reshape(aux_mat',1,m*n);
        if(m<240)
            m_dif=240-m;
            eye_m=eye(10);
            eye_m=reshape(eye_m,1,10*10);
            fill_m=[];
            for j=1:m_dif,
                fill_m=[fill_m eye_m];
            end, 
            aux_mat=[aux_mat,fill_m];            
        end,        
        b=[b ; aux_mat];        
    end
end