function dataset = generateSyntheticFundusDataset(outputDir, numPerClass, imgSize)
% GENERATESYNTHETICFUNDUSDATASET Generates synthetic fundus images across ICDR Grades 0-4.
%   Synthesizes realistic retinal background illumination, optic disc, fovea,
%   vascular trees, and grade-specific lesions (MAs, HMs, HE, NV).
%
% Syntax:
%   dataset = generateSyntheticFundusDataset()
%   dataset = generateSyntheticFundusDataset(outputDir, numPerClass, imgSize)
%
% Outputs:
%   dataset - Struct array with paths, ground truth labels, and lesion metadata
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 1 || isempty(outputDir)
        outputDir = fullfile(pwd, 'data', 'synthetic');
    end

    if nargin < 2 || isempty(numPerClass)
        numPerClass = 3; % 3 images per class = 15 images total
    end

    if nargin < 3 || isempty(imgSize)
        imgSize = [512, 512];
    end

    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    H = imgSize(1);
    W = imgSize(2);
    centerX = W / 2;
    centerY = H / 2;
    retinalRadius = round(min(H, W) * 0.44);

    dataset = [];
    rng(42); % Deterministic seed for reproducible evaluation

    fprintf('Generating synthetic fundus dataset for ICDR Grades 0 to 4 in: %s\n', outputDir);

    for grade = 0:4
        for sampleIdx = 1:numPerClass
            imgRGB = zeros(H, W, 3);
            
            % 1. Retinal Background Disc
            [X, Y] = meshgrid(1:W, 1:H);
            distFromCenter = sqrt((X - centerX).^2 + (Y - centerY).^2);
            retinalMask = distFromCenter <= retinalRadius;

            % Realistic reddish-orange choroidal pigment variation
            pigmentNoise = imgaussfilt(rand(H, W), 15);
            redChan = (0.75 + 0.15 * pigmentNoise) .* (1.0 - 0.2 * (distFromCenter / retinalRadius));
            greenChan = (0.35 + 0.10 * pigmentNoise) .* (1.0 - 0.3 * (distFromCenter / retinalRadius));
            blueChan = (0.08 + 0.04 * pigmentNoise) .* (1.0 - 0.4 * (distFromCenter / retinalRadius));

            % 2. Optic Disc (Bright yellowish circle at nasal side)
            odCenter = [round(W * 0.28), round(H * 0.50)];
            odRadius = round(min(H, W) * 0.07);
            distOD = sqrt((X - odCenter(1)).^2 + (Y - odCenter(2)).^2);
            odMask = distOD <= odRadius;

            redChan(odMask) = 0.95;
            greenChan(odMask) = 0.85;
            blueChan(odMask) = 0.45;

            % 3. Fovea Centralis (Darker basin at temporal side)
            foveaCenter = [round(W * 0.65), round(H * 0.50)];
            distFovea = sqrt((X - foveaCenter(1)).^2 + (Y - foveaCenter(2)).^2);
            foveaMask = distFovea <= (odRadius * 0.6);

            redChan(foveaMask) = redChan(foveaMask) * 0.70;
            greenChan(foveaMask) = greenChan(foveaMask) * 0.65;
            blueChan(foveaMask) = blueChan(foveaMask) * 0.60;

            % 4. Vascular Tree Synthesis (Superior & Inferior Arcades)
            vesselMask = false(H, W);
            t = linspace(0, 1, 200);
            
            % Superior Arcade
            xArc1 = odCenter(1) + t * (W * 0.55);
            yArc1 = odCenter(2) - sin(t * pi * 0.8) * (H * 0.35) - t * (H * 0.1);
            
            % Inferior Arcade
            xArc2 = odCenter(1) + t * (W * 0.55);
            yArc2 = odCenter(2) + sin(t * pi * 0.8) * (H * 0.35) + t * (H * 0.1);

            for arc = 1:2
                if arc == 1, xArc = xArc1; yArc = yArc1; else, xArc = xArc2; yArc = yArc2; end
                for k = 1:numel(xArc)
                    px = round(xArc(k)); py = round(yArc(k));
                    if px >= 1 && px <= W && py >= 1 && py <= H
                        vesselMask(max(1, py-2):min(H, py+2), max(1, px-2):min(W, px+2)) = true;
                    end
                end
            end

            vesselMask = vesselMask & retinalMask;
            % Vessels appear dark in red/green
            redChan(vesselMask) = redChan(vesselMask) * 0.45;
            greenChan(vesselMask) = greenChan(vesselMask) * 0.25;
            blueChan(vesselMask) = blueChan(vesselMask) * 0.20;

            % 5. Grade-Specific Lesion Generation
            maMask = false(H, W);
            heMask = false(H, W);
            hmMask = false(H, W);
            nvMask = false(H, W);

            numMAs = 0; numHMs = 0; numHEs = 0; hasNV = false;

            if grade >= 1 % Mild NPDR: Few microaneurysms
                numMAs = 4 + randi(4);
            end

            if grade >= 2 % Moderate NPDR: More MAs, Hemorrhages, Hard Exudates
                numMAs = 10 + randi(6);
                numHMs = 6 + randi(4);
                numHEs = 8 + randi(6);
            end

            if grade >= 3 % Severe NPDR: Severe Hemorrhages in all 4 quadrants (4-2-1 rule)
                numMAs = 20 + randi(10);
                numHMs = 24 + randi(8);
                numHEs = 15 + randi(8);
            end

            if grade >= 4 % Proliferative DR: Neovascularization
                numMAs = 25 + randi(10);
                numHMs = 30 + randi(10);
                numHEs = 20 + randi(10);
                hasNV = true;
            end

            % Synthesize Microaneurysms (tiny dark red dots)
            for m = 1:numMAs
                mx = round(W * (0.35 + 0.45 * rand()));
                my = round(H * (0.25 + 0.50 * rand()));
                maMask(max(1, my-1):min(H, my+1), max(1, mx-1):min(W, mx+1)) = true;
            end
            maMask = maMask & retinalMask & ~odMask;
            redChan(maMask) = 0.35; greenChan(maMask) = 0.10; blueChan(maMask) = 0.08;

            % Synthesize Hard Exudates (bright yellow lipid patches)
            for e = 1:numHEs
                % Cluster near macula
                ex = round(foveaCenter(1) + (rand() - 0.5) * odRadius * 3.0);
                ey = round(foveaCenter(2) + (rand() - 0.5) * odRadius * 3.0);
                r = randi([2, 5]);
                if ex > r && ex < W-r && ey > r && ey < H-r
                    [Xsub, Ysub] = meshgrid((ex-r):(ex+r), (ey-r):(ey+r));
                    subMask = ((Xsub - ex).^2 + (Ysub - ey).^2) <= r^2;
                    heMask((ey-r):(ey+r), (ex-r):(ex+r)) = subMask;
                end
            end
            heMask = heMask & retinalMask & ~odMask;
            redChan(heMask) = 0.98; greenChan(heMask) = 0.95; blueChan(heMask) = 0.40;

            % Synthesize Hemorrhages (dark blotches)
            for h = 1:numHMs
                hx = round(W * (0.25 + 0.55 * rand()));
                hy = round(H * (0.20 + 0.60 * rand()));
                r = randi([3, 7]);
                if hx > r && hx < W-r && hy > r && hy < H-r
                    [Xsub, Ysub] = meshgrid((hx-r):(hx+r), (hy-r):(hy+r));
                    subMask = ((Xsub - hx).^2 + (Ysub - hy).^2) <= r^2;
                    hmMask((hy-r):(hy+r), (hx-r):(hx+r)) = subMask;
                end
            end
            hmMask = hmMask & retinalMask & ~odMask;
            redChan(hmMask) = 0.25; greenChan(hmMask) = 0.05; blueChan(hmMask) = 0.05;

            % Synthesize Neovascularization (fine branching mesh)
            if hasNV
                for nvLine = 1:12
                    nx = round(odCenter(1) + (rand() - 0.5) * odRadius * 2.2);
                    ny = round(odCenter(2) + (rand() - 0.5) * odRadius * 2.2);
                    len = randi([8, 16]);
                    ang = rand() * 2 * pi;
                    for step = 1:len
                        px = round(nx + step * cos(ang));
                        py = round(ny + step * sin(ang));
                        if px >= 1 && px <= W && py >= 1 && py <= H
                            nvMask(py, px) = true;
                        end
                    end
                end
                nvMask = nvMask & retinalMask;
                redChan(nvMask) = 0.30; greenChan(nvMask) = 0.12; blueChan(nvMask) = 0.10;
            end

            % Combine channels and mask background
            imgRGB(:, :, 1) = redChan .* retinalMask;
            imgRGB(:, :, 2) = greenChan .* retinalMask;
            imgRGB(:, :, 3) = blueChan .* retinalMask;

            % Save image
            filename = sprintf('DR_Grade%d_Sample%02d.png', grade, sampleIdx);
            filepath = fullfile(outputDir, filename);
            imwrite(imgRGB, filepath);

            % Record metadata
            meta = struct();
            meta.filename = filename;
            meta.filepath = filepath;
            meta.grade = grade;
            meta.isReferable = (grade >= 2);
            meta.numMAs = numMAs;
            meta.numHMs = numHMs;
            meta.numHEs = numHEs;
            meta.hasNV = hasNV;
            meta.odCenter = odCenter;
            meta.foveaCenter = foveaCenter;

            dataset = [dataset; meta]; %#ok<AGROW>
        end
    end

    fprintf('[SUCCESS] Generated %d synthetic fundus images across all ICDR grades.\n', numel(dataset));
end
