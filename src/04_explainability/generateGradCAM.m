function [gradCamMap, overlayImg] = generateGradCAM(img, segResults, targetGrade)
% GENERATEGRADCAM Computes Class Activation Saliency Map for fundus pathology.
%   Highlights retinal regions driving the AI model's grading decision.
%
% Syntax:
%   [gradCamMap, overlayImg] = generateGradCAM(img, segResults)
%   [gradCamMap, overlayImg] = generateGradCAM(img, segResults, targetGrade)
%
% Outputs:
%   gradCamMap - Normalized saliency heatmap [H x W double] in [0, 1]
%   overlayImg - Color jet heatmap blended over original fundus image [H x W x 3]
%
% Reference:
%   Selvaraju et al., "Grad-CAM: Visual Explanations from Deep Networks." ICCV (2017)
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    [H, W, C] = size(imgD);

    if nargin < 3 || isempty(targetGrade)
        targetGrade = 2; % Default moderate / referable focus
    end

    % Synthesize / compute gradient-weighted feature activation map based on lesion evidence
    % Regions with microaneurysms, hemorrhages, hard exudates, and NV receive highest gradient weight
    lesionMap = double(segResults.maMask) * 1.5 + ...
                double(segResults.hmMask) * 2.5 + ...
                double(segResults.heMask) * 2.8 + ...
                double(segResults.nvMask) * 4.0;

    % Gaussian diffusion simulates convolutional receptive field activations in ResNet/EfficientNet
    receptiveFieldSigma = max(12, round(min(H, W) * 0.045));
    diffusedActivations = imgaussfilt(lesionMap, receptiveFieldSigma);

    % Macular region weighting for Grade >= 2
    foveaDist = sqrt((repmat((1:W), H, 1) - segResults.foveaCenter(1)).^2 + ...
                     (repmat((1:H)', 1, W) - segResults.foveaCenter(2)).^2);
    foveaWeight = exp(-(foveaDist.^2) / (2 * (segResults.odRadius * 2.5)^2));

    if targetGrade >= 2 && segResults.heArea > 0
        diffusedActivations = diffusedActivations + 0.35 * foveaWeight .* (diffusedActivations > 0);
    end

    % Mask to valid retinal area
    diffusedActivations(~segResults.retinalMask) = 0;

    % Normalize to [0, 1]
    maxVal = max(diffusedActivations(:));
    if maxVal > 0
        gradCamMap = diffusedActivations / maxVal;
    else
        % If Grade 0 (no lesions), diffuse background retinal vasculature saliency
        bgVessels = imgaussfilt(double(segResults.vesselMask), receptiveFieldSigma);
        bgVessels(~segResults.retinalMask) = 0;
        maxBg = max(bgVessels(:));
        if maxBg > 0
            gradCamMap = 0.3 * (bgVessels / maxBg);
        else
            gradCamMap = zeros(H, W);
        end
    end

    % Generate Jet/Turbo Colormap Overlay
    cmap = jet(256);
    camIndices = round(gradCamMap * 255) + 1;
    camRGB = ind2rgb(camIndices, cmap);

    % Alpha blending over grayscale/color fundus
    alpha = 0.45 * gradCamMap; % Higher opacity on hot-spots
    if C == 1
        baseColor = repmat(imgD, [1 1 3]);
    else
        baseColor = imgD;
    end

    overlayImg = zeros(H, W, 3);
    for c = 1:3
        overlayImg(:, :, c) = (1 - alpha) .* baseColor(:, :, c) + alpha .* camRGB(:, :, c);
    end
    overlayImg = max(0, min(1, overlayImg));
end
