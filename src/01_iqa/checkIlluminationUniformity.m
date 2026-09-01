function [illumScore, isUniform, details] = checkIlluminationUniformity(img, minScore)
% CHECKILLUMINATIONUNIFORMITY Analyzes fundus illumination, exposure, and entropy.
%
% Syntax:
%   [illumScore, isUniform, details] = checkIlluminationUniformity(img)
%   [illumScore, isUniform, details] = checkIlluminationUniformity(img, minScore)
%
% Inputs:
%   img      - RGB fundus image (uint8 or double)
%   minScore - (Optional) Minimum illumination score threshold (default: 30.0)
%
% Outputs:
%   illumScore - Composite illumination score [0 - 100]
%   isUniform  - Boolean flag (true if illumination is acceptable)
%   details    - Struct containing over-exposure, under-exposure, entropy metrics
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 2 || isempty(minScore)
        minScore = 30.0;
    end

    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    % Convert to grayscale / intensity channel
    if size(imgD, 3) == 3
        grayImg = rgb2gray(imgD);
    else
        grayImg = imgD;
    end

    % Foreground retinal mask (exclude black background margins)
    retinalMask = grayImg > 0.04;
    numRetinalPixels = sum(retinalMask(:));

    if numRetinalPixels == 0
        illumScore = 0;
        isUniform = false;
        details = struct('overexposedPct', 100, 'underexposedPct', 100, ...
            'entropy', 0, 'meanIntensity', 0, 'stdIntensity', 0, 'isUniform', false);
        return;
    end

    retinalVals = grayImg(retinalMask);

    % Metric 1: Overexposure percentage (glare/saturation artifacts > 0.92)
    overexposedPct = (sum(retinalVals > 0.92) / numRetinalPixels) * 100;

    % Metric 2: Underexposure percentage (too dark < 0.12)
    underexposedPct = (sum(retinalVals < 0.12) / numRetinalPixels) * 100;

    % Metric 3: Information entropy on retinal mask
    histCounts = histcounts(retinalVals, 64, 'Normalization', 'probability');
    histCounts(histCounts == 0) = [];
    entropyVal = -sum(histCounts .* log2(histCounts)); % max ~6 for 64 bins

    % Metric 4: Mean and Standard Deviation of Intensity
    meanInt = mean(retinalVals);
    stdInt = std(retinalVals);

    % Penalties for severe lighting defects
    overPen = max(0, (overexposedPct - 3.0) * 4);
    underPen = max(0, (underexposedPct - 15.0) * 2.5);
    entropyNorm = min(100, (entropyVal / 5.5) * 100);

    % Target ideal mean intensity between 0.35 and 0.65
    intensityPenalty = abs(meanInt - 0.50) * 100;

    % Composite score calculation
    rawScore = entropyNorm - overPen - underPen - 0.4 * intensityPenalty;
    illumScore = min(100, max(0, rawScore));

    isUniform = (illumScore >= minScore) && (overexposedPct < 15.0) && (underexposedPct < 40.0);

    details = struct();
    details.illumScore = illumScore;
    details.isUniform = isUniform;
    details.overexposedPct = overexposedPct;
    details.underexposedPct = underexposedPct;
    details.entropy = entropyVal;
    details.meanIntensity = meanInt;
    details.stdIntensity = stdInt;
end
