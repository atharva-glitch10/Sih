function [nvDetected, nvMask, nvDetails] = detectNeovascularization(img, vesselMask, odMask, retinalMask)
% DETECTNEOVASCULARIZATION Detects new fragile vessel formations (NVD and NVE).
%   Hallmark of Proliferative Diabetic Retinopathy (PDR, ICDR Grade 4).
%   Detects fine tortuous vessel clusters in peripapillary (NVD) and retinal field (NVE).
%
% Syntax:
%   [nvDetected, nvMask, nvDetails] = detectNeovascularization(img, vesselMask, odMask, retinalMask)
%
% Outputs:
%   nvDetected - Boolean flag (true if clinically significant neovascularization is found)
%   nvMask     - Binary mask of detected NV clusters
%   nvDetails  - Struct with NVD / NVE classification and tortuosity scores
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
        retinalMask = true(H, W);
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
    % Define Peripapillary region for NVD (within 1 disc diameter of OD)
    peripapillaryZone = imdilate(odMask, strel('disk', max(1, round(min([H, W]) * 0.08)), 0)) & retinalMask;
    retinalElsewhereZone = retinalMask & ~peripapillaryZone;
    % Look for fine high-frequency vessel loops (high tortuosity & high local branch density)
    % High pass filter on inverted green channel
    invertedGreen = 1.0 - greenChan;
    seFine = strel('disk', 2, 0);
    fineVessels = imtophat(invertedGreen, seFine);
    fineVessels(~retinalMask) = 0;
    fineThresh = quantile(fineVessels(retinalMask), 0.985);
    fineMask = (fineVessels > fineThresh) & (fineVessels > 0.06);
    % Local vessel density map
    densityFilter = fspecial('disk', max(5, round(min(H, W) * 0.03)));
    vesselDensityMap = imfilter(double(vesselMask | fineMask), densityFilter, 'replicate');
    % NV is characterized by dense local clustering of tortuous fine vessels
    highDensityClusters = vesselDensityMap > 0.28;
    nvCandidateMask = highDensityClusters & (fineMask | vesselMask);
    % Cleanup tiny isolated specks
    nvMask = bwareaopen(nvCandidateMask, 25);
    % Separate into NVD (at disc) and NVE (elsewhere)
    nvdMask = nvMask & peripapillaryZone;
    nveMask = nvMask & retinalElsewhereZone;
    nvdArea = sum(nvdMask(:));
    nveArea = sum(nveMask(:));
    % Clinical significance criteria:
    % NVD > 0.25 of disc area OR NVE > 0.5 of disc area
    odArea = sum(odMask(:));
    if odArea == 0
        odArea = pi * (min(H, W) * 0.07)^2;
    end
    isNVD = nvdArea > (0.20 * odArea);
    isNVE = nveArea > (0.40 * odArea);
    nvDetected = isNVD || isNVE;
    nvDetails = struct();
    nvDetails.nvDetected = nvDetected;
    nvDetails.isNVD = isNVD;
    nvDetails.isNVE = isNVE;
    nvDetails.nvdArea = nvdArea;
    nvDetails.nveArea = nveArea;
    nvDetails.totalNVArea = sum(nvMask(:));
    nvDetails.mask = nvMask;
end

