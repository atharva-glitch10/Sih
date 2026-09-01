function results = simulateQueueingModel(simParams)
% SIMULATEQUEUEINGMODEL Discrete-event logistics and queueing simulation for rural DR tele-screening.
%   Simulates 100,000 annual patients across 10 rural PHCs, edge IQA rejection loops,
%   network uplinks (2G/3G/4G/VSAT), central AI inference, and specialist triage pool.
%
% Syntax:
%   results = simulateQueueingModel()
%   results = simulateQueueingModel(simParams)
%
% Inputs (Optional Struct):
%   simParams.numPatients       - Total patients simulated (default: 100000)
%   simParams.numPHCs           - Number of rural PHCs (default: 10)
%   simParams.numDoctors        - Tele-ophthalmologists pool (default: 5)
%   simParams.networkMode       - '2G', '3G', '4G', or 'VSAT' (default: '4G')
%   simParams.iqaRejectionRate  - Fraction of initial images rejected (default: 0.12)
%   simParams.referralRate      - Fraction of screened patients flagged referable (default: 0.28)
%
% Outputs:
%   results.avgTurnaroundTimeHrs - Mean patient turnaround time from capture to report
%   results.maxTurnaroundTimeHrs - Maximum turnaround time (99th percentile)
%   results.slaCompliancePct     - Percentage of cases triaged under 24-hour SLA target
%   results.doctorUtilization    - Tele-ophthalmologist workload utilization [0 - 1]
%   results.bottleneck           - Identified system bottleneck (Bandwidth / AI / Specialist)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 1 || isempty(simParams)
        simParams = struct();
    end

    % Default Simulation Parameters
    if ~isfield(simParams, 'numPatients'),      simParams.numPatients = 100000; end
    if ~isfield(simParams, 'numPHCs'),           simParams.numPHCs = 10; end
    if ~isfield(simParams, 'numDoctors'),        simParams.numDoctors = 6; end
    if ~isfield(simParams, 'networkMode'),       simParams.networkMode = '4G'; end
    if ~isfield(simParams, 'iqaRejectionRate'),  simParams.iqaRejectionRate = 0.10; end
    if ~isfield(simParams, 'referralRate'),      simParams.referralRate = 0.25; end
    if ~isfield(simParams, 'workingDaysPerYear'),simParams.workingDaysPerYear = 300; end
    if ~isfield(simParams, 'workingHoursPerDay'),simParams.workingHoursPerDay = 8; end

    % Network bandwidth profiles (Upload Speed in Mbps & image size ~ 3.5 MB)
    switch upper(simParams.networkMode)
        case '2G'
            uplinkSpeedMbps = 0.15;
            packetDropRate = 0.08;
        case '3G'
            uplinkSpeedMbps = 2.0;
            packetDropRate = 0.02;
        case '4G'
            uplinkSpeedMbps = 15.0;
            packetDropRate = 0.002;
        case 'VSAT'
            uplinkSpeedMbps = 5.0;
            packetDropRate = 0.01;
        otherwise
            uplinkSpeedMbps = 10.0;
            packetDropRate = 0.005;
    end

    imageSizeBytes = 3.5 * 1024 * 1024 * 8; % bits per image
    transferTimeSec = (imageSizeBytes / (uplinkSpeedMbps * 1e6));
    
    % Edge IQA computation time (local GPU/NPU)
    edgeIQATimeSec = 1.2;
    % Central AI inference + GradCAM time
    aiInferenceTimeSec = 2.5;
    % Specialist verification time (< 30s for AI-assisted cases)
    doctorReviewTimeSec = 28.0;

    totalScreeningHours = simParams.workingDaysPerYear * simParams.workingHoursPerDay;
    arrivalRatePerSec = simParams.numPatients / (totalScreeningHours * 3600);

    % Monte Carlo simulation of patient batches
    numBatches = 5000;
    batchSize = round(simParams.numPatients / numBatches);

    turnaroundTimesSec = zeros(numBatches, 1);
    doctorBusyTimesSec = 0;

    for b = 1:numBatches
        % 1. Edge capture + IQA loop
        rejectionEvents = rand(batchSize, 1) < simParams.iqaRejectionRate;
        totalRecaptures = sum(rejectionEvents);
        t_capture = edgeIQATimeSec * (batchSize + totalRecaptures);

        % 2. Telecommunication network transfer (with retransmission on drops)
        drops = rand(batchSize, 1) < packetDropRate;
        totalTransfers = batchSize + sum(drops);
        t_transfer = totalTransfers * transferTimeSec / simParams.numPHCs;

        % 3. Central AI batch inference
        t_ai = batchSize * aiInferenceTimeSec;

        % 4. Specialist triage pool queueing (Only referable cases + 5% random audit of Grade 0/1)
        numReferable = sum(rand(batchSize, 1) < simParams.referralRate);
        numAudits = sum(rand(batchSize - numReferable, 1) < 0.05);
        casesToReview = numReferable + numAudits;

        % Doctor pool service time
        totalDoctorWorkSec = casesToReview * doctorReviewTimeSec;
        doctorBusyTimesSec = doctorBusyTimesSec + totalDoctorWorkSec;
        t_doctor = totalDoctorWorkSec / simParams.numDoctors;

        % Total batch turnaround
        totalBatchSec = t_capture + t_transfer + t_ai + t_doctor;
        turnaroundTimesSec(b) = totalBatchSec;
    end

    avgTurnaroundHrs = mean(turnaroundTimesSec) / 3600;
    p99TurnaroundHrs = quantile(turnaroundTimesSec, 0.99) / 3600;
    slaHours = 24.0;
    slaCompliance = (sum(turnaroundTimesSec <= (slaHours * 3600)) / numBatches) * 100;

    totalAvailableDoctorSec = simParams.numDoctors * totalScreeningHours * 3600;
    doctorUtilization = min(1.0, doctorBusyTimesSec / totalAvailableDoctorSec);

    % Identify Bottleneck
    timeComponents = [mean(t_transfer), mean(t_ai), mean(t_doctor)];
    [~, maxIdx] = max(timeComponents);
    names = {'Network Bandwidth Uplink', 'Central AI Server Compute', 'Tele-Ophthalmologist Pool Capacity'};
    bottleneck = names{maxIdx};

    results = struct();
    results.params = simParams;
    results.avgTurnaroundTimeHrs = avgTurnaroundHrs;
    results.p99TurnaroundTimeHrs = p99TurnaroundHrs;
    results.slaCompliancePct = slaCompliance;
    results.doctorUtilization = doctorUtilization;
    results.bottleneck = bottleneck;
    results.totalPatientsYear = simParams.numPatients;
    results.numPHCs = simParams.numPHCs;
    results.numDoctors = simParams.numDoctors;
    results.networkMode = simParams.networkMode;
end
