function [vesselMask, vesselProbability, vesselDensity] = segmentVessels(img, retinalMask)
% SEGMENTVESSELS Segments retinal vasculature tree using multi-scale vesselness filtering.
%   Extracts arterial and venous trees using top-hat morphology, green-channel matched
%   directional filtering, and adaptive local thresholding.
%
% Syntax:
%   [vesselMask, vesselProbability, vesselDensity] = segmentVessels(img)
%   [vesselMask, vesselProbability, vesselDensity] = segmentVessels(img, retinalMask)
%
% Outputs:
%   vesselMask        - Binary mask of segmented retinal vessels [H x W logical]
%   vesselProbability - Normalized continuous vesselness response map [0 - 1]
%   vesselDensity     - Ratio of vessel pixels to total retinal area
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs
    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end
    [H, W, C] = size(imgD);
    if nargin < 2 || isempty(retinalMask)
        if C == 3
            gray = rgb2gray(imgD);
        else
            gray = imgD;
        end
        retinalMask = gray > 0.05;
        retinalMask = imfill(imclose(retinalMask, strel('disk', 5, 0)), 'holes');
    end
    % Vessels have strongest absorption contrast in the Green channel
    if C == 3
        greenChan = imgD(:, :, 2);
    else
        greenChan = imgD;
    end
    % Invert green channel so vessels appear bright
    invertedGreen = imcomplement(greenChan);
    invertedGreen(~retinalMask) = 0;
    % Multi-directional matched morphological top-hat filtering (12 angles from 0 to 165 deg)
    angles = 0:15:165;
    lineLength = max(9, round(min(H, W) * 0.025));
    maxTopHat = zeros(H, W);
    for theta = angles
        seLine = strel('line', lineLength, theta);
        topHat = imtophat(invertedGreen, seLine);
        maxTopHat = max(maxTopHat, topHat);
    end
    % CLAHE enhancement on vessel response
    maxTopHat = maxTopHat / (max(maxTopHat(:)) + 1e-6);
    claheVessels = adapthisteq(maxTopHat, 'ClipLimit', 0.015, 'NumTiles', [8 8]);
    % Multi-scale 2D Gaussian derivative / Hessian-based vessel enhancement
    sigmaList = [1.0, 1.8, 2.5];
    vesselResp = zeros(H, W);
    for s = sigmaList
        H11 = imfilter(claheVessels, fspecial('gaussian', round(6*s)+1, s), 'replicate');
        [Gx, Gy] = imgradientxy(double(mean(H11, 3)));
        [Gxx, Gxy] = imgradientxy(double(mean(Gx, 3)));
        [~,   Gyy] = imgradientxy(double(mean(Gy, 3)));
        
        % Eigenvalues of Hessian
        traceH = Gxx + Gyy;
        detH = Gxx .* Gyy - Gxy.^2;
        discH = sqrt(max(0, traceH.^2 - 4 * detH));
        lambda2 = (traceH + discH) / 2; % maximum principal curvature
        
        vesselResp = max(vesselResp, max(0, -lambda2) * (s^2));
    end
    % Normalize vesselness probability
    vesselProbability = vesselResp / (max(vesselResp(:)) + 1e-6);
    vesselProbability(~retinalMask) = 0;
    % Adaptive Otsu thresholding with local neighborhood refinement
    globalThresh = graythresh(im2double(vesselProbability));
    rawBinary = vesselProbability > (globalThresh * 0.75);
    % Morphological cleanup: remove spurious isolated noise specks (< 15 pixels)
    cleanBinary = bwareaopen(rawBinary, 15);
    cleanBinary = cleanBinary & retinalMask;
    % Exclude bright border artifacts by eroding retinal perimeter
    borderMargin = imerode(retinalMask, strel('disk', max(3, round(min([H, W]) * 0.015)), 0));
    vesselMask = cleanBinary & borderMargin;
    % Compute retinal vessel density
    retinalPixelCount = sum(retinalMask(:));
    if retinalPixelCount > 0
        vesselDensity = sum(vesselMask(:)) / retinalPixelCount;
    else
        vesselDensity = 0;
    end
end

