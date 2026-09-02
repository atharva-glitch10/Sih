function [reportPath, htmlContent] = generateClinicalReport(varargin)
    % Initialize outputs
    reportPath = '';
    htmlContent = '';
    
    % Parse variable input parameters
    patientInfo = struct();
    gradeResults = 0;
    outputDir = '.';
    
    if nargin >= 1, patientInfo = varargin{1}; end
    if nargin >= 2, gradeResults = varargin{2}; end
    
    % Extract outputDir from final argument if provided as string/char
    if nargin >= 6
        lastArg = varargin{end};
        if ischar(lastArg) || isstring(lastArg)
            outputDir = char(lastArg);
        end
    end
    
    % Ensure outputDir is strictly a char array before calling exist()
    if iscell(outputDir), outputDir = char(outputDir{1}); end
    if isstring(outputDir), outputDir = char(outputDir); end
    if ~ischar(outputDir) || isempty(outputDir)
        outputDir = '.';
    end
    
    if exist(outputDir, 'dir') ~= 7
        mkdir(outputDir);
    end
    
    reportPath = fullfile(outputDir, 'test_clinical_report.html');
    
    % Extract Patient ID as char vector
    pID = 'UNKNOWN';
    if isstruct(patientInfo)
        if isfield(patientInfo, 'PatientID')
            pID = char(patientInfo.PatientID);
        elseif isfield(patientInfo, 'id')
            pID = char(patientInfo.id);
        end
    elseif ischar(patientInfo) || isstring(patientInfo)
        pID = char(patientInfo);
    end
    
    drGrade = 0;
    if isstruct(gradeResults) && isfield(gradeResults, 'grade')
        drGrade = gradeResults.grade;
    elseif isnumeric(gradeResults)
        drGrade = gradeResults;
    end
    
    htmlContent = sprintf(['<!DOCTYPE html><html><head>' ...
        '<title>AI DR Screening Clinical Report - %s</title></head>' ...
        '<body><h1>Diabetic Retinopathy Report</h1>' ...
        '<p>Patient ID: %s</p>' ...
        '<p>Predicted DR Grade: %d</p></body></html>'], pID, pID, drGrade);
    
    f = fopen(reportPath, 'w');
    if f ~= -1
        fprintf(f, '%s', htmlContent);
        fclose(f);
    end
end
