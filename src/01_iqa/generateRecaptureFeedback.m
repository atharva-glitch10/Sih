function feedback = generateRecaptureFeedback(sharpnessDetails, illumDetails, fovDetails)
% GENERATERECAPTUREFEEDBACK Synthesizes actionable technician feedback for poor quality images.
%   Provides clear, step-by-step instructions for rural PHC health workers.
%
% Syntax:
%   feedback = generateRecaptureFeedback(sharpnessDetails, illumDetails, fovDetails)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    messages = {};
    actionItems = {};
    severity = 'None';

    % Check focus / blur
    if ~sharpnessDetails.isSharp
        if sharpnessDetails.normalizedScore < 10
            messages{end+1} = 'Severe motion blur or defocussed optical system detected.';
            actionItems{end+1} = 'Ask patient to fixate on internal target and hold camera firmly with both hands.';
            severity = 'Critical';
        else
            messages{end+1} = 'Mild focus softness detected on retinal vasculature.';
            actionItems{end+1} = 'Fine-tune diopter compensation dial on fundus scope.';
            if strcmp(severity, 'None')
                severity = 'Moderate';
            end
        end
    end

    % Check illumination
    if ~illumDetails.isUniform
        if illumDetails.overexposedPct > 12.0
            messages{end+1} = sprintf('Corneal glare / overexposure detected (%.1f%% of retinal area).', illumDetails.overexposedPct);
            actionItems{end+1} = 'Slightly reduce LED flash intensity or adjust camera working distance.';
            severity = 'Critical';
        elseif illumDetails.underexposedPct > 35.0
            messages{end+1} = sprintf('Severe underexposure / dark image (%.1f%% underexposed).', illumDetails.underexposedPct);
            actionItems{end+1} = 'Ensure patient pupil is sufficiently dilated (>3.5mm) or increase flash brightness.';
            severity = 'Critical';
        elseif illumDetails.entropy < 3.8
            messages{end+1} = 'Low dynamic range and low contrast in macular/peripapillary region.';
            actionItems{end+1} = 'Shield PHC room from ambient light and check lens cleanliness.';
            if strcmp(severity, 'None')
                severity = 'Moderate';
            end
        end
    end

    % Check field of view and centering
    if ~fovDetails.isAdequate
        if fovDetails.retinalAreaPct < 40.0
            messages{end+1} = sprintf('Incomplete retinal field of view (only %.1f%% visible).', fovDetails.retinalAreaPct);
            actionItems{end+1} = 'Reposition camera closer to patient pupil to capture full 45-degree field.';
            severity = 'Critical';
        elseif fovDetails.normCenterOffset >= 0.40
            messages{end+1} = 'Retinal image is severely decentered; optic disc or macula may be cropped.';
            actionItems{end+1} = 'Align camera optical axis with patient optical axis before triggering capture.';
            severity = 'Critical';
        end
    end

    if isempty(messages)
        messages{1} = 'Image quality is adequate for automated diagnostic grading.';
        actionItems{1} = 'Proceed with automated retinal lesion segmentation and grading.';
        severity = 'Optimal';
    end

    feedback = struct();
    feedback.severity = severity;
    feedback.summary = strjoin(messages, ' ');
    feedback.messages = messages;
    feedback.actionItems = actionItems;
    feedback.requiresRecapture = strcmp(severity, 'Critical');
end
