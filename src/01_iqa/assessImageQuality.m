function [qualityCategory, overallScore, feedback, processedImg, report] = assessImageQuality(img)
% ASSESSIMAGEQUALITY Master Image Quality Assessment (IQA) module for PHC screening.
%   Categorizes fundus image as:
%     'Gradeable'   - High quality, ready for direct deep learning and rule inference.
%     'Borderline'  - Moderate quality, enhanced via Graham's norm + CLAHE before grading.
%     'Ungradeable' - Poor quality, triggers instant recapture feedback for rural operator.
%
% Syntax:
%   [qualityCategory, overallScore, feedback, processedImg, report] = assessImageQuality(img)
%
% Outputs:
%   qualityCategory - 'Gradeable', 'Borderline', or 'Ungradeable'
%   overallScore    - Composite quality score [0 - 100]
%   feedback        - Struct with technician actionable feedback
%   processedImg    - Standardized / enhanced image for downstream segmentation
%   report          - Struct with sub-metric scores
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    % 1. Sharpness & Focus
    [sharpnessScore, isSharp, sharpDetails] = checkFocusSharpness(imgD);

    % 2. Illumination & Exposure
    [illumScore, isUniform, illumDetails] = checkIlluminationUniformity(imgD);

    % 3. Field of View & Centering
    [coverageScore, isAdequateFOV, fovDetails] = checkFOVRetinalCoverage(imgD);

    % Composite IQA Score: weighted blend of all 3 pillars
    overallScore = 0.40 * sharpnessScore + 0.35 * illumScore + 0.25 * coverageScore;
    overallScore = min(100, max(0, overallScore));

    % Quality Decision Logic
    if overallScore >= 55.0 && isSharp && isAdequateFOV && (illumDetails.overexposedPct < 8.0)
        qualityCategory = 'Gradeable';
        processedImg = imgD;
    elseif overallScore >= 35.0 && (fovDetails.retinalAreaPct >= 35.0) && (sharpnessScore >= 8.0)
        qualityCategory = 'Borderline';
        [processedImg, ~] = enhanceBorderlineImage(imgD, fovDetails.retinalMask);
    else
        qualityCategory = 'Ungradeable';
        processedImg = imgD;
    end

    % Feedback generator
    feedback = generateRecaptureFeedback(sharpDetails, illumDetails, fovDetails);

    report = struct();
    report.qualityCategory = qualityCategory;
    report.overallScore = overallScore;
    report.sharpness = sharpDetails;
    report.illumination = illumDetails;
    report.fov = fovDetails;
    report.feedback = feedback;
end
