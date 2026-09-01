function [hmMask, hmCount, hmDetails] = segmentHemorrhages(img, vesselMask, odMask, retinalMask)
% SEGMENTHEMORRHAGES Detects and segments retinal hemorrhages (dot/blot/flame).
%   Uses green channel absorption, vascular tree subtraction, and morphological
%   connected-component filtering across 4 retinal quadrants.
%
% Syntax:
%   [hmMask, hmCount, hmDetails] = segmentHemorrhages(img, vesselMask, odMask, retinalMask)
%
% Outputs:
%   hmMask    - Binary mask of detected Hemorrhages [H x W logical]
%   hmCount   - Number of distinct hemorrhage clusters
%   hmDetails - Struct with quadrant distribution, areas, and centroids
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    [H, W, C] = size(imgD);

    if nargin < 4 || isempty(retinalMask)
        if C == 3
            gray = rgb2gray(imgD);
        else
            gray = imgD;
        end
        retinalMask = gray > 0.05;
    end

    if nargin < 3 || isempty(odMask)
        odMask = false(H, W);
    end

    if nargin < 2 || isempty(vesselMask)
        vesselMask = false(H, W);
    end

    if C == 3
        greenChan = imgD(:, :, 2);
        redChan = imgD(:, :, 1);
    else
        greenChan = imgD;
        redChan = imgD;
    end

    % Inverted green channel highlights blood lesions
    invertedGreen = 1.0 - greenChan;
    invertedGreen(~retinalMask) = 0;

    % Exclude main vessels and optic disc
    dilatedVessels = imdilate(vesselMask, strel('disk', 3));
    dilatedOD = imdilate(odMask, strel('disk', 10));
    erodedRetina = imerode(retinalMask, strel('disk', 8));
    searchArea = erodedRetina & ~dilatedVessels & ~dilatedOD;

    % Hemorrhages are larger than microaneurysms, so we use a medium-sized top-hat
    seHM = strel('disk', max(5, round(min(H, W) * 0.02)));
    hmTopHat = imtophat(invertedGreen, seHM);
    hmTopHat(~searchArea) = 0;

    % Relative thresholding
    if any(searchArea(:))
        thresh = quantile(hmTopHat(searchArea), 0.982);
        rawCandidates = (hmTopHat >= thresh) & (hmTopHat > 0.05) & searchArea;
    else
        rawCandidates = false(H, W);
    end

    % Morphological cleanup
    cleanCandidates = bwareaopen(rawCandidates, 12); % Larger than MAs

    % Component filtering: Exclude thin elongated fragments (residual vessel parts)
    cc = bwconncomp(cleanCandidates);
    stats = regionprops(cc, 'Area', 'Centroid', 'Eccentricity', 'Solidity', 'PixelIdxList');

    hmMask = false(H, W);
    centroids = [];
    areas = [];
    quadrantCounts = struct('Q1_SuperiorTemporal', 0, 'Q2_SuperiorNasal', 0, ...
                            'Q3_InferiorNasal', 0, 'Q4_InferiorTemporal', 0);

    centerX = W / 2;
    centerY = H / 2;

    for k = 1:numel(stats)
        pix = stats(k).PixelIdxList;
        a = stats(k).Area;
        ecc = stats(k).Eccentricity;
        
        % Hemorrhages have moderate solidity and aren't as extreme in eccentricity as vessel branches
        if ecc < 0.92 && a >= 12
            hmMask(pix) = true;
            pt = stats(k).Centroid;
            centroids = [centroids; pt]; %#ok<AGROW>
            areas = [areas; a]; %#ok<AGROW>
            
            % Assign to 4 quadrants (for the 4-2-1 clinical rule)
            if pt(1) >= centerX && pt(2) < centerY
                quadrantCounts.Q1_SuperiorTemporal = quadrantCounts.Q1_SuperiorTemporal + 1;
            elseif pt(1) < centerX && pt(2) < centerY
                quadrantCounts.Q2_SuperiorNasal = quadrantCounts.Q2_SuperiorNasal + 1;
            elseif pt(1) < centerX && pt(2) >= centerY
                quadrantCounts.Q3_InferiorNasal = quadrantCounts.Q3_InferiorNasal + 1;
            else
                quadrantCounts.Q4_InferiorTemporal = quadrantCounts.Q4_InferiorTemporal + 1;
            end
        end
    end

    hmCount = size(centroids, 1);

    hmDetails = struct();
    hmDetails.count = hmCount;
    hmDetails.centroids = centroids;
    hmDetails.areas = areas;
    hmDetails.totalArea = sum(areas);
    hmDetails.quadrantCounts = quadrantCounts;
    hmDetails.mask = hmMask;
end
