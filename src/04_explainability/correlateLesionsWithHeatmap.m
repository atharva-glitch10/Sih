function correlation = correlateLesionsWithHeatmap(gradCamMap, segResults)
% CORRELATELESIONSWITHHEATMAP Validates that GradCAM saliency aligns with true lesions.
%   Quantifies how much of the AI's visual attention coincides with clinically
%   segmented microaneurysms, hard exudates, hemorrhages, and neovascularization.
%
% Syntax:
%   correlation = correlateLesionsWithHeatmap(gradCamMap, segResults)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    saliencyThreshold = 0.40;
    salientZone = gradCamMap >= saliencyThreshold;

    % Union of all detected pathology
    allLesionsMask = segResults.maMask | segResults.hmMask | segResults.heMask | segResults.nvMask;
    totalLesionPixels = sum(allLesionsMask(:));

    if totalLesionPixels > 0
        lesionInSalientZone = sum(allLesionsMask(:) & salientZone(:));
        lesionCoverageRatio = lesionInSalientZone / totalLesionPixels;
    else
        lesionCoverageRatio = 1.0; % Clean eye
    end

    % Check individual lesion overlap
    maInSalient = sum(segResults.maMask(:) & salientZone(:)) / max(1, sum(segResults.maMask(:)));
    hmInSalient = sum(segResults.hmMask(:) & salientZone(:)) / max(1, sum(segResults.hmMask(:)));
    heInSalient = sum(segResults.heMask(:) & salientZone(:)) / max(1, sum(segResults.heMask(:)));
    nvInSalient = sum(segResults.nvMask(:) & salientZone(:)) / max(1, sum(segResults.nvMask(:)));

    correlation = struct();
    correlation.lesionCoverageRatio = lesionCoverageRatio;
    correlation.maOverlapPct = maInSalient * 100;
    correlation.hmOverlapPct = hmInSalient * 100;
    correlation.heOverlapPct = heInSalient * 100;
    correlation.nvOverlapPct = nvInSalient * 100;
    correlation.isClinicallyFaithful = (lesionCoverageRatio >= 0.75) || (totalLesionPixels == 0);
    correlation.salientAreaPct = (sum(salientZone(:)) / max(1, sum(segResults.retinalMask(:)))) * 100;
end
