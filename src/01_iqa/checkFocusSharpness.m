function [sharpnessScore, isSharp, details] = checkFocusSharpness(img, threshold)
% CHECKFOCUSSHARPNESS Evaluates retinal fundus image focus and sharpness.
%   Uses Tenengrad gradient metric and Laplacian variance on the green channel.
%
% Syntax:
%   [sharpnessScore, isSharp, details] = checkFocusSharpness(img)
%   [sharpnessScore, isSharp, details] = checkFocusSharpness(img, threshold)
%
% Inputs:
%   img       - RGB fundus image (uint8 or double)
%   threshold - (Optional) Minimum sharpness score threshold (default: 15.0)
%
% Outputs:
%   sharpnessScore - Normalized sharpness score [0 - 100]
%   isSharp        - Boolean flag (true if sharpnessScore >= threshold)
%   details        - Struct containing Laplacian variance and Tenengrad metrics
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 2 || isempty(threshold)
        threshold = 15.0;
    end

    % Convert to double in [0, 1]
    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    % Extract green channel (highest contrast for retinal vessels)
    if size(imgD, 3) == 3
        greenChannel = imgD(:, :, 2);
    else
        greenChannel = imgD;
    end

    % Compute Laplacian variance
    lapFilter = [0 1 0; 1 -4 1; 0 1 0];
    laplacianResp = imfilter(greenChannel, lapFilter, 'replicate', 'conv');
    lapVariance = var(laplacianResp(:)) * 1e4;

    % Compute Tenengrad gradient magnitude metric (Sobel)
    [Gx, Gy] = imgradientxy(greenChannel, 'sobel');
    gradMagSq = Gx.^2 + Gy.^2;
    tenengradScore = mean(gradMagSq(:)) * 1e3;

    % Retinal mask to exclude dark background border
    retinalMask = greenChannel > 0.05;
    if any(retinalMask(:))
        tenengradRetina = mean(gradMagSq(retinalMask)) * 1e3;
    else
        tenengradRetina = tenengradScore;
    end

    % Composite sharpness score normalized to [0, 100]
    rawScore = 0.5 * lapVariance + 0.5 * tenengradRetina;
    sharpnessScore = min(100, max(0, rawScore * 2.5));

    isSharp = sharpnessScore >= threshold;

    details = struct();
    details.laplacianVariance = lapVariance;
    details.tenengradScore = tenengradScore;
    details.tenengradRetina = tenengradRetina;
    details.normalizedScore = sharpnessScore;
    details.threshold = threshold;
    details.isSharp = isSharp;
end
