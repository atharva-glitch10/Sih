function [enhancedImg, greenEnhanced] = enhanceBorderlineImage(img, retinalMask)
% ENHANCEBORDERLINEIMAGE Adaptive enhancement for borderline fundus images.
%   Applies:
%     1. Graham's local color constancy method (subtractive Gaussian background normalization)
%     2. CLAHE (Contrast-Limited Adaptive Histogram Equalization) on green channel
%     3. Edge-preserving smoothing (bilateral or guided filter) to suppress sensor noise
%
% Syntax:
%   [enhancedImg, greenEnhanced] = enhanceBorderlineImage(img)
%   [enhancedImg, greenEnhanced] = enhanceBorderlineImage(img, retinalMask)
%
% Reference:
%   Graham, B. "Kaggle Diabetic Retinopathy Detection competition." (2015)
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
        se = strel('disk', max(3, round(min(H, W) * 0.02)));
        retinalMask = imfill(imclose(retinalMask, se), 'holes');
    end

    % 1. Graham's Local Color Normalization: I_norm = 4*I - 4*Gaussian(I, sigma) + 128
    % Scales with retinal radius
    sigma = max(10, min(H, W) / 30);
    gaussianKernel = fspecial('gaussian', round(6 * sigma) + 1, sigma);

    enhancedChannels = zeros(H, W, C);
    for c = 1:C
        channel = imgD(:, :, c);
        bg = imfilter(channel, gaussianKernel, 'replicate', 'conv');
        % Weighted local subtraction
        normChan = 4 * channel - 4 * bg + 0.5;
        % Constrain inside retinal mask
        normChan(~retinalMask) = 0;
        normChan = max(0, min(1, normChan));
        enhancedChannels(:, :, c) = normChan;
    end

    % 2. CLAHE on Green Channel for Micro-Vessel & Lesion Visualisation
    if C == 3
        greenChan = enhancedChannels(:, :, 2);
    else
        greenChan = enhancedChannels;
    end
    
    % Contrast enhancement with clip limit
    claheGreen = adapthisteq(greenChan, 'ClipLimit', 0.02, 'Distribution', 'uniform', 'NumTiles', [8 8]);
    claheGreen(~retinalMask) = 0;
    
    if C == 3
        enhancedChannels(:, :, 2) = 0.7 * enhancedChannels(:, :, 2) + 0.3 * claheGreen;
    else
        enhancedChannels = claheGreen;
    end

    % 3. Edge-Preserving Bilateral Filter to suppress noise in low-cost sensors
    if exist('imbilatfilt', 'file')
        for c = 1:C
            enhancedChannels(:, :, c) = imbilatfilt(enhancedChannels(:, :, c), 0.04, 3);
        end
    else
        % Fallback: gentle median smoothing
        for c = 1:C
            enhancedChannels(:, :, c) = medfilt2(enhancedChannels(:, :, c), [3 3]);
        end
    end

    % Mask boundary clean
    for c = 1:C
        enhancedChannels(~repmat(retinalMask, [1 1 C])) = 0;
    end

    enhancedImg = max(0, min(1, enhancedChannels));
    greenEnhanced = claheGreen;
end
