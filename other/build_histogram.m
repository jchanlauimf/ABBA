function [c] = build_histogram(b, binrange)
    c=[];
    for i=1:240;

        % matrix d corresponds to the 100 runs and the 10 values per period
        % per run
        d = b(:,i:240:end);

        [m,n]=size(d);
        d = reshape(d,1,m*n);
        count = histc(d,binrange);
        c=[c; count];
    end
end