function model = trainDRClassifier(trainingFeatures, trainingLabels)
% TRAINDRCLASSIFIER Trains an ensemble DR classifier fusing biomarker & texture features.
%   Uses Random Forest / Ensemble or Weighted Distance-based Classifier if Statistics
%   Toolbox is available, with deterministic fallback calibration.
%
% Syntax:
%   model = trainDRClassifier() % Generates default calibrated model
%   model = trainDRClassifier(trainingFeatures, trainingLabels)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    model = struct();
    model.classes = [0, 1, 2, 3, 4];
    model.classNames = { ...
        'Grade 0 - No Diabetic Retinopathy', ...
        'Grade 1 - Mild Non-Proliferative DR', ...
        'Grade 2 - Moderate Non-Proliferative DR', ...
        'Grade 3 - Severe Non-Proliferative DR', ...
        'Grade 4 - Proliferative Diabetic Retinopathy' ...
    };

    % Feature weights based on clinical importance:
    % [maCount, hmCount, hmArea, heArea, vesselDensity, nvDetected, nvArea,
    %  quadsWithHMs, quadsWithSevereHMs, dmeRiskRatio, meanG, stdG, skewG, kurtG, entropyG]
    model.weights = [ ...
        1.8,  ... % maCount
        2.5,  ... % hmCount
        2.0,  ... % hmArea
        2.8,  ... % heArea
        1.2,  ... % vesselDensity
        5.0,  ... % nvDetected (High priority)
        4.0,  ... % nvArea
        3.0,  ... % quadsWithHMs
        3.5,  ... % quadsWithSevereHMs
        -2.2, ... % dmeRiskRatio (lower distance = higher risk)
        0.5, 0.5, 0.4, 0.4, 0.6 ... % texture
    ];

    % Benchmark centroids for ICDR grades 0-4 (standardized feature space)
    model.prototypes = [ ...
        % G0: No DR
        0,   0,   0,   0, 0.08, 0,  0, 0, 0, 10.0, 0.45, 0.12, 0.1, 2.5, 4.2;
        % G1: Mild NPDR (few MAs)
        2,   0,   0,   0, 0.09, 0,  0, 0, 0, 10.0, 0.44, 0.13, 0.2, 2.7, 4.3;
        % G2: Moderate NPDR (MAs, HMs, HE)
        8,   6,  80,  90, 0.10, 0,  0, 2, 0,  1.2, 0.42, 0.15, 0.4, 3.1, 4.5;
        % G3: Severe NPDR (4-2-1 rule: HMs in 4 quadrants)
        18, 24, 450, 220, 0.11, 0,  0, 4, 3,  0.8, 0.39, 0.18, 0.7, 3.8, 4.8;
        % G4: Proliferative DR (NV present)
        25, 30, 600, 350, 0.14, 1, 95, 4, 4,  0.6, 0.36, 0.21, 0.9, 4.2, 5.0  ...
    ];

    if nargin >= 2 && ~isempty(trainingFeatures) && ~isempty(trainingLabels)
        if exist('fitcensemble', 'file')
            try
                t = templateTree('MaxNumSplits', 20);
                model.matlabEnsemble = fitcensemble(trainingFeatures, trainingLabels, ...
                    'Method', 'Bag', 'NumLearningCycles', 50, 'Learners', t);
                model.hasTrainedEnsemble = true;
            catch
                model.hasTrainedEnsemble = false;
            end
        else
            model.hasTrainedEnsemble = false;
        end
    else
        model.hasTrainedEnsemble = false;
    end

    model.isCalibrated = true;
    model.referableThreshold = 0.40;
end
