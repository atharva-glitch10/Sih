function interactiveTriageApp()
% INTERACTIVETRIAGEAPP Full interactive graphical dashboard for rural tele-ophthalmologists.
%   Provides interactive controls to load images, run automated multi-pillar AI
%   screening, inspect Grad-CAM & segmented lesions, and export clinical sign-off reports.
%
% Syntax:
%   interactiveTriageApp()
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    % Initialize main UI window
    fig = uifigure('Name', 'MathWorks SIH: Rural DR Tele-Screening AI Dashboard', ...
                   'Position', [80, 60, 1340, 800], 'Color', [0.96, 0.97, 0.99]);

    % Top Banner
    pnlBanner = uipanel(fig, 'Position', [10, 735, 1320, 55], 'BackgroundColor', [0.12, 0.22, 0.38]);
    uilabel(pnlBanner, 'Text', 'MathWorks AI: Diabetic Retinopathy Screening & Sub-30s Clinical Verification', ...
            'Position', [20, 12, 850, 30], 'FontSize', 16, 'FontWeight', 'bold', 'FontColor', [1 1 1]);
    uilabel(pnlBanner, 'Text', 'Rural PHC Tele-Ophthalmology Edge Node', ...
            'Position', [950, 14, 340, 24], 'FontSize', 12, 'FontColor', [0.85 0.92 1.0], 'HorizontalAlignment', 'right');

    % Left Control Sidebar
    pnlSidebar = uipanel(fig, 'Position', [10, 10, 280, 715], 'Title', 'SCREENING WORKFLOW', ...
                         'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1]);

    btnLoad = uibutton(pnlSidebar, 'push', 'Text', '1. Load Fundus Image', ...
                       'Position', [15, 630, 250, 42], 'FontSize', 12, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.20, 0.50, 0.85], 'FontColor', [1 1 1]);

    btnRunAI = uibutton(pnlSidebar, 'push', 'Text', '2. Run AI Diagnostic Core', ...
                        'Position', [15, 575, 250, 42], 'FontSize', 12, 'FontWeight', 'bold', ...
                        'BackgroundColor', [0.18, 0.65, 0.35], 'FontColor', [1 1 1], 'Enable', 'off');

    btnExportReport = uibutton(pnlSidebar, 'push', 'Text', '3. Export Sub-30s Report', ...
                              'Position', [15, 520, 250, 42], 'FontSize', 12, 'FontWeight', 'bold', ...
                              'BackgroundColor', [0.85, 0.45, 0.15], 'FontColor', [1 1 1], 'Enable', 'off');

    btnSimulink = uibutton(pnlSidebar, 'push', 'Text', '4. Run Logistics Simulation', ...
                           'Position', [15, 465, 250, 42], 'FontSize', 12, 'FontWeight', 'bold', ...
                           'BackgroundColor', [0.55, 0.25, 0.70], 'FontColor', [1 1 1]);

    % Patient Details Form in Sidebar
    uilabel(pnlSidebar, 'Text', 'Patient ID:', 'Position', [15, 410, 100, 22], 'FontWeight', 'bold');
    txtPatientID = uieditfield(pnlSidebar, 'text', 'Value', 'PHC-PUN-0941', 'Position', [15, 385, 250, 26]);

    uilabel(pnlSidebar, 'Text', 'Age / Gender:', 'Position', [15, 350, 100, 22], 'FontWeight', 'bold');
    txtAgeGender = uieditfield(pnlSidebar, 'text', 'Value', '58 / Male', 'Position', [15, 325, 250, 26]);

    uilabel(pnlSidebar, 'Text', 'Screening PHC:', 'Position', [15, 290, 120, 22], 'FontWeight', 'bold');
    txtPHC = uieditfield(pnlSidebar, 'text', 'Value', 'Rural PHC Haveli, Pune', 'Position', [15, 265, 250, 26]);

    % Layer View Toggles
    uilabel(pnlSidebar, 'Text', 'Display Overlays:', 'Position', [15, 220, 150, 22], 'FontWeight', 'bold');
    chkLandmarks = uicheckbox(pnlSidebar, 'Text', 'Optic Disc & Fovea', 'Value', true, 'Position', [15, 195, 200, 22]);
    chkVessels = uicheckbox(pnlSidebar, 'Text', 'Vasculature Tree', 'Value', true, 'Position', [15, 170, 200, 22]);
    chkLesions = uicheckbox(pnlSidebar, 'Text', 'Lesion Map (MAs, HMs, HE)', 'Value', true, 'Position', [15, 145, 200, 22]);
    chkGradCAM = uicheckbox(pnlSidebar, 'Text', 'Grad-CAM Attention', 'Value', true, 'Position', [15, 120, 200, 22]);

    % Status message box
    lblStatus = uilabel(pnlSidebar, 'Text', 'Ready. Please load a fundus image.', ...
                        'Position', [15, 15, 250, 85], 'FontSize', 11, 'FontColor', [0.3 0.3 0.3]);

    % Center/Right Display Area
    % 4 Visual Panels: (1) Original + Landmarks, (2) Vasculature, (3) Lesion Map, (4) Grad-CAM Saliency
    ax1 = uiaxes(fig, 'Position', [305, 385, 330, 340]); title(ax1, '1. Original & Landmarks'); axis(ax1, 'off');
    ax2 = uiaxes(fig, 'Position', [645, 385, 330, 340]); title(ax2, '2. Vasculature Segmentation'); axis(ax2, 'off');
    ax3 = uiaxes(fig, 'Position', [985, 385, 330, 340]); title(ax3, '3. Micro-Lesion Overlays'); axis(ax3, 'off');
    ax4 = uiaxes(fig, 'Position', [305, 25, 330, 340]);  title(ax4, '4. Grad-CAM AI Saliency'); axis(ax4, 'off');

    % Diagnostic Summary Panel
    pnlDiag = uipanel(fig, 'Position', [645, 25, 670, 340], 'Title', 'CLINICAL AI TRIAGE & BIOMARKER QUANTIFICATION', ...
                      'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1]);

    lblTriageBadge = uilabel(pnlDiag, 'Text', 'NO ACTIVE IMAGE PROCESSED', ...
                             'Position', [20, 270, 630, 38], 'FontSize', 13, 'FontWeight', 'bold', ...
                             'BackgroundColor', [0.8 0.8 0.8], 'FontColor', [0.2 0.2 0.2], ...
                             'HorizontalAlignment', 'center');

    txtDiagSummary = uitextarea(pnlDiag, 'Position', [20, 20, 630, 235], 'FontSize', 12, ...
                                'Editable', 'off', 'Value', {'Load an image and click "Run AI Diagnostic Core" to generate explainable clinical findings.'});

    % Internal State Struct
    appState = struct();
    appState.rawImg = [];
    appState.segResults = [];
    appState.gradingResults = [];
    appState.iqaReport = [];

    % --- CALLBACK FUNCTIONS ---
    btnLoad.ButtonPushedFcn = @(~, ~) loadSampleImage();
    btnRunAI.ButtonPushedFcn = @(~, ~) executeAIPipeline();
    btnExportReport.ButtonPushedFcn = @(~, ~) exportReportAction();
    btnSimulink.ButtonPushedFcn = @(~, ~) runSimulinkAction();

    function loadSampleImage()
        % Check data directory for synthetic samples or prompt file chooser
        sampleDir = fullfile(pwd, 'data', 'synthetic');
        files = dir(fullfile(sampleDir, '*.png'));
        if ~isempty(files)
            samplePath = fullfile(sampleDir, files(min(4, numel(files))).name);
            appState.rawImg = imread(samplePath);
            appState.imgFilename = files(min(4, numel(files))).name;
        else
            % Generate demo image on the fly
            samplePath = fullfile(pwd, 'data', 'synthetic', 'DR_Grade3_Sample01.png');
            if exist(samplePath, 'file')
                appState.rawImg = imread(samplePath);
            else
                dataset = generateSyntheticFundusDataset(sampleDir, 2);
                appState.rawImg = imread(dataset(end).filepath);
            end
        end

        imshow(appState.rawImg, 'Parent', ax1);
        title(ax1, '1. Loaded Raw Fundus Image');
        btnRunAI.Enable = 'on';
        lblStatus.Text = 'Image loaded. Click "Run AI Diagnostic Core" to screen.';
    end

    function executeAIPipeline()
        lblStatus.Text = 'Analyzing image quality and extracting lesions...';
        drawnow;

        % 1. IQA
        [qCat, qScore, iqaFb, procImg, iqaRep] = assessImageQuality(appState.rawImg);
        retinalMask = iqaRep.fov.retinalMask;

        % 2. Retinal Landmarks & Lesions
        [odMask, odCenter, odRadius] = locateOpticDisc(procImg, retinalMask);
        [foveaCenter, foveaMask, maculaRegionMask] = locateFoveaCenter(procImg, odCenter, odRadius, retinalMask);
        [vesselMask, vesselProb, vesselDensity] = segmentVessels(procImg, retinalMask);
        [maMask, maCount, maDet] = detectMicroaneurysms(procImg, vesselMask, odMask, retinalMask);
        [heMask, heArea, heDet] = segmentHardExudates(procImg, odMask, retinalMask);
        [hmMask, hmCount, hmDet] = segmentHemorrhages(procImg, vesselMask, odMask, retinalMask);
        [nvDetected, nvMask, nvDet] = detectNeovascularization(procImg, vesselMask, odMask, retinalMask);

        seg = struct();
        seg.retinalMask = retinalMask;
        seg.odCenter = odCenter; seg.odRadius = odRadius; seg.odMask = odMask;
        seg.foveaCenter = foveaCenter; seg.foveaMask = foveaMask; seg.maculaRegionMask = maculaRegionMask;
        seg.vesselMask = vesselMask; seg.vesselDensity = vesselDensity;
        seg.maMask = maMask; seg.maDetails = maDet;
        seg.heMask = heMask; seg.heDetails = heDet; seg.heArea = heArea;
        seg.hmMask = hmMask; seg.hmDetails = hmDet;
        seg.nvMask = nvMask; seg.nvDetails = nvDet;

        % 3. DR Classification
        model = trainDRClassifier();
        [grade, gradeLabel, conf, isRef, probs, expl, details] = classifyDRSeverity(procImg, seg, model);

        % 4. Explainability & Grad-CAM
        [gradCamMap, overlay] = generateGradCAM(procImg, seg, grade);
        [dmeRisk, dmeScore, dmeExpl] = assessMacularEdemaRisk(foveaCenter, odRadius, heMask, retinalMask);

        appState.segResults = seg;
        appState.gradingResults = struct('grade', grade, 'gradeLabel', gradeLabel, 'confidence', conf, ...
            'isReferable', isRef, 'probs', probs, 'explanation', expl, 'details', details);
        appState.dmeRisk = dmeRisk;
        appState.dmeScore = dmeScore;
        appState.dmeExpl = dmeExpl;
        appState.overlay = overlay;
        appState.iqaReport = iqaRep;

        % Update Visual Axes
        % Panel 1: Original + Landmarks
        imshow(procImg, 'Parent', ax1);
        title(ax1, sprintf('1. IQA: %s (%.1f/100)', qCat, qScore));

        % Panel 2: Vasculature
        vRGB = zeros(size(procImg, 1), size(procImg, 2), 3);
        vRGB(:, :, 2) = double(vesselMask) * 0.9;
        vRGB(:, :, 3) = double(vesselMask) * 0.6;
        imshow(vRGB, 'Parent', ax2);
        title(ax2, sprintf('2. Vessel Density: %.2f%%', vesselDensity * 100));

        % Panel 3: Lesion Map
        grayBase = repmat(rgb2gray(procImg) * 0.4, [1 1 3]);
        if any(heMask(:)), grayBase(repmat(heMask, [1 1 3])) = 1.0; end
        if any(hmMask(:)), grayBase(repmat(hmMask, [1 1 3])) = 0.8; end
        imshow(grayBase, 'Parent', ax3);
        title(ax3, sprintf('3. Lesions (MAs=%d, HMs=%d, HE=%d px)', maCount, hmCount, round(heArea)));

        % Panel 4: Grad-CAM
        imshow(overlay, 'Parent', ax4);
        title(ax4, '4. Grad-CAM AI Saliency Attention');

        % Update Diagnostic Summary Badge
        if isRef
            lblTriageBadge.Text = sprintf('[URGENT REFERRAL] %s (Conf: %.1f%%)', upper(gradeLabel), conf * 100);
            lblTriageBadge.BackgroundColor = [0.85, 0.20, 0.20];
            lblTriageBadge.FontColor = [1 1 1];
        else
            lblTriageBadge.Text = sprintf('[ROUTINE SCREENING] %s (Conf: %.1f%%)', upper(gradeLabel), conf * 100);
            lblTriageBadge.BackgroundColor = [0.20, 0.70, 0.30];
            lblTriageBadge.FontColor = [1 1 1];
        end

        % Update Diagnostic Text
        lines = { ...
            sprintf('• ICDR Severity Scale: %s (Confidence: %.1f%%)', gradeLabel, conf * 100), ...
            sprintf('• Diabetic Macular Edema: %s (Score: %d/100)', dmeRisk, dmeScore), ...
            sprintf('• 4-2-1 Rule Rationale: %s', details.ruleExplanation), ...
            sprintf('• Microaneurysms: %d | Hemorrhages: %d (in %d quadrants)', maCount, hmCount, seg.hmDetails.quadrantCounts.Q1_SuperiorTemporal + seg.hmDetails.quadrantCounts.Q2_SuperiorNasal), ...
            sprintf('• DME Macular Warning: %s', dmeExpl), ...
            sprintf('• Multi-Class Probs: [G0: %.2f, G1: %.2f, G2: %.2f, G3: %.2f, G4: %.2f]', probs) ...
        };
        txtDiagSummary.Value = lines;

        btnExportReport.Enable = 'on';
        lblStatus.Text = 'AI Grading Complete. Ready to export report.';
    end

    function exportReportAction()
        ptInfo = struct('PatientID', txtPatientID.Value, 'Age', 58, 'Gender', 'Male', ...
            'PHC_Location', txtPHC.Value, 'ScreeningDate', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
        outPath = fullfile(pwd, 'DR_Clinical_Report.html');
        generateClinicalReport(ptInfo, appState.rawImg, appState.iqaReport, appState.segResults, ...
            appState.gradingResults, appState.dmeRisk, appState.dmeScore, appState.dmeExpl, appState.overlay, outPath);
        lblStatus.Text = sprintf('Report saved: %s', outPath);
        web(outPath, '-browser');
    end

    function runSimulinkAction()
        lblStatus.Text = 'Running 100k-patient tele-screening logistics simulation...';
        drawnow;
        simRes = simulateQueueingModel(struct('numPatients', 100000, 'numPHCs', 10, 'numDoctors', 6, 'networkMode', '4G'));
        msg = sprintf('Simulink Model Results:\n• 100,000 Annual Patients (10 PHCs)\n• Avg Turnaround: %.2f hours (<24h SLA)\n• 24h SLA Compliance: %.1f%%\n• Doctor Pool Workload: %.1f%%\n• Bottleneck: %s', ...
            simRes.avgTurnaroundTimeHrs, simRes.slaCompliancePct, simRes.doctorUtilization * 100, simRes.bottleneck);
        uialert(fig, msg, 'Simulink Logistics Simulation Complete', 'Icon', 'info');
        lblStatus.Text = 'Simulation completed successfully.';
    end
end
