function [featureVec, featureNames, featureStruct] = extractHybridFeatures(img, segResults)
% EXTRACTHYBRIDFEATURES Extracts clinical biomarker measurements and image features.
%   Fuses structural lesion quantification with deep statistical textures for ICDR grading.
%
% Syntax:
%   [featureVec, featureNames, featureStruct] = extractHybridFeatures(img, segResults)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    % 1. Biomarker counts and areas from segmentation
    maCount = segResults.maDetails.count;
    hmCount = segResults.hmDetails.count;
    hmArea = segResults.hmDetails.totalArea;
    heArea = segResults.heDetails.totalArea;
    vesselDensity = segResults.vesselDensity;
    nvDetected = double(segResults.nvDetails.nvDetected);
    nvArea = segResults.nvDetails.totalNVArea;

    % Quadrant distribution for Hemorrhages (4-2-1 Rule metrics)
    qCounts = [segResults.hmDetails.quadrantCounts.Q1_SuperiorTemporal, ...
               segResults.hmDetails.quadrantCounts.Q2_SuperiorNasal, ...
               segResults.hmDetails.quadrantCounts.Q3_InferiorNasal, ...
               segResults.hmDetails.quadrantCounts.Q4_InferiorTemporal];
    
    quadsWithHMs = sum(qCounts > 0);
    quadsWithSevereHMs = sum(qCounts >= 5); % severe threshold per quadrant

    % Distance of Hard Exudates to Fovea Center (DME risk marker)
    foveaCenter = segResults.foveaCenter;
    if segResults.heDetails.count > 0 && ~isempty(segResults.heDetails.centroids)
        distsToFovea = sqrt((segResults.heDetails.centroids(:, 1) - foveaCenter(1)).^2 + ...
                            (segResults.heDetails.centroids(:, 2) - foveaCenter(2)).^2);
        minHEDistanceToFovea = min(distsToFovea);
    else
        minHEDistanceToFovea = 9999.0;
    end

    % Optic disc diameter in pixels
    odDiameter = 2 * segResults.odRadius;
    dmeRiskRatio = minHEDistanceToFovea / max(1, odDiameter);

    % 2. Image Global Intensity & Texture Statistics (Deep proxy features)
    greenChan = imgD(:, :, 2);
    retinalMask = segResults.retinalMask;
    validPixels = greenChan(retinalMask);

    if ~isempty(validPixels)
        meanG = mean(validPixels);
        stdG = std(validPixels);
        skewG = skewness(validPixels);
        kurtG = kurtosis(validPixels);
        entropyG = entropy(validPixels);
    else
        meanG = 0; stdG = 0; skewG = 0; kurtG = 0; entropyG = 0;
    end

    % Assemble structured features
    featureStruct = struct();
    featureStruct.maCount = maCount;
    featureStruct.hmCount = hmCount;
    featureStruct.hmArea = hmArea;
    featureStruct.heArea = heArea;
    featureStruct.vesselDensity = vesselDensity;
    featureStruct.nvDetected = nvDetected;
    featureStruct.nvArea = nvArea;
    featureStruct.quadsWithHMs = quadsWithHMs;
    featureStruct.quadsWithSevereHMs = quadsWithSevereHMs;
    featureStruct.dmeRiskRatio = dmeRiskRatio;
    featureStruct.meanG = meanG;
    featureStruct.stdG = stdG;
    featureStruct.skewG = skewG;
    featureStruct.kurtG = kurtG;
    featureStruct.entropyG = entropyG;

    featureNames = { ...
        'maCount', 'hmCount', 'hmArea', 'heArea', 'vesselDensity', ...
        'nvDetected', 'nvArea', 'quadsWithHMs', 'quadsWithSevereHMs', ...
        'dmeRiskRatio', 'meanG', 'stdG', 'skewG', 'kurtG', 'entropyG' ...
    };

    featureVec = [ ...
        maCount, hmCount, hmArea, heArea, vesselDensity, ...
        nvDetected, nvArea, quadsWithHMs, quadsWithSevereHMs, ...
        dmeRiskRatio, meanG, stdG, skewG, kurtG, entropyG ...
    ];
end

function s = skewness(x)
    % Fallback skewness if Stats toolbox is not active
    m = mean(x);
    s = mean((x - m).^3) / (mean((x - m).^2)^1.5 + 1e-8);
end

function k = kurtosis(x)
    % Fallback kurtosis if Stats toolbox is not active
    m = mean(x);
    k = mean((x - m).^4) / (mean((x - m).^2)^2 + 1e-8);
end
