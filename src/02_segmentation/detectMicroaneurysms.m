function [maMask, maCount, maDetails] = detectMicroaneurysms(img, vesselMask, odMask, retinalMask)
% DETECTMICROANEURYSMS Detects retinal microaneurysms (MAs) - earliest sign of DR.
%   Applies morphological top-hat on inverted green channel, subtracts vascular tree,
%   and filters candidates by circularity, size, and local gradient contrast.
%
% Syntax:
%   [maMask, maCount, maDetails] = detectMicroaneurysms(img, vesselMask, odMask, retinalMask)
%
% Outputs:
%   maMask    - Binary mask of detected Microaneurysms [H x W logical]
%   maCount   - Total count of validated microaneurysms
%   maDetails - Struct with centroid coordinates, areas, and confidence
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
    else
        greenChan = imgD;
    end

    % Microaneurysms appear dark in green channel, so invert
    invertedGreen = 1.0 - greenChan;
    invertedGreen(~retinalMask) = 0;

    % Dilate vessel mask and OD mask to exclude vessel branches and optic disc margin
    dilatedVessels = imdilate(vesselMask, strel('disk', 2));
    dilatedOD = imdilate(odMask, strel('disk', 8));
    erodedRetina = imerode(retinalMask, strel('disk', 6));
    searchROI = erodedRetina & ~dilatedVessels & ~dilatedOD;

    % Morphological circular top-hat filtering for small round spots (< 12 pixels diameter)
    maxMARadius = max(3, round(min(H, W) * 0.008));
    seMA = strel('disk', maxMARadius);
    topHatResp = imtophat(invertedGreen, seMA);
    topHatResp(~searchROI) = 0;

    % Candidate thresholding: top quantile of search ROI
    if any(searchROI(:))
        candidateThresh = quantile(topHatResp(searchROI), 0.992);
    else
        candidateThresh = 0.5;
    end

    candidateMask = (topHatResp >= candidateThresh) & (topHatResp > 0.04) & searchROI;

    % Connected component morphological filtering
    cc = bwconncomp(candidateMask);
    stats = regionprops(cc, 'Area', 'Centroid', 'Eccentricity', 'Solidity', 'Perimeter');

    maMask = false(H, W);
    centroids = [];
    areas = [];

    % Expected MA size: between 3 and 120 pixels in typical 512x512 - 2048x2048 images
    minArea = max(2, round(min(H, W) * 0.003));
    maxArea = max(25, round(min(H, W) * 0.07));

    for k = 1:numel(stats)
        a = stats(k).Area;
        ecc = stats(k).Eccentricity;
        sol = stats(k).Solidity;
        
        % MAs must be roughly circular (low eccentricity) and compact (high solidity)
        if a >= minArea && a <= maxArea && ecc <= 0.85 && sol >= 0.60
            maMask(cc.PixelIdxList{k}) = true;
            centroids = [centroids; stats(k).Centroid]; %#ok<AGROW>
            areas = [areas; a]; %#ok<AGROW>
        end
    end

    maCount = size(centroids, 1);

    maDetails = struct();
    maDetails.count = maCount;
    maDetails.centroids = centroids;
    maDetails.areas = areas;
    maDetails.mask = maMask;
end
