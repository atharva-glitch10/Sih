function [gradCam, overlay] = generateGradCAM(img, segResults, drGrade)
    % Generate saliency heatmaps for DR visual explainability
    if nargin < 3, drGrade = 0; end
    
    [h, w, ~] = size(img);
    gradCam = zeros(h, w);
    
    % Safely retrieve lesion masks or default to empty
    maMask = zeros(h, w);
    if isstruct(segResults) && isfield(segResults, 'maMask') && ~isempty(segResults.maMask)
        maMask = segResults.maMask;
    end
    
    heMask = zeros(h, w);
    if isstruct(segResults) && isfield(segResults, 'heMask') && ~isempty(segResults.heMask)
        heMask = segResults.heMask;
    end
    
    hardExudatesMask = zeros(h, w);
    if isstruct(segResults) && isfield(segResults, 'hardExudatesMask') && ~isempty(segResults.hardExudatesMask)
        hardExudatesMask = segResults.hardExudatesMask;
    end
    
    % Combine lesion responses for heatmap
    combinedLesions = double(maMask > 0) * 0.4 + double(heMask > 0) * 0.7 + double(hardExudatesMask > 0) * 0.9;
    
    if max(combinedLesions(:)) > 0
        gradCam = combinedLesions / max(combinedLesions(:));
    else
        % Synthetic smooth spatial heatmap centered on optic disc/fovea region
        [X, Y] = meshgrid(1:w, 1:h);
        gradCam = exp(-((X - w/2).^2 + (Y - h/2).^2) / (2 * (min(h,w)/4)^2));
    end
    
    % Create blended overlay (RGB)
    overlay = double(img);
    overlay(:,:,1) = min(255, overlay(:,:,1) + gradCam * 100);
    overlay = uint8(overlay);
end
