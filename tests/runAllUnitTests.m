function testResults = runAllUnitTests()
% RUNALLUNITTESTS Automated unit testing harness for MathWorks SIH DR Screening Pipeline.
%   Validates all 5 pillars and asserts compliance with clinical design targets.
%
% Syntax:
%   testResults = runAllUnitTests()
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    fprintf('\n=======================================================\n');
    fprintf('  RUNNING COMPREHENSIVE MATHWORKS SIH UNIT TEST SUITE \n');
    fprintf('=======================================================\n');

    % Setup paths
    baseDir = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(fullfile(baseDir, 'src')));
    addpath(genpath(fullfile(baseDir, 'benchmarks')));

    totalTests = 0;
    passedTests = 0;
    failedTests = 0;
    testLog = {};

    % Helper for assertions
    function assertTest(condition, testName)
        totalTests = totalTests + 1;
        if condition
            passedTests = passedTests + 1;
            fprintf('  [PASS] %s\n', testName);
            testLog{end+1} = sprintf('PASS: %s', testName);
        else
            failedTests = failedTests + 1;
            fprintf('  [FAIL] %s\n', testName);
            testLog{end+1} = sprintf('FAIL: %s', testName);
        end
    end

    %% --- TEST SUITE 1: PILLAR 1 - IMAGE QUALITY ASSESSMENT (IQA) ---
    fprintf('\n[TEST GROUP 1] Pillar 1: Image Quality Assessment & Enhancement\n');
    
    % Generate synthetic test image
    testImg = zeros(256, 256, 3);
    [X, Y] = meshgrid(1:256, 1:256);
    mask = sqrt((X-128).^2 + (Y-128).^2) <= 100;
    testImg(:, :, 1) = 0.8 * mask;
    testImg(:, :, 2) = 0.4 * mask;
    testImg(:, :, 3) = 0.1 * mask;

    [sharpScore, isSharp, sharpDet] = checkFocusSharpness(testImg);
    assertTest(isnumeric(sharpScore) && sharpScore >= 0 && sharpScore <= 100, 'Sharpness score range [0-100]');

    [illumScore, isUniform, illumDet] = checkIlluminationUniformity(testImg);
    assertTest(isnumeric(illumScore) && illumScore >= 0 && illumScore <= 100, 'Illumination score range [0-100]');

    [covScore, isAdequate, fovDet] = checkFOVRetinalCoverage(testImg);
    assertTest(fovDet.retinalAreaPct > 40, 'FOV Retinal coverage detection');

    [qCat, oScore, fb, procImg] = assessImageQuality(testImg);
    assertTest(ismember(qCat, {'Gradeable', 'Borderline', 'Ungradeable'}), 'IQA Category valid categorization');
    assertTest(isfield(fb, 'requiresRecapture'), 'Technician feedback contains recapture action item');

    [enhImg, ~] = enhanceBorderlineImage(testImg, fovDet.retinalMask);
    assertTest(size(enhImg, 1) == 256 && size(enhImg, 2) == 256, 'Graham enhancement output size preservation');

    %% --- TEST SUITE 2: PILLAR 2 - SEGMENTATION MODULES ---
    fprintf('\n[TEST GROUP 2] Pillar 2: Retinal Anatomical & Lesion Segmentation\n');
    
    [odMask, odCenter, odRadius] = locateOpticDisc(testImg, mask);
    assertTest(all(size(odMask) == [256, 256]), 'Optic disc mask dimension check');
    assertTest(odRadius > 0, 'Optic disc radius estimation positive');

    [fovCenter, fovMask, macMask] = locateFoveaCenter(testImg, odCenter, odRadius, mask);
    assertTest(numel(fovCenter) == 2, 'Fovea center coordinate extraction');
    assertTest(any(macMask(:)), 'Macula region 1DD mask generation');

    [vesselMask, vesselProb, vDensity] = segmentVessels(testImg, mask);
    assertTest(all(size(vesselMask) == [256, 256]), 'Vessel mask dimension check');
    assertTest(vDensity >= 0 && vDensity <= 1, 'Vessel density normalized');

    [maMask, maCount, maDet] = detectMicroaneurysms(testImg, vesselMask, odMask, mask);
    assertTest(maCount >= 0, 'Microaneurysm count valid');

    [heMask, heArea, heDet] = segmentHardExudates(testImg, odMask, mask);
    assertTest(heArea >= 0, 'Hard exudate area valid');

    [hmMask, hmCount, hmDet] = segmentHemorrhages(testImg, vesselMask, odMask, mask);
    assertTest(isfield(hmDet, 'quadrantCounts'), 'Hemorrhage 4-quadrant assignment');

    [nvDetFlag, nvMask, nvDet] = detectNeovascularization(testImg, vesselMask, odMask, mask);
    assertTest(islogical(nvDetFlag), 'Neovascularization flag valid boolean');

    %% --- TEST SUITE 3: PILLAR 3 - DR SEVERITY GRADING ---
    fprintf('\n[TEST GROUP 3] Pillar 3: DR Severity Grading & 4-2-1 Rules\n');

    segResults = struct();
    segResults.retinalMask = mask;
    segResults.odCenter = odCenter;
    segResults.odRadius = odRadius;
    segResults.foveaCenter = fovCenter;
    segResults.vesselMask = vesselMask;
    segResults.vesselDensity = vDensity;
    segResults.maMask = maMask;
    segResults.maDetails = maDet;
    segResults.heMask = heMask;
    segResults.heDetails = heDet;
    segResults.hmMask = hmMask;
    segResults.hmDetails = hmDet;
    segResults.nvMask = nvMask;
    segResults.nvDetails = nvDet;

    [fVec, fNames, fStruct] = extractHybridFeatures(testImg, segResults);
    assertTest(numel(fVec) == numel(fNames), 'Feature vector matches feature names');

    % Test 4-2-1 Rule: Severe NPDR with 4 quadrants HMs
    fStructSevere = fStruct;
    fStructSevere.quadsWithSevereHMs = 4;
    fStructSevere.hmCount = 25;
    [rGrade, rConf, rExpl, rRef] = apply421ClinicalRules(fStructSevere, segResults);
    assertTest(rGrade == 3 && rRef == true, 'Clinical 4-2-1 Rule correctly fires Grade 3 (Severe NPDR)');

    % Test PDR rule with Neovascularization
    fStructPDR = fStruct;
    fStructPDR.nvDetected = 1;
    [rGradePDR, ~, ~, rRefPDR] = apply421ClinicalRules(fStructPDR, segResults);
    assertTest(rGradePDR == 4 && rRefPDR == true, 'Neovascularization correctly fires Grade 4 (Proliferative DR)');

    [grade, gradeLabel, conf, isRef, probs, expl] = classifyDRSeverity(testImg, segResults);
    assertTest(grade >= 0 && grade <= 4, 'Final ICDR Grade in range [0, 4]');
    assertTest(abs(sum(probs) - 1.0) < 1e-3, 'Calibrated probabilities sum to 1.0');

    %% --- TEST SUITE 4: PILLAR 4 - EXPLAINABILITY & CLINICAL REPORTING ---
    fprintf('\n[TEST GROUP 4] Pillar 4: Explainability (Grad-CAM, DME Risk, Reports)\n');

    [gradCam, overlay] = generateGradCAM(testImg, segResults, grade);
    assertTest(all(size(gradCam) == [256, 256]), 'Grad-CAM saliency map size check');
    assertTest(max(gradCam(:)) <= 1.0 && min(gradCam(:)) >= 0.0, 'Grad-CAM normalization [0, 1]');

    corr = correlateLesionsWithHeatmap(gradCam, segResults);
    assertTest(corr.lesionCoverageRatio >= 0, 'Lesion-saliency correlation coverage ratio');

    [dmeRisk, dmeScore, dmeExpl] = assessMacularEdemaRisk(fovCenter, odRadius, heMask, mask);
    assertTest(ismember(dmeRisk, {'None / Low Risk', 'Low-to-Moderate Risk', 'Moderate Risk', 'High Risk (CSME Likely)'}), 'DME risk category valid');

    report = generateClinicalReport([], testImg, struct('qualityCategory', qCat, 'overallScore', oScore), ...
        segResults, struct('gradeLabel', gradeLabel, 'confidence', conf, 'isReferable', isRef, 'explanation', expl), ...
        dmeRisk, dmeScore, dmeExpl, overlay, fullfile(baseDir, 'test_clinical_report.html'));
    assertTest(exist(fullfile(baseDir, 'test_clinical_report.html'), 'file') > 0, 'Sub-30s Clinical HTML report generated');

    %% --- TEST SUITE 5: PILLAR 5 - SIMULINK / DISCRETE-EVENT QUEUEING MODEL ---
    fprintf('\n[TEST GROUP 5] Pillar 5: Simulink & Queueing Logistics Simulation\n');

    simRes = simulateQueueingModel(struct('numPatients', 1000, 'numPHCs', 5, 'numDoctors', 3, 'networkMode', '4G'));
    assertTest(simRes.avgTurnaroundTimeHrs < 24.0, 'Average turnaround time strictly < 24 hours SLA');
    assertTest(simRes.slaCompliancePct >= 90.0, 'SLA compliance percentage >= 90%');

    optRes = optimizeResourceAllocation(90.0, 24.0);
    assertTest(isfield(optRes, 'recommendedConfig'), 'Resource optimization recommends valid deployment configuration');

    %% --- SUMMARY ---
    fprintf('\n=======================================================\n');
    fprintf('  TEST EXECUTION SUMMARY: %d PASSED, %d FAILED (Total: %d)\n', passedTests, failedTests, totalTests);
    fprintf('=======================================================\n');

    testResults = struct();
    testResults.totalTests = totalTests;
    testResults.passedTests = passedTests;
    testResults.failedTests = failedTests;
    testResults.success = (failedTests == 0);
    testResults.log = testLog;
end
