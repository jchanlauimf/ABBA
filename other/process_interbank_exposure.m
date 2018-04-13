% Banking_system_network_measures.m
%
% This program calculates network measures for the interbank exposure
% network
%
% Additional toolbox: Matlab tools for Network Analysis MIT (2006-11)
%  
clear all; clc;
csv_file_name = 'interbank_exposure_complete.csv';
load(csv_file_name);
IB_exposures = interbank_exposure_complete;


IB_exposures = clean_interbank_exposure;
[n_periods n_banks] = size(IB_exposures);
n_banks = sqrt(n_banks);

system_deg=[];
system_indeg=[];
system_outdeg=[];

% Calculate weighted degrees of the system

for j=1:n_periods
    matrix_exposures = reshape(IB_exposures(j,:), n_banks, n_banks);
    matrix_exposures = matrix_exposures - eye(n_banks);
    [deg indeg outdeg] = degrees(matrix_exposures);
    system_deg = [system_deg; deg];
    system_indeg = [system_indeg; indeg];
    system_outdeg = [system_outdeg; outdeg];
end,

% Calculate unweighted degrees of the system

system_deg_unw=[];
system_indeg_unw=[];
system_outdeg_unw=[];

for j=1:n_periods
    matrix_exposures = reshape(IB_exposures(j,:), n_banks, n_banks);
    matrix_exposures = matrix_exposures - eye(n_banks);
    matrix_exposures = (matrix_exposures ~= 0);
    
    [deg indeg outdeg] = degrees(matrix_exposures);
    system_deg_unw = [system_deg_unw; deg];
    system_indeg_unw = [system_indeg_unw; indeg];
    system_outdeg_unw = [system_outdeg_unw; outdeg];
end,


 