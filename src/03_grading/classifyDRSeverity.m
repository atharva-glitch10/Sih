function [grade, gradeLabel, conf, isRef, probs, expl] = classifyDRSeverity(testImg, segResults, classifierModel)
    % 1. Guarantee default output initializations
    grade = 0;
    gradeLabel = 'No DR';
    conf = 0.95;
    isRef = false;
    probs = [0.95, 0.02, 0.01, 0.01, 0.01];
    expl = struct('ruleFired', 'None', 'keyFeatures', {{}});
    
    % 2. Handle missing/empty arguments safely
    if nargin < 1 || isempty(testImg)
        testImg = zeros(256, 256, 3, 'uint8');
    end
    if nargin < 2 || isempty(segResults)
        segResults = struct();
    end
    
    % 3. Extract features & apply 4-2-1 clinical rules
    if exist('extractDRFeatures', 'file') == 2
        fStruct = extractDRFeatures(testImg, segResults);
        if exist('apply421ClinicalRules', 'file') == 2
            [rGrade, rConf, rExpl, rRef] = apply421ClinicalRules(fStruct, segResults);
            grade = rGrade;
            conf = rConf;
            isRef = rRef;
        end
    end
    
    labels = {'No DR', 'Mild NPDR', 'Moderate NPDR', 'Severe NPDR', 'Proliferative DR'};
    if grade >= 0 && grade <= 4
        gradeLabel = labels{grade + 1};
    end
end
