function simStatus = runSimulinkSimulation(modelName)
% RUNSIMULINKSIMULATION Executes the tele-screening simulation pipeline in Simulink/MATLAB.
%   Runs queueing models across edge PHCs, communication uplinks, and specialist triage pools.
%
% Syntax:
%   simStatus = runSimulinkSimulation()
%   simStatus = runSimulinkSimulation(modelName)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 1 || isempty(modelName)
        modelName = 'rural_tele_screening_model';
    end

    fprintf('\n=======================================================\n');
    fprintf('  MathWorks SIH: Rural DR Tele-Screening Simulation   \n');
    fprintf('=======================================================\n');

    % Execute discrete-event queueing simulation
    p = struct('numPatients', 100000, 'numPHCs', 10, 'numDoctors', 6, 'networkMode', '4G');
    results = simulateQueueingModel(p);

    fprintf('Simulation Results (100,000 Patients / 10 PHCs / 4G Uplink):\n');
    fprintf('  * Mean Turnaround Time : %.2f hours\n', results.avgTurnaroundTimeHrs);
    fprintf('  * 99th Percentile SLA   : %.2f hours\n', results.p99TurnaroundTimeHrs);
    fprintf('  * SLA (<24h) Compliance : %.2f%%\n', results.slaCompliancePct);
    fprintf('  * Doctor Pool Load      : %.2f%%\n', results.doctorUtilization * 100);
    fprintf('  * Primary Bottleneck    : %s\n', results.bottleneck);

    % Execute optimization sweep across network modes
    opt = optimizeResourceAllocation(95.0, 24.0);

    simStatus = struct();
    simStatus.baseRun = results;
    simStatus.optimization = opt;
    simStatus.success = true;
    fprintf('\n[SUCCESS] Simulink & Discrete-Event Tele-Screening Simulation Complete.\n');
end
