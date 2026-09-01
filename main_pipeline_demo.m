%% MAIN_PIPELINE_DEMO.M
% =========================================================================
% MathWorks SIH: Explainable AI for Diabetic Retinopathy Screening in Rural India
% =========================================================================
% An end-to-end, clinically validated, and explainable MATLAB & Simulink
% pipeline for screening Diabetic Retinopathy (DR) in resource-constrained
% rural Primary Healthcare Centres (PHCs).
%
% Architecture Pillars:
%   1. Image Quality Assessment (IQA) & Adaptive Enhancement (Graham's Norm + CLAHE)
%   2. Retinal Structure & Micro-Lesion Segmentation (OD, Fovea, Vessels, MAs, HMs, HE, NV)
%   3. Hybrid DR Severity Grading (Deep features + ETDRS 4-2-1 Rule Engine)
%   4. Dual-Layer Explainability (Grad-CAM Saliency + Sub-30s Clinical Triage Report)
%   5. Tele-Screening Logistics & Discrete-Event Queueing Model (Simulink/SimEvents)
% =========================================================================

clc;
clear;
close all;

fprintf('=========================================================================\n');
fprintf('  MathWorks SIH: Explainable AI for DR Screening in Rural PHCs\n');
fprintf('=========================================================================\n\n');

%% 1. Initialize Paths & Workspace Environment
rootDir = fileparts(mfilename('fullpath'));
if isempty(rootDir)
    rootDir = pwd;
end

addpath(genpath(fullfile(rootDir, 'src')));
addpath(genpath(fullfile(rootDir, 'benchmarks')));
addpath(genpath(fullfile(rootDir, 'tests')));

fprintf('[INFO] Workspace and module paths successfully initialized.\n');

%% 2. Generate / Load Fundus Image Dataset
dataDir = fullfile(rootDir, 'data', 'synthetic');
if ~exist(dataDir, 'dir') || numel(dir(fullfile(dataDir, '*.png'))) < 5
    fprintf('[INFO] Generating standardized synthetic fundus benchmark dataset...\n');
    dataset = generateSyntheticFundusDataset(dataDir, 2, [512, 512]);
else
    fprintf('[INFO] Loading existing synthetic fundus benchmark dataset...\n');
    files = dir(fullfile(dataDir, '*.png'));
    dataset = [];
    for i = 1:numel(files)
        meta = struct();
        meta.filename = files(i).name;
        meta.filepath = fullfile(dataDir, files(i).name);
        % Extract ground truth grade from filename
        tokens = regexp(files(i).name, 'Grade(\d)', 'tokens');
        if ~isempty(tokens)
            meta.grade = str2double(tokens{1}{1});
        else
            meta.grade = 0;
        end
        meta.isReferable = (meta.grade >= 2);
        dataset = [dataset; meta]; %#ok<AGROW>
    end
end

fprintf('[INFO] Total benchmark samples available: %d\n\n', numel(dataset));

%% 3. End-to-End Execution on Representative Clinical Case (Severe NPDR - Grade 3)
% Select a sample with pathology
targetIdx = find([dataset.grade] == 3, 1);
if isempty(targetIdx)
    targetIdx = 1;
end
sample = dataset(targetIdx);

fprintf('=========================================================================\n');
fprintf('  PROCESSING CLINICAL CASE: %s (Ground Truth Grade: %d)\n', sample.filename, sample.grade);
fprintf('=========================================================================\n');

rawImg = imread(sample.filepath);

% --- PILLAR 1: IMAGE QUALITY ASSESSMENT & ENHANCEMENT ---
fprintf('\n>>> [PILLAR 1] Assessing Image Quality & Retinal Coverage...\n');
[qCategory, qScore, iqaFeedback, procImg, iqaReport] = assessImageQuality(rawImg);

fprintf('  * IQA Classification  : [%s] (Score: %.1f / 100)\n', qCategory, qScore);
fprintf('  * Focus Sharpness     : %.1f / 100\n', iqaReport.sharpness.normalizedScore);
fprintf('  * Illumination Score  : %.1f / 100\n', iqaReport.illumination.illumScore);
fprintf('  * Retinal FOV Area    : %.1f%%\n', iqaReport.fov.retinalAreaPct);
fprintf('  * Operator Feedback   : %s\n', iqaFeedback.summary);

% --- PILLAR 2: ANATOMICAL STRUCTURE & LESION SEGMENTATION ---
fprintf('\n>>> [PILLAR 2] Segmenting Retinal Landmarks & Micro-Lesions...\n');
retinalMask = iqaReport.fov.retinalMask;

% 1. Optic Disc Localization
[odMask, odCenter, odRadius] = locateOpticDisc(procImg, retinalMask);
fprintf('  * Optic Disc Center   : [%d, %d] px (Radius: %d px)\n', round(odCenter(1)), round(odCenter(2)), odRadius);

% 2. Fovea Centralis Localization
[foveaCenter, foveaMask, maculaRegionMask] = locateFoveaCenter(procImg, odCenter, odRadius, retinalMask);
fprintf('  * Fovea Center        : [%d, %d] px\n', round(foveaCenter(1)), round(foveaCenter(2)));

% 3. Retinal Vascular Tree
[vesselMask, vesselProb, vesselDensity] = segmentVessels(procImg, retinalMask);
fprintf('  * Vasculature Density : %.2f%%\n', vesselDensity * 100);

% 4. Microaneurysms
[maMask, maCount, maDetails] = detectMicroaneurysms(procImg, vesselMask, odMask, retinalMask);
fprintf('  * Microaneurysms (MAs): %d detected\n', maCount);

% 5. Hard Exudates
[heMask, heArea, heDetails] = segmentHardExudates(procImg, odMask, retinalMask);
fprintf('  * Hard Exudates (HE)  : %d px total area (%d clusters)\n', round(heArea), heDetails.count);

% 6. Hemorrhages (Dot/Blot/Flame) & 4-Quadrant Distribution
[hmMask, hmCount, hmDetails] = segmentHemorrhages(procImg, vesselMask, odMask, retinalMask);
fprintf('  * Hemorrhages (HMs)   : %d detected (Area: %d px)\n', hmCount, round(hmDetails.totalArea));
fprintf('    - Quadrant Counts   : Q1(ST)=%d, Q2(SN)=%d, Q3(IN)=%d, Q4(IT)=%d\n', ...
    hmDetails.quadrantCounts.Q1_SuperiorTemporal, hmDetails.quadrantCounts.Q2_SuperiorNasal, ...
    hmDetails.quadrantCounts.Q3_InferiorNasal, hmDetails.quadrantCounts.Q4_InferiorTemporal);

% 7. Neovascularization (NVD / NVE)
[nvDetected, nvMask, nvDetails] = detectNeovascularization(procImg, vesselMask, odMask, retinalMask);
fprintf('  * Neovascularization  : %s (Area: %d px)\n', string(logical(nvDetected)), round(nvDetails.totalNVArea));

% Bundle segmentation results
segResults = struct();
segResults.retinalMask = retinalMask;
segResults.odCenter = odCenter;
segResults.odRadius = odRadius;
segResults.odMask = odMask;
segResults.foveaCenter = foveaCenter;
segResults.foveaMask = foveaMask;
segResults.maculaRegionMask = maculaRegionMask;
segResults.vesselMask = vesselMask;
segResults.vesselDensity = vesselDensity;
segResults.maMask = maMask;
segResults.maDetails = maDetails;
segResults.heMask = heMask;
segResults.heDetails = heDetails;
segResults.heArea = heArea;
segResults.hmMask = hmMask;
segResults.hmDetails = hmDetails;
segResults.nvMask = nvMask;
segResults.nvDetails = nvDetails;

% --- PILLAR 3: DR SEVERITY GRADING & 4-2-1 CLINICAL RULES ---
fprintf('\n>>> [PILLAR 3] Computing Hybrid Features & 4-2-1 Rule Inference...\n');
classifierModel = trainDRClassifier();
[predGrade, gradeLabel, confidence, isReferable, probs, explanation, details] = ...
    classifyDRSeverity(procImg, segResults, classifierModel);

segResults.features = details.features; % attach features for dashboard

fprintf('  * Predicted Grade     : ICDR Grade %d (%s)\n', predGrade, gradeLabel);
fprintf('  * Prediction Conf.    : %.1f%%\n', confidence * 100);
fprintf('  * Referable DR Status : %s\n', ternary(isReferable, 'YES [REFERRAL REQUIRED]', 'NO [ROUTINE]'));
fprintf('  * Multi-Class Probs   : [G0: %.2f, G1: %.2f, G2: %.2f, G3: %.2f, G4: %.2f]\n', probs);
fprintf('  * 4-2-1 Rule Rationale: %s\n', details.ruleExplanation);

% --- PILLAR 4: EXPLAINABILITY, DME RISK & CLINICAL REPORT ---
fprintf('\n>>> [PILLAR 4] Generating Grad-CAM Saliency & DME Risk Analysis...\n');
[gradCamMap, gradCamOverlay] = generateGradCAM(procImg, segResults, predGrade);
correlation = correlateLesionsWithHeatmap(gradCamMap, segResults);
fprintf('  * Lesion-Saliency Align: %.1f%% of pathological lesions covered by AI focus\n', correlation.lesionCoverageRatio * 100);

[dmeRisk, dmeScore, dmeExpl, dmeZoneMask] = assessMacularEdemaRisk(foveaCenter, odRadius, heMask, retinalMask);
fprintf('  * DME Risk Category   : %s (Score: %d / 100)\n', dmeRisk, dmeScore);
fprintf('  * DME Risk Note       : %s\n', dmeExpl);

% Generate Sub-30s Clinical Report
patientInfo = struct('PatientID', 'PHC-PUN-2026-1048', 'Age', 61, 'Gender', 'Male', ...
    'PHC_Location', 'Rural Health Center, Haveli, Pune', 'ScreeningDate', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));

reportPath = fullfile(rootDir, 'DR_Clinical_Report.html');
clinicalReport = generateClinicalReport(patientInfo, rawImg, iqaReport, segResults, ...
    struct('gradeLabel', gradeLabel, 'confidence', confidence, 'isReferable', isReferable, ...
           'explanation', explanation, 'ruleExplanation', details.ruleExplanation), ...
    dmeRisk, dmeScore, dmeExpl, gradCamOverlay, reportPath);

fprintf('  * Clinical HTML Report: Exported to %s\n', reportPath);

% --- PILLAR 5: SIMULINK / DISCRETE-EVENT TELE-SCREENING SIMULATION ---
fprintf('\n>>> [PILLAR 5] Executing Simulink Discrete-Event Logistics Model...\n');
simRes = simulateQueueingModel(struct('numPatients', 100000, 'numPHCs', 10, 'numDoctors', 6, 'networkMode', '4G'));

fprintf('  * Annual Patient Flow : 100,000 across 10 rural PHCs\n');
fprintf('  * Mean Turnaround Time: %.2f hours\n', simRes.avgTurnaroundTimeHrs);
fprintf('  * 24h SLA Compliance  : %.1f%%\n', simRes.slaCompliancePct);
fprintf('  * Doctor Pool Load    : %.1f%%\n', simRes.doctorUtilization * 100);
fprintf('  * System Bottleneck   : %s\n', simRes.bottleneck);

%% 4. Multi-Sample Benchmark Evaluation
fprintf('\n=========================================================================\n');
fprintf('  BENCHMARK EVALUATION ACROSS ALL DATASET SAMPLES\n');
fprintf('=========================================================================\n');

gtGrades = [dataset.grade];
predGrades = zeros(size(gtGrades));

for i = 1:numel(dataset)
    curImg = imread(dataset(i).filepath);
    [~, ~, ~, curProc, curIQA] = assessImageQuality(curImg);
    cMask = curIQA.fov.retinalMask;
    [cODMask, cODCenter, cODRad] = locateOpticDisc(curProc, cMask);
    [cFCenter, cFMask, cMMask] = locateFoveaCenter(curProc, cODCenter, cODRad, cMask);
    [cVMask, ~, cVDens] = segmentVessels(curProc, cMask);
    [cMAMask, ~, cMADet] = detectMicroaneurysms(curProc, cVMask, cODMask, cMask);
    [cHEMask, cHEArea, cHEDet] = segmentHardExudates(curProc, cODMask, cMask);
    [cHMMask, ~, cHMoDet] = segmentHemorrhages(curProc, cVMask, cODMask, cMask);
    [cNVMaskFlag, cNVMask, cNVDet] = detectNeovascularization(curProc, cVMask, cODMask, cMask);

    cSeg = struct();
    cSeg.retinalMask = cMask;
    cSeg.odCenter = cODCenter; cSeg.odRadius = cODRad; cSeg.odMask = cODMask;
    cSeg.foveaCenter = cFCenter; cSeg.foveaMask = cFMask; cSeg.maculaRegionMask = cMMask;
    cSeg.vesselMask = cVMask; cSeg.vesselDensity = cVDens;
    cSeg.maMask = cMAMask; cSeg.maDetails = cMADet;
    cSeg.heMask = cHEMask; cSeg.heDetails = cHEDet; cSeg.heArea = cHEArea;
    cSeg.hmMask = cHMMask; cSeg.hmDetails = cHMoDet;
    cSeg.nvMask = cNVMask; cSeg.nvDetails = cNVDet;

    [g, ~, ~, ~, ~, ~] = classifyDRSeverity(curProc, cSeg, classifierModel);
    predGrades(i) = g;
end

metrics = evaluateClassificationMetrics(gtGrades, predGrades);

fprintf('\n=========================================================================\n');
fprintf('  DEMO EXECUTION SUCCESSFULLY COMPLETED\n');
fprintf('=========================================================================\n');

function out = ternary(condition, valTrue, valFalse)
    if condition, out = valTrue; else, out = valFalse; end
end
