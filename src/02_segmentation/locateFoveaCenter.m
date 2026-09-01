function [foveaCenter, foveaMask, maculaRegionMask] = locateFoveaCenter(img, odCenter, odRadius, retinalMask)
% LOCATEFOVEACENTER Pinpoints the Fovea Centralis and Macular Region.
%   Uses geometric orientation relative to the Optic Disc (~2.5 Disc Diameters temporal)
%   combined with minimum intensity valley search on the green channel.
%
% Syntax:
%   [foveaCenter, foveaMask, maculaRegionMask] = locateFoveaCenter(img, odCenter, odRadius)
%   [foveaCenter, foveaMask, maculaRegionMask] = locateFoveaCenter(img, odCenter, odRadius, retinalMask)
%
% Outputs:
%   foveaCenter      - [X_fovea, Y_fovea] coordinates in pixels
%   foveaMask        - Small binary circle indicating the FAZ (Foveal Avascular Zone)
%   maculaRegionMask - 1 Disc Diameter (1 DD) radius zone around Fovea (critical for DME risk)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    [H, W, C] = size(imgD);

    if nargin < 4 || isempty(retinalMask)
        if C == 3
            gray = rgb2gray(imgD);
        else
            gray = imgD;
        end
        retinalMask = gray > 0.05;
    end

    if C == 3
        greenChan = imgD(:, :, 2);
    else
        greenChan = imgD;
    end

    discDiameter = 2 * odRadius;
    expectedTemporalDist = 2.5 * discDiameter;

    % Determine if OD is on the left (Right Eye - OD) or right (Left Eye - OS)
    if odCenter(1) < (W / 2)
        % OD is in nasal side on the left -> Fovea is temporal towards the right (+X)
        estimatedFoveaX = odCenter(1) + expectedTemporalDist;
    else
        % OD is in nasal side on the right -> Fovea is temporal towards the left (-X)
        estimatedFoveaX = odCenter(1) - expectedTemporalDist;
    end

    estimatedFoveaY = odCenter(2); % Roughly horizontal

    % Search window around estimated geometric point
    searchRadius = round(0.75 * discDiameter);
    xMin = max(1, round(estimatedFoveaX - searchRadius));
    xMax = min(W, round(estimatedFoveaX + searchRadius));
    yMin = max(1, round(estimatedFoveaY - searchRadius));
    yMax = min(H, round(estimatedFoveaY + searchRadius));

    % Smooth green channel in search window to find darkest intensity basin (FAZ)
    subGreen = greenChan(yMin:yMax, xMin:xMax);
    smoothedSub = imgaussfilt(subGreen, max(2, round(odRadius * 0.2)));

    [~, minIdx] = min(smoothedSub(:));
    [subY, subX] = ind2sub(size(smoothedSub), minIdx);

    foveaCenter = [xMin + subX - 1, yMin + subY - 1];

    % Bounds clamp
    foveaCenter(1) = max(1, min(W, foveaCenter(1)));
    foveaCenter(2) = max(1, min(H, foveaCenter(2)));

    [X, Y] = meshgrid(1:W, 1:H);
    distFromFovea = sqrt((X - foveaCenter(1)).^2 + (Y - foveaCenter(2)).^2);

    % Fovea mask (FAZ radius ~ 0.25 disc diameter)
    fazRadius = max(5, round(discDiameter * 0.25));
    foveaMask = (distFromFovea <= fazRadius) & retinalMask;

    % Macula region (1 Disc Diameter radius around foveal center)
    maculaRadius = max(10, round(discDiameter * 1.0));
    maculaRegionMask = (distFromFovea <= maculaRadius) & retinalMask;
end
