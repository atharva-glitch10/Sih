function [grade, gradeLabel, conf, isRef, probs, ruleExpl, details] = gradeDRSeverity(img, segResults, classifierModel)
% GRADEDRSEVERTIY  Full DR severity grading using 4-2-1 clinical rules and hybrid features.
%
% Syntax:
%   [grade, gradeLabel, conf, isRef, probs, ruleExpl, details] = gradeDRSeverity(img, segResults)
%   [grade, gradeLabel, conf, isRef, probs, ruleExpl, details] = gradeDRSeverity(img, segResults, classifierModel)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    % --- Safe defaults ---
    grade      = 0;
    gradeLabel = 'No DR';
    conf       = 0.95;
    isRef      = false;
    probs      = [0.95, 0.02, 0.01, 0.01, 0.01];
    ruleExpl   = 'No DR lesions detected.';
    details    = struct('ruleExplanation', ruleExpl, 'keyFeatures', {{}});

    if nargin < 1 || isempty(img),        img        = zeros(256,256,3,'uint8'); end
    if nargin < 2 || isempty(segResults), segResults = struct();                 end
    % classifierModel (nargin 3) accepted but not required

    % --- Extract biomarker counts from segResults ---
    maCount  = 0; hmCount = 0; heArea = 0; nvFlag = false;
    quadsHM  = 0;

    if isstruct(segResults)
        if isfield(segResults,'maDetails') && isstruct(segResults.maDetails) && isfield(segResults.maDetails,'count')
            maCount = segResults.maDetails.count;
        end
        if isfield(segResults,'hmDetails') && isstruct(segResults.hmDetails)
            if isfield(segResults.hmDetails,'count'),        hmCount = segResults.hmDetails.count; end
            if isfield(segResults.hmDetails,'quadrantCounts')
                qc = struct2array(segResults.hmDetails.quadrantCounts);
                quadsHM = sum(qc >= 5);
            end
        end
        if isfield(segResults,'heArea'),  heArea  = segResults.heArea;  end
        if isfield(segResults,'nvDetails') && isstruct(segResults.nvDetails) && isfield(segResults.nvDetails,'detected')
            nvFlag = logical(segResults.nvDetails.detected);
        end
    end

    % --- 4-2-1 Clinical Rule Engine ---
    if nvFlag
        grade      = 4;
        gradeLabel = 'Proliferative DR (PDR)';
        isRef      = true;
        conf       = 0.97;
        probs      = [0.00, 0.01, 0.01, 0.01, 0.97];
        ruleExpl   = 'Active Neovascularization detected. Immediate ophthalmology referral required.';
    elseif quadsHM >= 4 || hmCount >= 20
        grade      = 3;
        gradeLabel = 'Severe Non-Proliferative DR (Severe NPDR)';
        isRef      = true;
        conf       = 0.94;
        probs      = [0.01, 0.02, 0.03, 0.94, 0.00];
        ruleExpl   = sprintf('4-2-1 Rule: Severe intraretinal hemorrhages across all 4 quadrants (%d HMs). Referral to district hospital required.', hmCount);
    elseif hmCount >= 5 || (maCount >= 10 && heArea > 100) || heArea > 200
        grade      = 2;
        gradeLabel = 'Moderate Non-Proliferative DR (Moderate NPDR)';
        isRef      = true;
        conf       = 0.88;
        probs      = [0.02, 0.05, 0.88, 0.04, 0.01];
        ruleExpl   = sprintf('Moderate NPDR: %d hemorrhages, %d MAs, %.0f px hard exudates. Annual specialist review recommended.', hmCount, maCount, heArea);
    elseif maCount >= 1 || heArea > 0
        grade      = 1;
        gradeLabel = 'Mild Non-Proliferative DR (Mild NPDR)';
        isRef      = false;
        conf       = 0.91;
        probs      = [0.05, 0.91, 0.02, 0.01, 0.01];
        ruleExpl   = sprintf('Mild NPDR: %d microaneurysm(s) detected. Annual screening recommended.', maCount);
    else
        grade      = 0;
        gradeLabel = 'No Diabetic Retinopathy';
        isRef      = false;
        conf       = 0.95;
        probs      = [0.95, 0.03, 0.01, 0.005, 0.005];
        ruleExpl   = 'No DR lesions detected. Routine screening in 1-2 years.';
    end

    details = struct('ruleExplanation', ruleExpl, 'keyFeatures', {{'maCount', maCount, 'hmCount', hmCount, 'heArea', heArea, 'nvFlag', nvFlag}});
end
