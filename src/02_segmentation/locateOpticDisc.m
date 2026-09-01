function [odMask, odCenter, odRadius, odProps] = locateOpticDisc(img, retinalMask)
% LOCATEOPTICDISC Detects and segments the Optic Disc (OD) in retinal fundus images.
%   Employs intensity thresholding on red channel, circular Hough transform/fitting,
%   and morphological refinement.
%
% Syntax:
%   [odMask, odCenter, odRadius, odProps] = locateOpticDisc(img)
%   [odMask, odCenter, odRadius, odProps] = locateOpticDisc(img, retinalMask)
%
% Outputs:
%   odMask   - Binary mask of Optic Disc [H x W logical]
%   odCenter - Coordinates [X_center, Y_center] in pixels
%   odRadius - Estimated disc radius in pixels
%   odProps  - Region properties struct
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if isa(img, 'uint8')
        imgD = im2double(img);
    else
        imgD = img;
    end

    [H, W, C] = size(imgD);

    if nargin < 2 || isempty(retinalMask)
        if C == 3
            gray = rgb2gray(imgD);
        else
            gray = imgD;
        end
        retinalMask = gray > 0.05;
        retinalMask = imfill(imclose(retinalMask, strel('disk', 5)), 'holes');
    end

    % Optic disc is brightest in Red channel and grayscale
    if C == 3
        redChan = imgD(:, :, 1);
        greenChan = imgD(:, :, 2);
        % OD stands out with high red & high green intensity
        odComposite = 0.6 * redChan + 0.4 * greenChan;
    else
        odComposite = imgD;
    end

    % Erode retinal mask slightly to avoid bright perimeter edge artifacts
    erodedMask = imerode(retinalMask, strel('disk', round(min(H, W) * 0.04)));
    odComposite(~erodedMask) = 0;

    % Top 1% brightest pixels as candidate seed region
    candidateThreshold = quantile(odComposite(erodedMask), 0.985);
    brightMask = (odComposite >= candidateThreshold) & erodedMask;

    % Morphological closing to coalesce OD core
    expectedODRadius = round(min(H, W) * 0.07); % OD is typically 1/14 to 1/10 of image width
    seOD = strel('disk', max(3, round(expectedODRadius * 0.4)));
    brightClosed = imclose(brightMask, seOD);
    brightFilled = imfill(brightClosed, 'holes');

    % Connected component selection based on area and circularity
    cc = bwconncomp(brightFilled);
    if cc.NumObjects > 0
        stats = regionprops(cc, 'Area', 'Centroid', 'Eccentricity', 'EquivDiameter');
        bestScore = -Inf;
        bestIdx = 1;
        
        for k = 1:numel(stats)
            area = stats(k).Area;
            ecc = stats(k).Eccentricity;
            eqDiam = stats(k).EquivDiameter;
            
            % Expected OD area is roughly pi * (expectedODRadius)^2
            expectedArea = pi * (expectedODRadius^2);
            areaRatio = min(area / expectedArea, expectedArea / max(1, area));
            circularityScore = 1.0 - ecc;
            
            score = 2.0 * circularityScore + 1.5 * areaRatio;
            if score > bestScore
                bestScore = score;
                bestIdx = k;
            end
        end
        
        odCenter = stats(bestIdx).Centroid;
        odRadius = max(round(expectedODRadius * 0.8), round(stats(bestIdx).EquivDiameter / 2));
    else
        % Fallback: Center of image right/left half
        odCenter = [round(W * 0.25), round(H * 0.5)];
        odRadius = expectedODRadius;
    end

    % Generate smooth circular mask around detected OD center
    [X, Y] = meshgrid(1:W, 1:H);
    distSq = (X - odCenter(1)).^2 + (Y - odCenter(2)).^2;
    odMask = distSq <= (odRadius^2);
    odMask = odMask & retinalMask;

    odProps = struct();
    odProps.center = odCenter;
    odProps.radius = odRadius;
    odProps.diameter = 2 * odRadius;
    odProps.mask = odMask;
end
