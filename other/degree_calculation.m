function [b,c] = degree_calculation(A)
    [m,n]=size(A);
    n=sqrt(n);
    b=[];
    c=[];
    for i=1:m,
        d=A(i,:);
        d=reshape(d,n,n);
        d=d-eye(n);
        [deg indeg outdeg]=degrees(d);        
        b=[b; indeg];
        c=[c; outdeg];
    end
end