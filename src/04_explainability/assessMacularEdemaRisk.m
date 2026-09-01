function [dmeRisk, dmeScore, dmeExplanation, dmeZoneMask] = assessMacularEdemaRisk(foveaCenter, odRadius, heMask, retinalMask)
% ASSESSMACULAREDEMARISK Evaluates Clinically Significant Macular Edema (CSME) risk.
%   Analyzes the proximity and area of hard exudates relative to the Fovea Centralis.
%
% Syntax:
%   [dmeRisk, dmeScore, dmeExplanation, dmeZoneMask] = assessMacularEdemaRisk(foveaCenter, odRadius, heMask, retinalMask)
%
% Outputs:
%   dmeRisk        - 'None', 'Moderate Risk', or 'High Risk (CSME Likely)'
%   dmeScore       - Risk index [0 - 100]
%   dmeExplanation - Clinical explanation string
%   dmeZoneMask    - Multi-ring binary mask showing 1/3 DD and 1 DD critical zones
%
% Reference:
%   ETDRS Report No. 1, "Photocoagulation for diabetic macular edema." Arch Ophthalmol (1985)
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    [H, W] = size(heMask);
    discDiameter = 2 * odRadius;

    [X, Y] = meshgrid(1:W, 1:H);
    distFromFovea = sqrt((X - foveaCenter(1)).^2 + (Y - foveaCenter(2)).^2);

    % Ring 1: High critical zone (within 1/3 Disc Diameter ~ 500 microns)
    zone1_3DD = (distFromFovea <= (discDiameter / 3)) & retinalMask;

    % Ring 2: Intermediate critical zone (within 1 Disc Diameter ~ 1500 microns)
    zone1DD = (distFromFovea <= discDiameter) & retinalMask;

    % Ring 3: Outer macula zone (within 2 Disc Diameters)
    zone2DD = (distFromFovea <= (2 * discDiameter)) & retinalMask;

    dmeZoneMask = uint8(zone2DD) + uint8(zone1DD) + uint8(zone1_3DD);

    % Quantify exudates in each critical zone
    heInZone1_3DD = sum(heMask(:) & zone1_3DD(:));
    heInZone1DD = sum(heMask(:) & zone1DD(:));
    heInZone2DD = sum(heMask(:) & zone2DD(:));
    totalHE = sum(heMask(:));

    if heInZone1_3DD > 5
        dmeRisk = 'High Risk (CSME Likely)';
        dmeScore = 95;
        dmeExplanation = sprintf('CRITICAL: %d px hard exudates detected within 1/3 Disc Diameter (<500 µm) of Fovea center. Urgent Anti-VEGF / Focal Laser evaluation indicated.', heInZone1_3DD);
    elseif heInZone1DD > 15
        dmeRisk = 'Moderate Risk';
        dmeScore = 75;
        dmeExplanation = sprintf('WARNING: %d px hard exudates situated within 1 Disc Diameter of Foveal center. High likelihood of impending macular thickening.', heInZone1DD);
    elseif heInZone2DD > 30 || (totalHE > 50)
        dmeRisk = 'Low-to-Moderate Risk';
        dmeScore = 40;
        dmeExplanation = sprintf('Hard exudates present in outer paramacular zone (%d px within 2 DD). Regular OCT follow-up recommended.', heInZone2DD);
    else
        dmeRisk = 'None / Low Risk';
        dmeScore = 5;
        dmeExplanation = 'Macular region clear of significant lipid exudation.';
    end
end
