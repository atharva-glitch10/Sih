function optResults = optimizeResourceAllocation(targetSLAPct, maxTurnaroundHours)
% OPTIMIZERESOURCEALLOCATION Performs Monte Carlo optimization for rural tele-screening logistics.
%   Sweeps doctor staffing pools and network profiles to identify cost-optimal
%   configurations achieving >= 95% SLA compliance under 24 hours.
%
% Syntax:
%   optResults = optimizeResourceAllocation()
%   optResults = optimizeResourceAllocation(targetSLAPct, maxTurnaroundHours)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 1 || isempty(targetSLAPct)
        targetSLAPct = 98.0;
    end

    if nargin < 2 || isempty(maxTurnaroundHours)
        maxTurnaroundHours = 24.0;
    end

    networkModes = {'2G', '3G', '4G', 'VSAT'};
    doctorRange = 2:2:12;

    resultsGrid = [];

    fprintf('=== MathWorks SIH: Running Rural Screening Optimization Sweeps ===\n');

    for netIdx = 1:numel(networkModes)
        netMode = networkModes{netIdx};
        for d = doctorRange
            p = struct();
            p.numPatients = 100000;
            p.numPHCs = 10;
            p.numDoctors = d;
            p.networkMode = netMode;
            
            res = simulateQueueingModel(p);
            
            isCompliant = (res.slaCompliancePct >= targetSLAPct) && (res.avgTurnaroundTimeHrs <= maxTurnaroundHours);
            
            entry = struct();
            entry.networkMode = netMode;
            entry.numDoctors = d;
            entry.avgTurnaroundHrs = res.avgTurnaroundTimeHrs;
            entry.slaCompliancePct = res.slaCompliancePct;
            entry.doctorUtilization = res.doctorUtilization;
            entry.bottleneck = res.bottleneck;
            entry.isCompliant = isCompliant;

            resultsGrid = [resultsGrid; entry]; %#ok<AGROW>
        end
    end

    % Filter compliant configurations
    compliantEntries = resultsGrid([resultsGrid.isCompliant]);
    
    if ~isempty(compliantEntries)
        % Choose lowest doctor count among compliant 4G/3G configurations
        [~, minDocIdx] = min([compliantEntries.numDoctors]);
        recommendedConfig = compliantEntries(minDocIdx);
    else
        recommendedConfig = resultsGrid(end);
    end

    optResults = struct();
    optResults.resultsGrid = resultsGrid;
    optResults.recommendedConfig = recommendedConfig;
    optResults.targetSLA = targetSLAPct;
    optResults.maxTurnaroundHours = maxTurnaroundHours;
    
    fprintf('Optimal Configuration Found:\n');
    fprintf('  - Network: %s\n', recommendedConfig.networkMode);
    fprintf('  - Doctors Required: %d\n', recommendedConfig.numDoctors);
    fprintf('  - Avg Turnaround Time: %.2f hours\n', recommendedConfig.avgTurnaroundHrs);
    fprintf('  - SLA Compliance: %.1f%%\n', recommendedConfig.slaCompliancePct);
    fprintf('  - Doctor Utilization: %.1f%%\n', recommendedConfig.doctorUtilization * 100);
end
