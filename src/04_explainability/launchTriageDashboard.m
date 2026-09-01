function hFig = launchTriageDashboard(imgOriginal, segResults, gradingResults, dmeRisk, dmeScore, gradCamOverlay, patientInfo)
% LAUNCHTRIAGEDASHBOARD Interactive multi-panel clinical dashboard for tele-screening.
%   Provides tele-ophthalmologists with rapid sub-30s triage visualizations:
%     Panel 1: Original Fundus with Optic Disc & Fovea landmarks
%     Panel 2: Segmented Retinal Vasculature & Density
%     Panel 3: Multi-Lesion Map (MAs=cyan, HMs=red, HE=yellow, NV=magenta)
%     Panel 4: Grad-CAM Saliency & DME Risk Zones
%     Panel 5: Diagnostic Decision Badge & Clinical Biomarker Table
%
% Syntax:
%   hFig = launchTriageDashboard(imgOriginal, segResults, gradingResults, dmeRisk, dmeScore, gradCamOverlay)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 7 || isempty(patientInfo)
        patientInfo = struct('PatientID', 'PHC-MH-0842', 'Age', 58, 'Gender', 'F');
    end

    if isa(imgOriginal, 'uint8')
        imgD = im2double(imgOriginal);
    else
        imgD = imgOriginal;
    end

    [H, W, ~] = size(imgD);

    % Create figure
    hFig = figure('Name', 'Rural Tele-Ophthalmology AI Triage Dashboard', ...
                  'NumberTitle', 'off', 'Color', [0.95 0.96 0.98], ...
                  'Position', [100 80 1280 780]);

    % Top Banner Title
    annotation('textbox', [0.03, 0.93, 0.94, 0.05], ...
        'String', sprintf('PHC TELE-SCREENING TRIAGE: Patient ID %s | Age: %d | Gender: %s', ...
        patientInfo.PatientID, patientInfo.Age, patientInfo.Gender), ...
        'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none', ...
        'BackgroundColor', [0.15 0.25 0.40], 'Color', 'white', 'HorizontalAlignment', 'center');

    % Panel 1: Original + Landmarks
    subplot('Position', [0.04, 0.52, 0.28, 0.38]);
    imshow(imgD); hold on;
    % Mark Optic Disc (green circle)
    theta = linspace(0, 2*pi, 100);
    odX = segResults.odCenter(1) + segResults.odRadius * cos(theta);
    odY = segResults.odCenter(2) + segResults.odRadius * sin(theta);
    plot(odX, odY, 'g-', 'LineWidth', 2);
    text(segResults.odCenter(1), segResults.odCenter(2) - segResults.odRadius - 5, ...
        'Optic Disc', 'Color', 'green', 'FontWeight', 'bold', 'FontSize', 9, 'HorizontalAlignment', 'center');
    
    % Mark Fovea (blue cross & circle)
    plot(segResults.foveaCenter(1), segResults.foveaCenter(2), 'bx', 'MarkerSize', 12, 'LineWidth', 2);
    fovX = segResults.foveaCenter(1) + (segResults.odRadius * 0.5) * cos(theta);
    fovY = segResults.foveaCenter(2) + (segResults.odRadius * 0.5) * sin(theta);
    plot(fovX, fovY, 'b--', 'LineWidth', 1.5);
    text(segResults.foveaCenter(1), segResults.foveaCenter(2) + segResults.odRadius * 0.7, ...
        'Fovea (FAZ)', 'Color', 'cyan', 'FontWeight', 'bold', 'FontSize', 9, 'HorizontalAlignment', 'center');
    title('1. Anatomical Landmarks', 'FontSize', 11, 'FontWeight', 'bold');
    hold off;

    % Panel 2: Vascular Tree
    subplot('Position', [0.36, 0.52, 0.28, 0.38]);
    vesselRGB = zeros(H, W, 3);
    vesselRGB(:, :, 1) = double(segResults.vesselMask) * 0.1;
    vesselRGB(:, :, 2) = double(segResults.vesselMask) * 0.9;
    vesselRGB(:, :, 3) = double(segResults.vesselMask) * 0.7;
    imshow(vesselRGB);
    title(sprintf('2. Vasculature (Density: %.2f%%)', segResults.vesselDensity * 100), ...
        'FontSize', 11, 'FontWeight', 'bold');

    % Panel 3: Color-Coded Lesion Map
    subplot('Position', [0.68, 0.52, 0.28, 0.38]);
    % Background grayscale fundus
    grayBase = repmat(rgb2gray(imgD) * 0.4, [1 1 3]);
    % Overlay lesions: MAs (Cyan), HMs (Red), HE (Yellow), NV (Magenta)
    lesionDisplay = grayBase;
    
    % Hard Exudates -> Bright Yellow [1 1 0]
    heMask3 = repmat(segResults.heMask, [1 1 3]);
    lesionDisplay(heMask3) = repmat([1, 1, 0], [sum(segResults.heMask(:)), 1]);

    % Hemorrhages -> Bright Red [1 0 0]
    hmMask3 = repmat(segResults.hmMask, [1 1 3]);
    lesionDisplay(hmMask3) = repmat([1, 0.1, 0.1], [sum(segResults.hmMask(:)), 1]);

    % Microaneurysms -> Bright Cyan [0 1 1] (dilated for visibility)
    dilatedMA = imdilate(segResults.maMask, strel('disk', 2));
    maMask3 = repmat(dilatedMA, [1 1 3]);
    lesionDisplay(maMask3) = repmat([0, 1, 1], [sum(dilatedMA(:)), 1]);

    % Neovascularization -> Magenta [1 0 1]
    if segResults.nvDetails.nvDetected
        nvMask3 = repmat(segResults.nvMask, [1 1 3]);
        lesionDisplay(nvMask3) = repmat([1, 0, 1], [sum(segResults.nvMask(:)), 1]);
    end

    imshow(lesionDisplay);
    title('3. Segmented Lesion Map', 'FontSize', 11, 'FontWeight', 'bold');

    % Panel 4: Grad-CAM Saliency
    subplot('Position', [0.04, 0.08, 0.28, 0.38]);
    imshow(gradCamOverlay);
    title('4. AI Grad-CAM Visual Attention', 'FontSize', 11, 'FontWeight', 'bold');

    % Panel 5: Clinical Biomarker Table & Decision Badge
    subplot('Position', [0.36, 0.08, 0.60, 0.38]);
    axis off;

    % Triage Color
    if gradingResults.isReferable
        badgeColor = [0.85 0.2 0.2];
        refText = 'URGENT SPECIALIST REFERRAL REQUIRED';
    else
        badgeColor = [0.2 0.7 0.3];
        refText = 'ROUTINE 12-MONTH RESCREENING';
    end

    % Render summary text boxes
    rectangle('Position', [0, 0.78, 1.0, 0.20], 'Curvature', 0.2, ...
        'FaceColor', badgeColor, 'EdgeColor', 'none');
    text(0.5, 0.88, sprintf('ICDR %s  |  CONFIDENCE: %.1f%%\n%s', ...
        upper(gradingResults.gradeLabel), gradingResults.confidence * 100, refText), ...
        'Color', 'white', 'FontWeight', 'bold', 'FontSize', 11, ...
        'HorizontalAlignment', 'center', 'Interpreter', 'none');

    % Biomarker statistics
    statsStr = { ...
        sprintf('\\bfMicroaneurysms (MAs):\\rm %d', segResults.maDetails.count), ...
        sprintf('\\bfHemorrhages (HMs):\\rm %d (4-Quadrant distribution: %d active)', ...
            segResults.hmDetails.count, segResults.features.quadsWithHMs), ...
        sprintf('\\bfHard Exudates (HE):\\rm %d px  |  \\bfDME Risk:\\rm %s (%d/100)', ...
            round(segResults.heDetails.totalArea), dmeRisk, dmeScore), ...
        sprintf('\\bfNeovascularization (NV):\\rm %s', string(logical(segResults.nvDetails.nvDetected))), ...
        sprintf('\\bfRationale:\\rm %s', gradingResults.ruleExplanation) ...
    };

    text(0.02, 0.40, statsStr, 'FontSize', 10, 'Interpreter', 'tex', 'VerticalAlignment', 'middle');
end
