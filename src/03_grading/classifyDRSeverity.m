function [grade, gradeLabel, confidence, isReferable, probs, explanation, details] = classifyDRSeverity(img, segResults, model)
% CLASSIFYDRSEVERITY Unified hybrid AI and clinical rule-based DR grading engine.
%   Fuses structural lesion segmentations, clinical ETDRS 4-2-1 rules, and machine
%   learning probabilities into an ICDR Grade 0-4 and Referable DR decision.
%
% Syntax:
%   [grade, gradeLabel, confidence, isReferable, probs, explanation, details] = classifyDRSeverity(img, segResults)
%   [grade, gradeLabel, confidence, isReferable, probs, explanation, details] = classifyDRSeverity(img, segResults, model)
%
% Outputs:
%   grade       - Predicted ICDR Grade [0: No DR, 1: Mild, 2: Moderate, 3: Severe, 4: Proliferative]
%   gradeLabel  - Clinical text description of the grade
%   confidence  - Confidence score [0.0 - 1.0]
%   isReferable - Boolean flag (true if patient requires urgent ophthalmologist referral)
%   probs       - 5-element array of calibrated probabilities for [G0, G1, G2, G3, G4]
%   explanation - Multi-line clinical justification for decision
%   details     - Struct containing features and intermediate rule scores
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 3 || isempty(model)
        model = trainDRClassifier();
    end

    % 1. Extract quantitative hybrid biomarker features
    [featureVec, featureNames, featureStruct] = extractHybridFeatures(img, segResults);

    % 2. Evaluate Clinical 4-2-1 Gold-Standard Rules
    [ruleGrade, ruleConf, ruleExplanation, ruleReferable] = apply421ClinicalRules(featureStruct, segResults);

    % 3. Evaluate Statistical / Machine Learning Classifier Scores
    % Compute weighted Euclidean distance to ICDR prototype centroids
    diffs = (model.prototypes - featureVec) .* model.weights;
    sqDistances = sum(diffs.^2, 2);
    
    % Invert distances to raw similarity logits
    rawLogits = -sqDistances / (mean(sqDistances) + 1e-4);

    % 4. Calibrate probabilities via Temperature Scaling
    [calibratedProbs, refThreshold] = calibrateProbabilities(rawLogits, 1.4);

    % If MATLAB Ensemble model was pre-trained, blend predictions
    if isfield(model, 'hasTrainedEnsemble') && model.hasTrainedEnsemble
        try
            [~, ensembleProbs] = predict(model.matlabEnsemble, featureVec);
            calibratedProbs = 0.4 * calibratedProbs + 0.6 * ensembleProbs(:)';
        catch
            % continue with calibratedProbs
        end
    end

    % Boost probability of rule-matched class to respect clinical safety constraints
    ruleBias = zeros(1, 5);
    ruleBias(ruleGrade + 1) = 0.5;
    fusedProbs = calibratedProbs + ruleBias;
    fusedProbs = fusedProbs / sum(fusedProbs);

    % 5. Final Grade Selection & Clinical Safety Assurance
    % If a high-grade rule is triggered (e.g. NV present or 4-quadrant HMs), never downgrade
    [maxProb, modelGradeIdx] = max(fusedProbs);
    modelGrade = modelGradeIdx - 1;

    finalGrade = max(ruleGrade, modelGrade);
    confidence = max(ruleConf, fusedProbs(finalGrade + 1));

    % 6. Referable DR Determination (Grade >= 2 OR DME present)
    probReferable = sum(fusedProbs(3:5));
    isReferable = (finalGrade >= 2) || (probReferable >= refThreshold) || ruleReferable;

    gradeLabel = model.classNames{finalGrade + 1};

    % 7. Generate Clinical Explainability Text
    lines = {};
    lines{end+1} = sprintf('Diagnostic Assessment: %s (Confidence: %.1f%%)', gradeLabel, confidence * 100);
    if isReferable
        lines{end+1} = 'Triage Recommendation: [URGENT REFERRAL] Refer to District Hospital / Tele-Ophthalmologist.';
    else
        lines{end+1} = 'Triage Recommendation: [ROUTINE SCREENING] Re-screen at PHC in 12 months.';
    end
    lines{end+1} = sprintf('Clinical Rule Rationale: %s', ruleExplanation);
    lines{end+1} = sprintf('Key Biomarkers: MAs=%d, HMs=%d (in %d quads), Hard Exudates=%d px, NV=%d', ...
        featureStruct.maCount, featureStruct.hmCount, featureStruct.quadsWithHMs, ...
        round(featureStruct.heArea), featureStruct.nvDetected);
    
    explanation = strjoin(lines, newline);

    details = struct();
    details.features = featureStruct;
    details.featureVector = featureVec;
    details.featureNames = featureNames;
    details.ruleGrade = ruleGrade;
    details.ruleConfidence = ruleConf;
    details.ruleExplanation = ruleExplanation;
    details.calibratedProbs = fusedProbs;
    details.probReferable = probReferable;
    details.referableThreshold = refThreshold;
end
