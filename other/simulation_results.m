function [b] = simulation_results(a,start_points, end_points, idx)
    
    b=[];
    for i=1:100,
        aux_mat = a(start_points(i,idx):end_points(i,idx),:);
        [m,n]=size(aux_mat);
        aux_mat = reshape(aux_mat,1,m*n);
        if (m*n<2400)
            aux_mat = [aux_mat, zeros(1,2400-m*n)];
        end
        b=[b ; aux_mat];
    end

end