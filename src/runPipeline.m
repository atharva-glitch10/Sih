function result = runPipeline(imagePath, patientID, outputJson)
% RUNPIPELINE Headless execution entrypoint for Octave / MATLAB backend bridges.
%   Takes input image path, runs all 5 screening pillars, outputs structured JSON
%   bounded by markers and writes to outputJson.
%
% Syntax:
%   result = runPipeline(imagePath, patientID, outputJson)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 1 || isempty(imagePath)
        imagePath = fullfile('data', 'synthetic', 'DR_Grade3_Sample01.bmp');
    end
    if nargin < 2 || isempty(patientID)
        patientID = 'PHC-MH-2026-0842';
    end
    if nargin < 3 || isempty(outputJson)
        outputJson = fullfile('reports', [patientID, '_result.json']);
    end

    % Ensure output directory exists
    outputDir = fileparts(outputJson);
    if ~isempty(outputDir) && ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % 1. Read input image
    if ~exist(imagePath, 'file')
        error('Input fundus image not found: %s', imagePath);
    end
    rawImg = imread(imagePath);

    % --- PILLAR 1: IMAGE QUALITY ASSESSMENT ---
    [qCat, qScore, iqaFb, procImg, iqaReport] = assessImageQuality(rawImg);
    retinalMask = iqaReport.fov.retinalMask;

    % --- PILLAR 2: ANATOMICAL & LESION SEGMENTATION ---
    [odMask, odCenter, odRadius] = locateOpticDisc(procImg, retinalMask);
    [foveaCenter, foveaMask, maculaRegionMask] = locateFoveaCenter(procImg, odCenter, odRadius, retinalMask);
    [vesselMask, vesselProb, vesselDensity] = segmentVessels(procImg, retinalMask);
    [maMask, maCount, maDet] = detectMicroaneurysms(procImg, vesselMask, odMask, retinalMask);
    [heMask, heArea, heDet] = segmentHardExudates(procImg, odMask, retinalMask);
    [hmMask, hmCount, hmDet] = segmentHemorrhages(procImg, vesselMask, odMask, retinalMask);
    [nvDetected, nvMask, nvDet] = detectNeovascularization(procImg, vesselMask, odMask, retinalMask);

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
    segResults.maDetails = maDet;
    segResults.heMask = heMask;
    segResults.heDetails = heDet;
    segResults.heArea = heArea;
    segResults.hmMask = hmMask;
    segResults.hmDetails = hmDet;
    segResults.nvMask = nvMask;
    segResults.nvDetails = nvDet;

    % --- PILLAR 3: GRADING & 4-2-1 RULES ---
    classifierModel = trainDRClassifier();
    [grade, gradeLabel, conf, isRef, probs, expl, details] = classifyDRSeverity(procImg, segResults, classifierModel);

    % --- PILLAR 4: EXPLAINABILITY & DME ---
    [gradCamMap, overlay] = generateGradCAM(procImg, segResults, grade);
    [dmeRisk, dmeScore, dmeExpl] = assessMacularEdemaRisk(foveaCenter, odRadius, heMask, retinalMask);

    % --- PILLAR 5: SIMULINK / QUEUEING LOGISTICS ---
    simRes = simulateQueueingModel(struct('numPatients', 100000, 'numPHCs', 10, 'numDoctors', 6, 'networkMode', '4G'));

    % Construct structured result
    result = struct();
    result.patientID = patientID;
    result.imagePath = imagePath;
    result.status = 'SUCCESS';
    result.iqa = struct('category', qCat, 'score', qScore, 'feedback', iqaFb.summary);
    result.diagnosis = struct( ...
        'grade', grade, ...
        'gradeLabel', gradeLabel, ...
        'confidence', conf, ...
        'isReferable', isRef, ...
        'probabilities', probs, ...
        'ruleExplanation', details.ruleExplanation, ...
        'dmeRisk', dmeRisk, ...
        'dmeScore', dmeScore ...
    );
    result.biomarkers = struct( ...
        'microaneurysms', maCount, ...
        'hemorrhages', hmCount, ...
        'hemorrhageArea', round(hmDet.totalArea), ...
        'hardExudatesArea', round(heArea), ...
        'vesselDensity', vesselDensity, ...
        'neovascularization', logical(nvDetected) ...
    );
    result.logistics = struct( ...
        'avgTurnaroundHours', simRes.avgTurnaroundTimeHrs, ...
        'slaCompliancePct', simRes.slaCompliancePct, ...
        'doctorUtilizationPct', simRes.doctorUtilization * 100 ...
    );

    % Format JSON string
    if exist('jsonencode', 'builtin') || exist('jsonencode', 'file')
        jsonStr = jsonencode(result);
    else
        % Octave / fallback JSON formatter
        jsonStr = sprintf('{"patientID":"%s","imagePath":"%s","status":"SUCCESS","diagnosis":{"grade":%d,"gradeLabel":"%s","confidence":%.4f,"isReferable":%s,"dmeRisk":"%s","dmeScore":%d},"biomarkers":{"microaneurysms":%d,"hemorrhages":%d,"hardExudatesArea":%d,"neovascularization":%s}}', ...
            patientID, imagePath, grade, gradeLabel, conf, ternaryStr(isRef, 'true', 'false'), dmeRisk, dmeScore, ...
            maCount, hmCount, round(heArea), ternaryStr(nvDetected, 'true', 'false'));
    end

    % Write to output JSON file
    fid = fopen(outputJson, 'w');
    if fid ~= -1
        fprintf(fid, '%s\n', jsonStr);
        fclose(fid);
    end

    % Print stdout delimiters for process bridges
    fprintf('\n===JSON_START===\n%s\n===JSON_END===\n', jsonStr);
end

function str = ternaryStr(cond, strTrue, strFalse)
    if cond, str = strTrue; else, str = strFalse; end
end
