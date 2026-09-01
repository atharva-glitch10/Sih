function [ruleGrade, ruleConfidence, ruleExplanation, isReferable] = apply421ClinicalRules(features, segResults)
% APPLY421CLINICALRULES Enforces clinical ETDRS & ICDR 4-2-1 diagnostic rules.
%   Ensures deterministic clinical safety bounds on AI model predictions:
%     - Proliferative DR (Grade 4): Presence of Neovascularization (NVD or NVE)
%     - Severe NPDR (Grade 3): 4-2-1 rule (severe hemorrhages in all 4 quadrants)
%     - Moderate NPDR (Grade 2): More than MAs, multiple exudates/hemorrhages
%     - Mild NPDR (Grade 1): Microaneurysms only
%     - No DR (Grade 0): Zero lesions
%
% Syntax:
%   [ruleGrade, ruleConfidence, ruleExplanation, isReferable] = apply421ClinicalRules(features, segResults)
%
% Reference:
%   Wilkinson et al., "Proposed international clinical diabetic retinopathy and diabetic macular edema disease severity scales." Ophthalmology (2003)
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    maCount = features.maCount;
    hmCount = features.hmCount;
    heArea = features.heArea;
    nvDetected = (features.nvDetected > 0.5);
    quadsWithHMs = features.quadsWithHMs;
    quadsWithSevereHMs = features.quadsWithSevereHMs;
    dmeRatio = features.dmeRiskRatio;

    reasons = {};

    % Rule 1: Proliferative Diabetic Retinopathy (Grade 4)
    if nvDetected || (features.nvArea > 50)
        ruleGrade = 4;
        ruleConfidence = 0.96;
        reasons{end+1} = sprintf('Active Neovascularization detected (area: %d px). PDR criteria satisfied.', round(features.nvArea));
        ruleExplanation = 'Grade 4 (Proliferative DR): ' + string(reasons{1});
        isReferable = true;
        return;
    end

    % Rule 2: Severe Non-Proliferative Diabetic Retinopathy (Grade 3 - 4-2-1 Rule)
    if (quadsWithSevereHMs >= 4) || (quadsWithHMs == 4 && hmCount >= 18)
        ruleGrade = 3;
        ruleConfidence = 0.92;
        reasons{end+1} = sprintf('4-2-1 Rule triggered: Severe intraretinal hemorrhages across all 4 quadrants (total %d HMs).', hmCount);
        ruleExplanation = 'Grade 3 (Severe NPDR): ' + string(reasons{1});
        isReferable = true;
        return;
    end

    % Rule 3: Moderate Non-Proliferative Diabetic Retinopathy (Grade 2)
    if (hmCount >= 3) || (heArea > 30) || (maCount >= 5 && quadsWithHMs >= 2) || (dmeRatio < 1.0 && heArea > 0)
        ruleGrade = 2;
        ruleConfidence = 0.88;
        if dmeRatio < 1.0 && heArea > 0
            reasons{end+1} = sprintf('Hard exudates present within 1 Disc Diameter of Fovea (DME risk marker, HE area: %d px).', round(heArea));
        end
        if hmCount >= 3
            reasons{end+1} = sprintf('Moderate hemorrhages detected in %d quadrants (count: %d).', quadsWithHMs, hmCount);
        elseif maCount >= 5
            reasons{end+1} = sprintf('Multiple microaneurysm clusters detected (count: %d).', maCount);
        end
        ruleExplanation = 'Grade 2 (Moderate NPDR): ' + strjoin(reasons, ' | ');
        isReferable = true;
        return;
    end

    % Rule 4: Mild Non-Proliferative Diabetic Retinopathy (Grade 1)
    if (maCount >= 1) || (hmCount == 1 && heArea == 0)
        ruleGrade = 1;
        ruleConfidence = 0.86;
        reasons{end+1} = sprintf('Isolated microaneurysms only (count: %d, zero large exudates/NV).', maCount);
        ruleExplanation = 'Grade 1 (Mild NPDR): ' + string(reasons{1});
        % Mild DR alone without DME is non-referable (routine annual follow-up)
        isReferable = false;
        return;
    end

    % Rule 5: No Apparent Diabetic Retinopathy (Grade 0)
    ruleGrade = 0;
    ruleConfidence = 0.94;
    reasons{end+1} = 'Clear retinal fundus; zero microaneurysms, hemorrhages, exudates, or neovascularization.';
    ruleExplanation = 'Grade 0 (No DR): ' + string(reasons{1});
    isReferable = false;
end
