function [coverageScore, isAdequate, details] = checkFOVRetinalCoverage(img, minCoveragePct)
% CHECKFOVRETINALCOVERAGE Validates Field of View (FOV) and retinal mask completeness.
%   Ensures fundus image captures sufficient retinal surface and is properly centered.
%
% Syntax:
%   [coverageScore, isAdequate, details] = checkFOVRetinalCoverage(img)
%   [coverageScore, isAdequate, details] = checkFOVRetinalCoverage(img, minCoveragePct)
%
% Inputs:
%   img            - RGB fundus image (uint8 or double)
%   minCoveragePct - (Optional) Minimum retinal mask coverage percentage (default: 45.0)
%
% Outputs:
%   coverageScore - FOV quality score [0 - 100]
%   isAdequate    - Boolean flag (true if FOV is acceptable for grading)
%   details       - Struct containing retinal mask, center offset, circularity
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs
    if nargin < 2 || isempty(minCoveragePct)
        minCoveragePct = 45.0; % Typical circular fundus occupies 50-80% of square sensor
    end
    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end
    [H, W, ~] = size(imgD);
    totalPixels = H * W;
    % Red channel or grayscale thresholding to find retinal disc
    if size(imgD, 3) == 3
        redChan = imgD(:, :, 1);
        grayImg = rgb2gray(imgD);
    else
        redChan = imgD;
        grayImg = imgD;
    end
    % Binary retinal mask extraction with morphological cleanup
    rawMask = (redChan > 0.08) | (grayImg > 0.05);
    se = strel('disk', max(3, round(min([H, W]) * 0.015)), 0);
    cleanMask = imclose(rawMask, se);
    cleanMask = imfill(cleanMask, 'holes');
    % Keep largest connected component (the retinal field)
    cc = bwconncomp(cleanMask);
    if cc.NumObjects > 0
        numPixels = cellfun(@numel, cc.PixelIdxList);
        [maxNum, maxIdx] = max(numPixels);
        retinalMask = false(size(cleanMask));
        retinalMask(cc.PixelIdxList{maxIdx}) = true;
    else
        retinalMask = false(size(cleanMask));
        maxNum = 0;
    end
    retinalAreaPct = (maxNum / totalPixels) * 100;
    % Retinal mask centroid and circularity check
    props = regionprops(retinalMask, 'Centroid', 'Eccentricity', 'Area', 'Perimeter');
    if ~isempty(props)
        imgCenter = [W / 2, H / 2];
        centroid = props(1).Centroid;
        normOffset = norm(centroid - imgCenter) / (min(H, W) / 2); % 0 is perfect center
        eccentricity = props(1).Eccentricity; % 0 is circle, near 1 is slit
    else
        centroid = [W / 2, H / 2];
        normOffset = 1.0;
        eccentricity = 1.0;
    end
    % Score based on coverage, decentration penalty, and shape circularity
    coverageFactor = min(1.0, retinalAreaPct / 65.0);
    centerPenalty = min(1.0, normOffset * 0.5);
    shapeFactor = max(0, 1.0 - eccentricity * 0.4);
    coverageScore = max(0, min(100, (coverageFactor * 0.6 + shapeFactor * 0.4 - centerPenalty * 0.3) * 100));
    isAdequate = (retinalAreaPct >= minCoveragePct) && (normOffset < 0.45);
    details = struct();
    details.coverageScore = coverageScore;
    details.isAdequate = isAdequate;
    details.retinalAreaPct = retinalAreaPct;
    details.normCenterOffset = normOffset;
    details.eccentricity = eccentricity;
    details.retinalMask = retinalMask;
end

