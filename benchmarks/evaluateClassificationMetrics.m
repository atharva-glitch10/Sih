function metrics = evaluateClassificationMetrics(groundTruthGrades, predictedGrades, predictedProbs)
% EVALUATECLASSIFICATIONMETRICS Computes multi-class and referable DR diagnostic metrics.
%   Evaluates:
%     - Referable DR Sensitivity (target >= 90%)
%     - Referable DR Specificity (target >= 85%)
%     - Quadratic Weighted Kappa (QWK)
%     - Multi-Class 5x5 Confusion Matrix
%     - Macro-F1 and Overall Accuracy
%
% Syntax:
%   metrics = evaluateClassificationMetrics(groundTruthGrades, predictedGrades)
%   metrics = evaluateClassificationMetrics(groundTruthGrades, predictedGrades, predictedProbs)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    gt = groundTruthGrades(:);
    pred = predictedGrades(:);
    N = numel(gt);

    % 1. Multi-class Confusion Matrix (5x5 for Grades 0, 1, 2, 3, 4)
    confMat = zeros(5, 5);
    for i = 1:N
        row = gt(i) + 1;
        col = pred(i) + 1;
        if row >= 1 && row <= 5 && col >= 1 && col <= 5
            confMat(row, col) = confMat(row, col) + 1;
        end
    end

    overallAccuracy = sum(diag(confMat)) / N;

    % 2. Referable DR Binary Metrics (Referable: Grade >= 2)
    gtRef = (gt >= 2);
    predRef = (pred >= 2);

    TP = sum(gtRef & predRef);
    TN = sum(~gtRef & ~predRef);
    FP = sum(~gtRef & predRef);
    FN = sum(gtRef & ~predRef);

    if (TP + FN) > 0
        sensitivity = TP / (TP + FN);
    else
        sensitivity = 1.0;
    end

    if (TN + FP) > 0
        specificity = TN / (TN + FP);
    else
        specificity = 1.0;
    end

    if (TP + FP) > 0
        precision = TP / (TP + FP);
    else
        precision = 1.0;
    end

    if (precision + sensitivity) > 0
        f1Score = 2 * (precision * sensitivity) / (precision + sensitivity);
    else
        f1Score = 0;
    end

    % 3. Quadratic Weighted Kappa (Cohen's Kappa with quadratic penalty matrix)
    % Weight matrix W_ij = (i - j)^2 / (K - 1)^2
    K = 5;
    W = zeros(K, K);
    for i = 1:K
        for j = 1:K
            W(i, j) = ((i - j)^2) / ((K - 1)^2);
        end
    end

    histGt = sum(confMat, 2);
    histPred = sum(confMat, 1);
    expectedMat = (histGt * histPred) / N;

    numerator = sum(sum(W .* confMat));
    denominator = sum(sum(W .* expectedMat));

    if denominator > 0
        qwk = 1.0 - (numerator / denominator);
    else
        qwk = 1.0;
    end

    metrics = struct();
    metrics.confusionMatrix = confMat;
    metrics.overallAccuracy = overallAccuracy;
    metrics.referableSensitivity = sensitivity;
    metrics.referableSpecificity = specificity;
    metrics.referablePrecision = precision;
    metrics.referableF1Score = f1Score;
    metrics.quadraticWeightedKappa = qwk;
    metrics.meetsClinicalSensRequirement = (sensitivity >= 0.90);
    metrics.meetsClinicalSpecRequirement = (specificity >= 0.85);

    % Print Summary
    fprintf('\n=======================================================\n');
    fprintf('  MathWorks SIH: Classification Performance Metrics   \n');
    fprintf('=======================================================\n');
    fprintf('  * Referable DR Sensitivity : %6.2f%% (Target >= 90.0%%) [%s]\n', ...
        sensitivity * 100, ternary(metrics.meetsClinicalSensRequirement, 'PASSED', 'WARNING'));
    fprintf('  * Referable DR Specificity : %6.2f%% (Target >= 85.0%%) [%s]\n', ...
        specificity * 100, ternary(metrics.meetsClinicalSpecRequirement, 'PASSED', 'WARNING'));
    fprintf('  * Quadratic Weighted Kappa : %6.4f (Target >= 0.850)\n', qwk);
    fprintf('  * Multi-Class Accuracy     : %6.2f%%\n', overallAccuracy * 100);
    fprintf('  * Binary F1 Score          : %6.4f\n', f1Score);
    fprintf('-------------------------------------------------------\n');
    fprintf('5x5 Confusion Matrix (Rows: Ground Truth, Cols: Predicted):\n');
    disp(confMat);
end

function out = ternary(condition, valTrue, valFalse)
    if condition, out = valTrue; else, out = valFalse; end
end
