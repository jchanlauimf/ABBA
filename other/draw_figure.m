function [b] = draw_figure (x,y,z,my_xtick, my_ytick, ...
    my_xlabel, my_xlim)

figure;
waterfall(x,y,z);
alpha(0.05);
set(gca,'FontSize',30);
set(gca,'XTick',my_xtick);
set(gca,'YTick',my_ytick);
% view([30 30]);  roe
% view([-20 20]); capital-ratio
%view([170 20]); % reserve ratio
view([145 30]); % capital ratio
xlabel(my_xlabel,'FontSize',30);
ylabel('Periods','FontSize',30);
xlim(my_xlim);
ylim([0 240]);
colormap(pink);
%colormap(bone);
%colormap(cool);
%shading interp;
%shading flat;
b='true';
end