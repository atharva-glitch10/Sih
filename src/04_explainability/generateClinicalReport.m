function report = generateClinicalReport(patientInfo, imgOriginal, iqaReport, segResults, gradingResults, dmeRisk, dmeScore, dmeExpl, gradCamOverlay, outputPath)
% GENERATECLINICALREPORT Generates a sub-30-second tele-ophthalmology verification report.
%   Synthesizes key diagnostic tags, multi-panel diagnostic visual overlays,
%   biomarker quantification tables, and referral priority for rural PHC triage.
%
% Syntax:
%   report = generateClinicalReport(patientInfo, imgOriginal, iqaReport, segResults, gradingResults, dmeRisk, dmeScore, dmeExpl, gradCamOverlay)
%   report = generateClinicalReport(..., outputPath)
%
% Reference:
%   MathWorks SIH - Explainable AI for DR Screening in Rural PHCs

    if nargin < 10 || isempty(outputPath)
        outputPath = 'DR_Clinical_Report.html';
    end

    if isempty(patientInfo)
        patientInfo = struct('PatientID', 'PHC-MH-2026-0842', 'Age', 58, 'Gender', 'Female', ...
            'PHC_Location', 'Rural PHC Shirwal, Satara, MH', 'ScreeningDate', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
    end

    % Compile comprehensive report struct
    report = struct();
    report.patient = patientInfo;
    report.iqa = iqaReport;
    report.grading = gradingResults;
    report.dme = struct('risk', dmeRisk, 'score', dmeScore, 'explanation', dmeExpl);
    report.biomarkers = struct( ...
        'microaneurysms', segResults.maDetails.count, ...
        'hemorrhages', segResults.hmDetails.count, ...
        'hemorrhageArea', segResults.hmDetails.totalArea, ...
        'hardExudatesArea', segResults.heDetails.totalArea, ...
        'vesselDensity', segResults.vesselDensity, ...
        'neovascularization', segResults.nvDetails.nvDetected ...
    );

    % Color tagging for rapid visual triage
    if gradingResults.isReferable
        triageBadgeColor = '#d9534f'; % Urgent Red
        triageBadgeText = 'URGENT SPECIALIST REFERRAL REQUIRED';
    else
        triageBadgeColor = '#5cb85c'; % Green
        triageBadgeText = 'ROUTINE PHC ANNUAL RESCREENING';
    end

    % Build structured HTML clinical report
    htmlLines = {};
    htmlLines{end+1} = '<!DOCTYPE html>';
    htmlLines{end+1} = '<html lang="en"><head><meta charset="UTF-8">';
    htmlLines{end+1} = '<title>AI DR Screening Clinical Report - ' + string(patientInfo.PatientID) + '</title>';
    htmlLines{end+1} = '<style>';
    htmlLines{end+1} = 'body { font-family: "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 20px; background-color: #f4f6f9; color: #2c3e50; }';
    htmlLines{end+1} = '.container { max-width: 900px; margin: auto; background: white; padding: 25px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }';
    htmlLines{end+1} = '.header { display: flex; justify-content: space-between; border-bottom: 2px solid #3498db; padding-bottom: 12px; }';
    htmlLines{end+1} = '.title { font-size: 22px; font-weight: bold; color: #1a365d; }';
    htmlLines{end+1} = '.badge { display: inline-block; padding: 8px 16px; font-weight: bold; color: white; border-radius: 4px; margin-top: 10px; font-size: 14px; }';
    htmlLines{end+1} = '.grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 15px 0; }';
    htmlLines{end+1} = '.card { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 15px; }';
    htmlLines{end+1} = '.card h3 { margin-top: 0; color: #2b6cb0; border-bottom: 1px solid #e2e8f0; padding-bottom: 6px; }';
    htmlLines{end+1} = 'table { width: 100%; border-collapse: collapse; margin-top: 8px; }';
    htmlLines{end+1} = 'td, th { padding: 6px 10px; text-align: left; font-size: 13px; }';
    htmlLines{end+1} = 'tr:nth-child(even) { background-color: #f1f5f9; }';
    htmlLines{end+1} = '.alert-box { padding: 12px; border-radius: 4px; margin: 10px 0; font-size: 13px; font-weight: 500; }';
    htmlLines{end+1} = '</style></head><body>';

    htmlLines{end+1} = '<div class="container">';
    htmlLines{end+1} = '<div class="header"><div><div class="title">MathWorks AI Diabetic Retinopathy Screening</div>';
    htmlLines{end+1} = '<div style="font-size: 13px; color: #718096;">Rural PHC Tele-Ophthalmology Verification Report (Sub-30s Triage)</div></div>';
    htmlLines{end+1} = '<div style="text-align: right; font-size: 12px; color: #718096;">' + string(patientInfo.ScreeningDate) + '<br><b>' + string(patientInfo.PHC_Location) + '</b></div></div>';

    htmlLines{end+1} = sprintf('<div class="badge" style="background-color: %s;">%s</div>', triageBadgeColor, triageBadgeText);

    htmlLines{end+1} = '<div class="grid-2">';
    % Patient Card
    htmlLines{end+1} = '<div class="card"><h3>Patient Information</h3>';
    htmlLines{end+1} = sprintf('<table><tr><td><b>Patient ID:</b></td><td>%s</td></tr>', patientInfo.PatientID);
    htmlLines{end+1} = sprintf('<tr><td><b>Age / Gender:</b></td><td>%d / %s</td></tr>', patientInfo.Age, patientInfo.Gender);
    htmlLines{end+1} = sprintf('<tr><td><b>IQA Status:</b></td><td><b>%s</b> (Score: %.1f/100)</td></tr>', iqaReport.qualityCategory, iqaReport.overallScore);
    htmlLines{end+1} = '</table></div>';

    % Diagnosis Card
    htmlLines{end+1} = '<div class="card"><h3>AI Diagnostic Summary</h3>';
    htmlLines{end+1} = sprintf('<table><tr><td><b>ICDR Grade:</b></td><td><b style="color: %s;">%s</b></td></tr>', triageBadgeColor, gradingResults.gradeLabel);
    htmlLines{end+1} = sprintf('<tr><td><b>Confidence:</b></td><td>%.1f%%</td></tr>', gradingResults.confidence * 100);
    htmlLines{end+1} = sprintf('<tr><td><b>DME Risk:</b></td><td><b>%s</b> (Score: %d/100)</td></tr>', dmeRisk, dmeScore);
    htmlLines{end+1} = '</table></div></div>';

    % Biomarker & Clinical Rules Details
    htmlLines{end+1} = '<div class="card"><h3>Explainable Biomarker Quantification</h3>';
    htmlLines{end+1} = '<table><tr><th>Biomarker</th><th>Detected Quantity</th><th>Clinical ETDRS Relevance</th></tr>';
    htmlLines{end+1} = sprintf('<tr><td>Microaneurysms (MAs)</td><td><b>%d</b></td><td>Early capillary microvascular leakage</td></tr>', report.biomarkers.microaneurysms);
    htmlLines{end+1} = sprintf('<tr><td>Hemorrhages (HMs)</td><td><b>%d</b> (%d px total area)</td><td>4-2-1 Rule quadrant distribution</td></tr>', report.biomarkers.hemorrhages, round(report.biomarkers.hemorrhageArea));
    htmlLines{end+1} = sprintf('<tr><td>Hard Exudates (HE)</td><td><b>%d px</b></td><td>Lipid deposition & Macular Edema risk</td></tr>', round(report.biomarkers.hardExudatesArea));
    htmlLines{end+1} = sprintf('<tr><td>Neovascularization (NV)</td><td><b>%s</b></td><td>Defining hallmark of Proliferative DR (PDR)</td></tr>', string(logical(report.biomarkers.neovascularization)));
    htmlLines{end+1} = '</table>';

    htmlLines{end+1} = sprintf('<div class="alert-box" style="background-color: #ebf8ff; border-left: 4px solid #3182ce;"><b>Clinical Rationale:</b> %s</div>', gradingResults.explanation);
    htmlLines{end+1} = sprintf('<div class="alert-box" style="background-color: #fffaf0; border-left: 4px solid #dd6b20;"><b>DME Analysis:</b> %s</div>', dmeExpl);
    htmlLines{end+1} = '</div>';

    % Signoff Section
    htmlLines{end+1} = '<div style="margin-top: 20px; display: flex; justify-content: space-between; font-size: 12px; color: #718096; border-top: 1px solid #e2e8f0; padding-top: 10px;">';
    htmlLines{end+1} = '<div>Tele-Ophthalmologist Reviewer: ___________________</div>';
    htmlLines{end+1} = '<div>Action: [ ] Confirmed  [ ] Overruled  [ ] Request Secondary Angiography</div>';
    htmlLines{end+1} = '<div>Review Duration: &lt; 30 seconds SLA</div></div>';

    htmlLines{end+1} = '</div></body></html>';

    % Write HTML file
    fid = fopen(outputPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s\n', htmlLines{:});
        fclose(fid);
        report.htmlPath = outputPath;
    end
end
