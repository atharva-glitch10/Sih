function metrics = evaluateSegmentationMetrics(groundTruthMask, predictedMask)
% EVALUATESEGMENTATIONMETRICS Computes Dice, IoU (Jaccard), Sensitivity, and Specificity.
%
% Syntax:
%   metrics = evaluateSegmentationMetrics(groundTruthMask, predictedMask)
%
% Outputs:
%   metrics.diceCoefficient - Dice similarity coefficient [0 - 1]
%   metrics.jaccardIoU      - Intersection over Union [0 - 1]
%   metrics.sensitivity     - True positive rate
%   metrics.specificity     - True negative rate
%   metrics.pixelAccuracy   - Overall binary pixel accuracy
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    gt = logical(groundTruthMask);
    pred = logical(predictedMask);

    intersection = sum(gt(:) & pred(:));
    union = sum(gt(:) | pred(:));
    gtSum = sum(gt(:));
    predSum = sum(pred(:));

    % Dice coefficient: 2 * |A n B| / (|A| + |B|)
    if (gtSum + predSum) > 0
        dice = (2 * intersection) / (gtSum + predSum);
    else
        dice = 1.0; % Both masks empty
    end

    % Jaccard IoU: |A n B| / |A u B|
    if union > 0
        iou = intersection / union;
    else
        iou = 1.0;
    end

    % Pixel-level Confusion Matrix
    TP = intersection;
    FP = sum(~gt(:) & pred(:));
    FN = sum(gt(:) & ~pred(:));
    TN = sum(~gt(:) & ~pred(:));

    if (TP + FN) > 0
        sens = TP / (TP + FN);
    else
        sens = 1.0;
    end

    if (TN + FP) > 0
        spec = TN / (TN + FP);
    else
        spec = 1.0;
    end

    acc = (TP + TN) / numel(gt);

    metrics = struct();
    metrics.diceCoefficient = dice;
    metrics.jaccardIoU = iou;
    metrics.sensitivity = sens;
    metrics.specificity = spec;
    metrics.pixelAccuracy = acc;
end
