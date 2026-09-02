function [heMask, heArea, heDetails] = segmentHardExudates(img, odMask, retinalMask)
% SEGMENTHARDEXUDATES Segments hard exudates (HE) - bright lipid deposits.
%   Uses L*a*b* color transformation, luminance/yellow-chrominance thresholding,
%   and optic disc masking to prevent false positives from physiological OD brightness.
%
% Syntax:
%   [heMask, heArea, heDetails] = segmentHardExudates(img, odMask, retinalMask)
%
% Outputs:
%   heMask    - Binary mask of detected Hard Exudates [H x W logical]
%   heArea    - Total pixel area occupied by Hard Exudates
%   heDetails - Struct with cluster centroids, count, and intensity features
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs
    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end
    [H, W, C] = size(imgD);
    if nargin < 3 || isempty(retinalMask)
        if C == 3
            gray = rgb2gray(imgD);
        else
            gray = imgD;
        end
        retinalMask = gray > 0.05;
    end
    if nargin < 2 || isempty(odMask)
        odMask = false(H, W);
    end
    % Hard exudates are bright yellow/white, best distinguished in Lab color space
    if C == 3
        labImg = rgb2lab(imgD);
        L = labImg(:, :, 1); % Luminance [0, 100]
        b = labImg(:, :, 3); % Yellow-Blue chromaticity (+b is yellow)
        
        % Normalize channels
        L_norm = (L - min(L(:))) / (max(L(:)) - min(L(:)) + 1e-6);
        b_norm = (b - min(b(:))) / (max(b(:)) - min(b(:)) + 1e-6);
        
        % Hard exudate intensity index: High Luminance + Strong Yellow Chrominance
        heIndex = 0.55 * L_norm + 0.45 * b_norm;
    else
        heIndex = imgD;
    end
    % Exclude Optic Disc (with dilation margin) and retinal border
    dilatedOD = imdilate(odMask, strel('disk', max(1, round(min([H, W]) * 0.035)), 0));
    erodedRetina = imerode(retinalMask, strel('disk', 6, 0));
    validROI = erodedRetina & ~dilatedOD;
    heIndex(~validROI) = 0;
    % Dynamic thresholding relative to retinal background
    if any(validROI(:))
        bgMean = mean(heIndex(validROI));
        bgStd = std(heIndex(validROI));
        threshold = bgMean + 1.85 * bgStd;
        rawHE = (heIndex >= threshold) & (heIndex > 0.55) & validROI;
    else
        rawHE = false(H, W);
    end
    % Morphological opening and area cleanup
    seSmall = strel('disk', 1, 0);
    openedHE = imopen(rawHE, seSmall);
    cleanHE = bwareaopen(openedHE, 4); % remove 1-3 pixel noise
    % Filter candidate clusters using gradient sharpness (HE has sharp boundaries)
    [Gx, Gy] = imgradientxy(heIndex);
    gradMag = sqrt(Gx.^2 + Gy.^2);
    cc = bwconncomp(cleanHE);
    stats = regionprops(cc, 'Area', 'Centroid', 'PixelIdxList', 'Perimeter');
    heMask = false(H, W);
    clusterCentroids = [];
    clusterAreas = [];
    for k = 1:numel(stats)
        pix = stats(k).PixelIdxList;
        % Average edge gradient of the cluster
        clusterGrad = mean(gradMag(pix));
        if clusterGrad >= 0.015 && stats(k).Area <= round(min(H, W) * 0.05 * min(H, W) * 0.05)
            heMask(pix) = true;
            clusterCentroids = [clusterCentroids; stats(k).Centroid]; %#ok<AGROW>
            clusterAreas = [clusterAreas; stats(k).Area]; %#ok<AGROW>
        end
    end
    heArea = sum(heMask(:));
    heDetails = struct();
    heDetails.count = size(clusterCentroids, 1);
    heDetails.totalArea = heArea;
    heDetails.centroids = clusterCentroids;
    heDetails.areas = clusterAreas;
    heDetails.mask = heMask;
end

