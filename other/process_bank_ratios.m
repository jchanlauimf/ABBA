% process_bank_ratios.m
% 
% November 2014
% This program processes the bank ratios
%
% The variables in the ascii file are:
%
% 1.  Run number
% 
% Afterwards, for each of the ten banks
%
% 2.  Regulatory CAR
% 3.  Minimum regulatory reserves ratio
% 4.  Actual CAR
% 5.  Reserves ratio
% 6.  Leverage ratio
% 7.  upper-bound-capital-ratio
% 8.  buffer-reserves-ratio
% 9.  bank-dividend
% 10. cumulative dividends
% 11. bank-loans
% 12. bank-reserves
% 13. bank-deposits
% 14. equity
% 15. total-assets
% 16. rwassets
% 17. credit-failure indicator
% 18. liquidity failure indicator

%
%
% 
%% Read data and assign values to parameters
clear all; clc;
csv_file_name = 'f:/netlogo/bank_ratios_complete.csv';
load(csv_file_name);
bank_ratio_data = bank_ratios_complete;
CAR = [0.04 0.08 0.12 0.16];
mRR = [0.03 0.045 0.06];

nCAR = length(CAR);
nmRR = length(mRR);
n_banks = size(bank_ratio_data(:,2:end), 2)/17;
[m,n]=size(bank_ratio_data);

%% Prepare aggregate graphics
%
%  Pooled capital_ratios

idx_capital_ratio = 4:17:n;
idx_reserve_ratio = 5:17:n;
idx_equity = 14:17:n;
idx_credit_failure = 17:17:n;
idx_liquidity_failure = 18:17:n;
idx_bank_dividend = 9:17:n;
idx_bank_loans = 11:17:n;

idx04030 = find(bank_ratio_data(:,2)==0.04 & bank_ratio_data(:,3)==0.030);
idx04045 = find(bank_ratio_data(:,2)==0.04 & bank_ratio_data(:,3)==0.045);
idx04060 = find(bank_ratio_data(:,2)==0.04 & bank_ratio_data(:,3)==0.060);

idx08030 = find(bank_ratio_data(:,2)==0.08 & bank_ratio_data(:,3)==0.030);
idx08045 = find(bank_ratio_data(:,2)==0.08 & bank_ratio_data(:,3)==0.045);
idx08060 = find(bank_ratio_data(:,2)==0.08 & bank_ratio_data(:,3)==0.060);

idx12030 = find(bank_ratio_data(:,2)==0.12 & bank_ratio_data(:,3)==0.030);
idx12045 = find(bank_ratio_data(:,2)==0.12 & bank_ratio_data(:,3)==0.045);
idx12060 = find(bank_ratio_data(:,2)==0.12 & bank_ratio_data(:,3)==0.060);

idx16030 = find(bank_ratio_data(:,2)==0.16 & bank_ratio_data(:,3)==0.030);
idx16045 = find(bank_ratio_data(:,2)==0.16 & bank_ratio_data(:,3)==0.045);
idx16060 = find(bank_ratio_data(:,2)==0.16 & bank_ratio_data(:,3)==0.060);

%% find number of occurrences for each run for a given CAR and MRR
%
%  N(i,j) = number of total periods in simulation 

N_simulations = zeros(100,nCAR*nmRR);

for i=1:100,
    
    N_simulations(i,1) = length(find(bank_ratio_data(idx04030,1)==i));
    N_simulations(i,2) = length(find(bank_ratio_data(idx04045,1)==i));    
    N_simulations(i,3) = length(find(bank_ratio_data(idx04060,1)==i));    
    
    N_simulations(i,4) = length(find(bank_ratio_data(idx08030,1)==i));
    N_simulations(i,5) = length(find(bank_ratio_data(idx08045,1)==i));    
    N_simulations(i,6) = length(find(bank_ratio_data(idx08060,1)==i));    

    N_simulations(i,7) = length(find(bank_ratio_data(idx12030,1)==i));
    N_simulations(i,8) = length(find(bank_ratio_data(idx12045,1)==i));    
    N_simulations(i,9) = length(find(bank_ratio_data(idx12060,1)==i));    
    
    N_simulations(i,10) = length(find(bank_ratio_data(idx16030,1)==i));
    N_simulations(i,11) = length(find(bank_ratio_data(idx16045,1)==i));    
    N_simulations(i,12) = length(find(bank_ratio_data(idx16060,1)==i));    
    
end


%% Cumulative sum of N_simulations to isolate each run
N_end_points = cumsum(N_simulations);

%% Structures saving capital ratio, reserve ratio, equity, and dividend
%  data

capital_ratio = struct( ...
    'c01', bank_ratio_data(idx04030,idx_capital_ratio), ...
    'c02', bank_ratio_data(idx04045,idx_capital_ratio), ...
    'c03', bank_ratio_data(idx04060,idx_capital_ratio), ...
    'c04', bank_ratio_data(idx08030,idx_capital_ratio), ...
    'c05', bank_ratio_data(idx08045,idx_capital_ratio), ...
    'c06', bank_ratio_data(idx08060,idx_capital_ratio), ...
    'c07', bank_ratio_data(idx12030,idx_capital_ratio), ...
    'c08', bank_ratio_data(idx12045,idx_capital_ratio), ...
    'c09', bank_ratio_data(idx12060,idx_capital_ratio), ...
    'c10', bank_ratio_data(idx16030,idx_capital_ratio), ...
    'c11', bank_ratio_data(idx16045,idx_capital_ratio), ...
    'c12', bank_ratio_data(idx16060,idx_capital_ratio));

reserve_ratio = struct( ...
    'c01', bank_ratio_data(idx04030,idx_reserve_ratio), ...
    'c02', bank_ratio_data(idx04045,idx_reserve_ratio), ...
    'c03', bank_ratio_data(idx04060,idx_reserve_ratio), ...
    'c04', bank_ratio_data(idx08030,idx_reserve_ratio), ...
    'c05', bank_ratio_data(idx08045,idx_reserve_ratio), ...
    'c06', bank_ratio_data(idx08060,idx_reserve_ratio), ...
    'c07', bank_ratio_data(idx12030,idx_reserve_ratio), ...
    'c08', bank_ratio_data(idx12045,idx_reserve_ratio), ...
    'c09', bank_ratio_data(idx12060,idx_reserve_ratio), ...
    'c10', bank_ratio_data(idx16030,idx_reserve_ratio), ...
    'c11', bank_ratio_data(idx16045,idx_reserve_ratio), ...
    'c12', bank_ratio_data(idx16060,idx_reserve_ratio));

equity = struct( ...
    'c01', bank_ratio_data(idx04030,idx_equity), ...
    'c02', bank_ratio_data(idx04045,idx_equity), ...
    'c03', bank_ratio_data(idx04060,idx_equity), ...
    'c04', bank_ratio_data(idx08030,idx_equity), ...
    'c05', bank_ratio_data(idx08045,idx_equity), ...
    'c06', bank_ratio_data(idx08060,idx_equity), ...
    'c07', bank_ratio_data(idx12030,idx_equity), ...
    'c08', bank_ratio_data(idx12045,idx_equity), ...
    'c09', bank_ratio_data(idx12060,idx_equity), ...
    'c10', bank_ratio_data(idx16030,idx_equity), ...
    'c11', bank_ratio_data(idx16045,idx_equity), ...
    'c12', bank_ratio_data(idx16060,idx_equity));

bank_dividend = struct( ...
    'c01', bank_ratio_data(idx04030,idx_bank_dividend), ...
    'c02', bank_ratio_data(idx04045,idx_bank_dividend), ...
    'c03', bank_ratio_data(idx04060,idx_bank_dividend), ...
    'c04', bank_ratio_data(idx08030,idx_bank_dividend), ...
    'c05', bank_ratio_data(idx08045,idx_bank_dividend), ...
    'c06', bank_ratio_data(idx08060,idx_bank_dividend), ...
    'c07', bank_ratio_data(idx12030,idx_bank_dividend), ...
    'c08', bank_ratio_data(idx12045,idx_bank_dividend), ...
    'c09', bank_ratio_data(idx12060,idx_bank_dividend), ...
    'c10', bank_ratio_data(idx16030,idx_bank_dividend), ...
    'c11', bank_ratio_data(idx16045,idx_bank_dividend), ...
    'c12', bank_ratio_data(idx16060,idx_bank_dividend));

%% save field names in a string array
fn = fieldnames(bank_dividend);

%% Auxiliary calculations
N_start_points = N_end_points +1;
N_start_points = N_start_points(1:end-1,:);
N_start_points = [zeros(1,12)+1; N_start_points];

%% Create the simulation matrices 100 x 2400
%
% each row corresponds to one run, 240 periods for one bank, 10 banks
% first 240 periods corresponds to bank 1, second 240 periods, second bank
%

capital_ratio_simulations = struct( ...
'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

for i=1:length(fn)
    a=capital_ratio.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    % notice we set the subscript to 1 in the next line so the 
    % structure is 1 x 1 -only one element
    capital_ratio_simulations(1).(fn{i}) = b;    
end

reserve_ratio_simulations = struct( ...
'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

for i=1:length(fn)
    a=reserve_ratio.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    reserve_ratio_simulations(1).(fn{i}) = b;    
end

equity_simulations = struct( ...
'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

for i=1:length(fn)
    a=equity.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    equity_simulations(1).(fn{i}) = b;    
end

bank_dividend_simulations = struct( ...
'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

for i=1:length(fn)
    a=bank_dividend.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    bank_dividend_simulations(1).(fn{i}) = b;    
end

%% Other way to create the structure
bank_ratios = struct(...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});
for i=1:length(fn)
    a=capital_ratio.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    bank_ratios(1).(fn{i}) = b;    
    a=reserve_ratio.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    bank_ratios(2).(fn{i}) = b;    
    a=equity.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    bank_ratios(3).(fn{i}) = b;    
    a=bank_dividend.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    bank_ratios(4).(fn{i}) = b;    
end    

%% calculate return on equity

return_on_equity = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});
    
for i=1:length(fn)
    this_equity = equity_simulations(1).(fn{i});
    this_dividend=bank_dividend_simulations(1).(fn{1});
    roe=zeros(size(this_equity));
    [thisrow thiscol]=find(this_equity > 0);
    n_points =length(thisrow);
    for nrow =1:n_points,
        ii = thisrow(nrow);
        jj = thiscol(nrow);
        roe(ii,jj) = this_dividend(ii,jj)/this_equity(ii,jj);
    end,   
    return_on_equity(1).(fn{i}) = roe;
end

%% create index to eliminate first 32 observations
%
% not needed
aux_idx=[33:240];
idx_wo_32=[aux_idx];
for i=1:9
    aux_idx=aux_idx+240;
    idx_wo_32=[idx_wo_32 aux_idx];
end

%% create histograms figures
binrange = 0:0.001:0.20;
xaxis_label = 'Capital ratio, in percent';
y=33:1:240;
xtick=0:2:20;
ytick=0:60:240;
% capital ratios
for i=1:length(fn)
    if i<10 xtick = 0:2:20; xlim=[0 20]; binrange=0:0.001:0.20;
      else xtick = 0:2:26; xlim=[0 26]; binrange=0:0.001:0.26;
    end
    b=capital_ratio_simulations(1).(fn{i});    
    [c]=build_histogram(b,binrange);
    idx_c=[33:240];
    draw_figure(binrange*100,y,c(idx_c,:)/10,xtick,ytick,xaxis_label,xlim);
end

%% Average capital-ratio per period

idx_0 = [33:240];
idx_wo_32=[idx_0];

for i=1:9,
    idx_0=idx_0+240;
    idx_wo_32=[idx_wo_32, idx_0];
end


mean_car_per_period =[];
for i=1:length(fn);
    b=capital_ratio_simulations(1).(fn{i});
    a=[];
    for j=1:240,
        a=[a mean(mean(b(:,j:240:end)))];    
    end,
    mean_car_per_period=[mean_car_per_period; a];
end,

mean_car_per_regime = mean(mean_car_per_period,2);
mean_car_per_regime= reshape(mean_car_per_regime,3, 4);

figure;
bar(mean_car_per_regime*100);
set(gca,'XTickLabel',{'3.0' '4.5' '6.0'});
set(gca, 'FontSize',20);
h_legend=legend('CAR 0.04','CAR 0.08','CAR 0.12','CAR 0.16');
set(h_legend,'FontSize',14);
legend('Location','Northwest');
legend('boxoff');
xlabel('Minimum reserve ratio, percent','FontSize',20);
ylabel('Mean capital ratio, in percent','FontSize',20);

%% create histograms figures - reserve ratio
binrange = 0:0.0025:0.12;
xaxis_label = 'reserve ratio, in percent';
y=33:1:240;
xtick=0:2:12;
ytick=0:60:240;
xlim = [0 12];
% capital ratios
for i=1:length(fn)
    %if i<10 xtick = 0:2:20; xlim=[0 20]; binrange=0:0.001:0.20;
    %  else xtick = 0:2:26; xlim=[0 26]; binrange=0:0.001:0.26;
    %end
    b=reserve_ratio_simulations(1).(fn{i});    
    [c]=build_histogram(b,binrange);
    idx_c=[33:240];
    draw_figure(binrange*100,y,c(idx_c,:)/10,xtick,ytick,xaxis_label,xlim);
end

%% Average reserve-ratio per period

idx_0 = [33:240];
idx_wo_32=[idx_0];

for i=1:9,
    idx_0=idx_0+240;
    idx_wo_32=[idx_wo_32, idx_0];
end


mean_mrr_per_period =[];
for i=1:length(fn);
    b=reserve_ratio_simulations(1).(fn{i});
    a=[];
    for j=1:240,
        a=[a mean(mean(b(:,j:240:end)))];    
    end,
    mean_mrr_per_period=[mean_mrr_per_period; a];
end,

mean_mrr_per_regime = mean(mean_mrr_per_period,2);
mean_mrr_per_regime= reshape(mean_mrr_per_regime,3, 4);

figure;
bar(mean_mrr_per_regime*100);
set(gca,'XTickLabel',{'3.0' '4.5' '6.0'});
set(gca, 'FontSize',16);
h_legend=legend('CAR 0.04','CAR 0.08','CAR 0.12','CAR 0.16');
set(h_legend,'FontSize',14,'Location','Northwest');
legend('boxoff');
xlabel('Minimum reserve ratio, percent','FontSize',16);
ylabel('Mean reserve ratio, in percent','FontSize',16);


%% create histograms figures roe
binrange = 0:0.005:0.25;
xaxis_label = 'return on equity, in percent';
y=33:1:240;
xtick=0:0.05:0.25;
xtick=xtick*100;
ytick=0:40:240;
xlim = [0 0.25]*100;
% capital ratios
for i=1:length(fn)
    %if i<10 xtick = 0:2:20; xlim=[0 20]; binrange=0:0.001:0.20;
    %  else xtick = 0:2:26; xlim=[0 26]; binrange=0:0.001:0.26;
    %end
    b=return_on_equity(1).(fn{i});    
    [c]=build_histogram(b,binrange);
    idx_c=[33:240];
    draw_figure(binrange*100,y,c(idx_c,:)/10,xtick,ytick,xaxis_label,xlim);
end

%% Average ROE per period

idx_0 = [33:240];
idx_wo_32=[idx_0];

for i=1:9,
    idx_0=idx_0+240;
    idx_wo_32=[idx_wo_32, idx_0];
end


mean_roe_per_period =[];
for i=1:length(fn);
    b=return_on_equity(1).(fn{i});
    a=[];
    for j=1:240,
        a=[a mean(mean(b(:,j:240:end)))];    
    end,
    mean_roe_per_period=[mean_roe_per_period; a];
end,

mean_roe_per_regime = mean(mean_roe_per_period,2);
mean_roe_per_regime= reshape(mean_roe_per_regime,3, 4);

figure;
bar(mean_roe_per_regime*100);
set(gca,'XTickLabel',{'3.0' '4.5' '6.0'});
set(gca, 'FontSize',30);
h_legend=legend('CAR 0.04','CAR 0.08','CAR 0.12','CAR 0.16');
set(h_legend,'FontSize',20);
legend('boxoff');
xlabel('Minimum reserve ratio, percent','FontSize',30);
ylabel('Return on equity, percent','FontSize',30);




%% eliminate the first 32 observations

idx_0 = [33:240];
idx_wo_32=[idx_0];

for i=1:9,
    idx_0=idx_0+240;
    idx_wo_32=[idx_wo_32, idx_0];
end

%% find number of failures

credit_failure = struct( ...
    'c01', bank_ratio_data(idx04030,idx_credit_failure), ...
    'c02', bank_ratio_data(idx04045,idx_credit_failure), ...
    'c03', bank_ratio_data(idx04060,idx_credit_failure), ...
    'c04', bank_ratio_data(idx08030,idx_credit_failure), ...
    'c05', bank_ratio_data(idx08045,idx_credit_failure), ...
    'c06', bank_ratio_data(idx08060,idx_credit_failure), ...
    'c07', bank_ratio_data(idx12030,idx_credit_failure), ...
    'c08', bank_ratio_data(idx12045,idx_credit_failure), ...
    'c09', bank_ratio_data(idx12060,idx_credit_failure), ...
    'c10', bank_ratio_data(idx16030,idx_credit_failure), ...
    'c11', bank_ratio_data(idx16045,idx_credit_failure), ...
    'c12', bank_ratio_data(idx16060,idx_credit_failure));

liquidity_failure = struct( ...
    'c01', bank_ratio_data(idx04030,idx_liquidity_failure), ...
    'c02', bank_ratio_data(idx04045,idx_liquidity_failure), ...
    'c03', bank_ratio_data(idx04060,idx_liquidity_failure), ...
    'c04', bank_ratio_data(idx08030,idx_liquidity_failure), ...
    'c05', bank_ratio_data(idx08045,idx_liquidity_failure), ...
    'c06', bank_ratio_data(idx08060,idx_liquidity_failure), ...
    'c07', bank_ratio_data(idx12030,idx_liquidity_failure), ...
    'c08', bank_ratio_data(idx12045,idx_liquidity_failure), ...
    'c09', bank_ratio_data(idx12060,idx_liquidity_failure), ...
    'c10', bank_ratio_data(idx16030,idx_liquidity_failure), ...
    'c11', bank_ratio_data(idx16045,idx_liquidity_failure), ...
    'c12', bank_ratio_data(idx16060,idx_liquidity_failure));

credit_failure_simulations = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

liquidity_failure_simulations = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

for i=1:length(fn)
    a=credit_failure.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    credit_failure_simulations(1).(fn{i}) = b;    
    a=liquidity_failure.(fn{i});
    [b]=simulation_results(a,N_start_points,N_end_points, i);
    liquidity_failure_simulations(1).(fn{i}) = b;        
end

%% credit and liquidity failures

credit_failures_count = zeros (length(fn),1);
liquidity_failures_count = zeros(length(fn),1);
credit_failures_pct = zeros(length(fn),1);
liquidity_failures_pct = zeros(length(fn),1);

for i=1:length(fn)
    a = credit_failure_simulations(1).(fn{i});
    [m,n]=size(a);
    a=find(a(:,idx_wo_32)>0);
    credit_failures_count(i)=length(a);
    credit_failures_pct(i) = length(a)/(m*n);
    
    a = liquidity_failure_simulations(1).(fn{i});
    [m,n]=size(a);
    a=find(a(:,idx_wo_32)>0);
    liquidity_failures_count(i)=length(a);
    liquidity_failures_pct(i) = length(a)/(m*n);
end

%% interbank exposures

csv_file_name = 'interbank_exposure_complete.csv';
load(csv_file_name);
IB_exposure = interbank_exposure_complete;
clearvars interbank_exposure_complete;

IB_exposure_cases = struct( ...
    'c01', IB_exposure(idx04030,:), ...
    'c02', IB_exposure(idx04045,:), ...
    'c03', IB_exposure(idx04060,:), ...
    'c04', IB_exposure(idx08030,:), ...
    'c05', IB_exposure(idx08045,:), ...
    'c06', IB_exposure(idx08060,:), ...
    'c07', IB_exposure(idx12030,:), ...
    'c08', IB_exposure(idx12045,:), ...
    'c09', IB_exposure(idx12060,:), ...
    'c10', IB_exposure(idx16030,:), ...
    'c11', IB_exposure(idx16045,:), ...
    'c12', IB_exposure(idx16060,:));

IB_exposure_simulations = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

for i=1:length(fn)
    a=IB_exposure_cases.(fn{i});
    a=a(:,2:end);    
    [b]=simulation_results_interbank(a,N_start_points,N_end_points, i);
    IB_exposure_simulations(1).(fn{i}) = b;    
end

%% 
% Rebuilding the exposure matrix\
%
%  get [var].c01
%  reshape [240 x 100]
%  go row by row 
%  reshape row [10 x 10]
%  calculate degrees

In_degree = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

Out_degree = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

for i=1:length(fn)
    a=IB_exposure_simulations.(fn{i});
    indeg=[];
    outdeg=[];
    for j=1:100
        aa=a(j,:);
        aa=reshape(aa,100,240);
        aa=aa';
        aa=(aa>0);        
        [b, c]=degree_calculation(aa);
        indeg=[indeg; b];
        outdeg=[outdeg; c];
    end,
    In_degree(1).(fn{i})=indeg;
    Out_degree(1).(fn{i})=outdeg;
end


%% Simple statistics - Interconnectedness

idx_0 = [33:240];
idx_wo_32=[idx_0];

for i=1:9,
    idx_0=idx_0+240;
    idx_wo_32=[idx_wo_32, idx_0];
end

c=[];
for i=1:length(fn);
    H=In_degree.(fn{i});    
    H=H(idx_wo_32,:);
    [m,n]=size(H);
    H=reshape(H,m*n,1);
    b=[];
    for j=0:10,
        b=[b sum(H==j)]; 
    end,
    b=b/length(H)*100;   
    c=[c;b];
end,
In_degree_pct = c;

c=[];
for i=1:length(fn);
    H=Out_degree.(fn{i});    
    H=H(idx_wo_32,:);
    [m,n]=size(H);
    H=reshape(H,m*n,1);
    b=[];
    for j=0:10,
        b=[b sum(H==j)]; 
    end,
    b=b/length(H)*100;   
    c=[c;b];
end,
Out_degree_pct = c;




%%
% Histograms for in-degree and out-degree

idx_0 = [33:240];
idx_wo_32=[idx_0];

for i=1:9,
    idx_0=idx_0+240;
    idx_wo_32=[idx_wo_32, idx_0];
end

figure;

for i=1:length(fn)
    subplot(4,3,i);
    H=In_degree.(fn{i});    
    H=H(idx_wo_32,:);
    H=sum(H,2);
    hist(H,40);    
end,

figure;

for i=1:length(fn)
    subplot(4,3,i);
    H=In_degree.(fn{i});    
    H=H(idx_wo_32,:);
    [m,n]=size(H);
    H=reshape(H,m*n,1);
    hist(H,10);    
end,

figure;

for i=1:length(fn)
    subplot(4,3,i);
    H=Out_degree.(fn{i});    
    H=H(idx_wo_32,:);
    H=sum(H,2);
    hist(H,40);    
end,

figure;

for i=1:length(fn)
    subplot(4,3,i);
    H=Out_degree.(fn{i});    
    H=H(idx_wo_32,:);
    [m,n]=size(H);
    H=reshape(H,m*n,1);
    hist(H,10);    
end,

%% Interconnectedness
%
% In_degree  (240x100) x 10 
% Runs stored in columns first.
% Percent of time has in-degrees or out-degres of order x or above
% 

In_degree_pct_bank = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});


n_run = 100;
n_period = 240;

for i=1:length(fn)
    a=In_degree.(fn{i});
    c0=[];c1=[]; c2=[];c3=[]; c4=[]; 
    c5=[]; c6=[]; c7=[]; c8=[]; c9=[]; 
    for j=1:n_run
        aa=a((j-1)*n_period+1: j*n_period,:);
        c0=[c0; sum(aa==0)./sum(aa>-1)*100];
        c1=[c1; sum(aa==1)./sum(aa>-1)*100];
        c2=[c2; sum(aa==2)./sum(aa>-1)*100];
        c3=[c3; sum(aa==3)./sum(aa>-1)*100];                      
        c4=[c4; sum(aa==4)./sum(aa>-1)*100];
        c5=[c5; sum(aa==5)./sum(aa>-1)*100];
        c6=[c6; sum(aa==6)./sum(aa>-1)*100];                      
        c7=[c7; sum(aa==7)./sum(aa>-1)*100];
        c8=[c8; sum(aa==8)./sum(aa>-1)*100];
        c9=[c9; sum(aa==9)./sum(aa>-1)*100];                      
    end
    In_degree_pct_bank(1).(fn{i}).link0 = c0;    
    In_degree_pct_bank(1).(fn{i}).link1 = c1;    
    In_degree_pct_bank(1).(fn{i}).link2 = c2;    
    In_degree_pct_bank(1).(fn{i}).link3 = c3;    
    In_degree_pct_bank(1).(fn{i}).link4 = c4;    
    In_degree_pct_bank(1).(fn{i}).link5 = c5;    
    In_degree_pct_bank(1).(fn{i}).link6 = c6;    
    In_degree_pct_bank(1).(fn{i}).link7 = c7;    
    In_degree_pct_bank(1).(fn{i}).link8 = c8;    
    In_degree_pct_bank(1).(fn{i}).link9 = c9;        
end,

Out_degree_pct_bank = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});


for i=1:length(fn)
    a=Out_degree.(fn{i});
    c0=[];c1=[]; c2=[];c3=[]; c4=[]; 
    c5=[]; c6=[]; c7=[]; c8=[]; c9=[]; 
    for j=1:n_run
        aa=a((j-1)*n_period+1: j*n_period,:);
        c0=[c0; sum(aa==0)./sum(aa>-1)*100];
        c1=[c1; sum(aa==1)./sum(aa>-1)*100];
        c2=[c2; sum(aa==2)./sum(aa>-1)*100];
        c3=[c3; sum(aa==3)./sum(aa>-1)*100];                      
        c4=[c4; sum(aa==4)./sum(aa>-1)*100];
        c5=[c5; sum(aa==5)./sum(aa>-1)*100];
        c6=[c6; sum(aa==6)./sum(aa>-1)*100];                      
        c7=[c7; sum(aa==7)./sum(aa>-1)*100];
        c8=[c8; sum(aa==8)./sum(aa>-1)*100];
        c9=[c9; sum(aa==9)./sum(aa>-1)*100];                      
    end
    Out_degree_pct_bank(1).(fn{i}).link0 = c0;    
    Out_degree_pct_bank(1).(fn{i}).link1 = c1;    
    Out_degree_pct_bank(1).(fn{i}).link2 = c2;    
    Out_degree_pct_bank(1).(fn{i}).link3 = c3;    
    Out_degree_pct_bank(1).(fn{i}).link4 = c4;    
    Out_degree_pct_bank(1).(fn{i}).link5 = c5;    
    Out_degree_pct_bank(1).(fn{i}).link6 = c6;    
    Out_degree_pct_bank(1).(fn{i}).link7 = c7;    
    Out_degree_pct_bank(1).(fn{i}).link8 = c8;    
    Out_degree_pct_bank(1).(fn{i}).link9 = c9;        
end,

%%
fn2={'link0', 'link1', 'link2', 'link3', 'link4', ...
     'link5', 'link6', 'link7', 'link8', 'link9'};

 In_degree_pct_stats = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});

 Out_degree_pct_stats = struct( ...
    'c01',{},'c02',{},'c03',{},'c04',{},'c05',{},'c06',{}, ...
    'c07',{},'c08',{},'c09',{},'c10',{},'c11',{},'c12',{});


 for i=1:length(fn)
     c=[];
     for j=1:length(fn2)
         a=In_degree_pct_bank.(fn{i}).(fn2{j});
         c=[min(a); mean(a); max(a)];  
         In_degree_pct_stats(1).(fn{i}).(fn2{j})=c;
         a=Out_degree_pct_bank.(fn{i}).(fn2{j});         
         c=[min(a); mean(a); max(a)];  
         Out_degree_pct_stats(1).(fn{i}).(fn2{j})=c;         
     end
 end,

%% Table results with linkages - only average results

table_indegree=[];
table_outdegree=[];
for i=1:length(fn)
    for j=1:length(fn2)
        a=In_degree_pct_stats.(fn{i}).(fn2{j});
        table_indegree = [table_indegree; min(a(1,:)) mean(a(2,:)) max(a(3,:))];
        a=Out_degree_pct_stats.(fn{i}).(fn2{j});
        table_outdegree = [table_outdegree; min(a(1,:)) mean(a(2,:)) max(a(3,:))];        
    end
end,

%% Create chart of sample paths, in-degree and out-degree
c=[]; d=[];
for i=1:length(fn)
    a=In_degree.(fn{i})(1:240,1);
    c=[c a];
    a=Out_degree.(fn{i})(1:240,1);
    d=[d a];
end,

for i=1:1:12,
    figure;
    bar([c(:,i), d(:,i)],0.5);
    ylim([0 9]);
    set(gca,'XTick',[0:40:240]);
    set(gca, 'YTick',[0:1:9]);    
    set(gca,'FontSize',16);
    legend('In-degree','Out-degree');
end

    
%%

binrange = 0:0.0025:0.12;
xaxis_label = 'reserve ratio, in percent';
y=33:1:240;
xtick=0:2:12;
ytick=0:60:240;
my_xlim = [0 12];
% capital ratios
%for i=1:length(fn)
for i=4:4,
    
    %if i<10 xtick = 0:2:20; xlim=[0 20]; binrange=0:0.001:0.20;
    %  else xtick = 0:2:26; xlim=[0 26]; binrange=0:0.001:0.26;
    %end
    b=reserve_ratio_simulations(1).(fn{i});    
    [c]=build_histogram(b,binrange);
    idx_c=[33:240];
    F(21)=struct('cdata',[],'colormap',[]);
    idx_j=33:10:240;
    for j=1:21;
        figure;
        d=zeros(size(c));
        d(1:idx_j(j),:)=c(1:idx_j(j),:);
        x=binrange*100;
        z=d(idx_c,:)/10;
        waterfall(x,y,z);
        alpha(0.05);
        %set(gca,'FontSize',30);
        set(gca,'XTick',xtick);
        set(gca,'YTick',ytick);
        % view([30 30]);  roe
        % view([-20 20]); capital-ratio
        %view([170 20]); % reserve ratio
        view([145 30]); % capital ratio
        xlabel(xaxis_label);
        ylabel('Periods'); 
        %xlim([0 12]);
        ylim([0 240]);
        colormap(bone);
        %colormap(bone);
        %colormap(cool);
        %shading interp;
        %shading flat;
        F(j)=getframe;        
    end,
        
        
        
    
end



