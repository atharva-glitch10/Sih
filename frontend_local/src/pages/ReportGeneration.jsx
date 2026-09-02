import { useEffect, useState } from "react";
import {
  FileText,
  CheckCircle2,
  Printer,
  ArrowLeft,
  Loader2,
} from "lucide-react";
import { useNavigate } from "react-router-dom";

function ReportGeneration() {
  const navigate = useNavigate();

  const [generating, setGenerating] = useState(true);
  const [generated, setGenerated] = useState(false);
  const [progress, setProgress] = useState(0);

  const report = {
    screeningId: "NETRA-2026-0842",
    patient: "Demo Patient",
    age: 58,
    gender: "Female",
    location: "Rural PHC Shirwal",
    date: "02 Sep 2026",

    grade: 2,
    diagnosis: "Moderate NPDR",
    confidence: 89.4,
    referral: "Referable",

    microaneurysms: 12,
    hemorrhages: 6,
    exudates: 110,
    neovascularization: "Not Detected",

    doctorDecision: "Confirmed AI Result",
    doctorNotes:
      "AI findings reviewed. Moderate diabetic retinopathy detected. Patient should be referred for ophthalmological evaluation.",
  };

  // Simulate report generation
  useEffect(() => {
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval);
          setGenerating(false);
          setGenerated(true);
          return 100;
        }

        return prev + 5;
      });
    }, 100);

    return () => clearInterval(interval);
  }, []);

  // Print / Save as PDF
  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="report-generation-page">

      {/* Header */}
      <div className="report-generation-header no-print">
        <div>
          <span className="page-eyebrow">CLINICAL REPORT</span>

          <h1>Report Generation</h1>

          <p>
            Generate the final NETRA diabetic retinopathy
            screening report.
          </p>
        </div>

        <div className="report-id">
          <span>Screening ID</span>
          <strong>{report.screeningId}</strong>
        </div>
      </div>

      {/* GENERATING */}
      {generating && (
        <div className="report-generation-card no-print">

          <div className="generation-state">

            <div className="generation-icon">
              <Loader2
                size={42}
                className="spinning"
              />
            </div>

            <h2>Generating Clinical Report</h2>

            <p>
              NETRA is compiling the patient's screening
              results, retinal evidence, explainability
              information and doctor's review.
            </p>

            <div className="generation-progress">

              <div className="progress-header">
                <span>Report generation</span>
                <strong>{progress}%</strong>
              </div>

              <div className="progress-track">
                <div
                  className="progress-fill"
                  style={{
                    width: `${progress}%`,
                  }}
                />
              </div>

            </div>

            <div className="generation-steps">

              <GenerationStep
                label="Patient information"
                complete={progress >= 20}
              />

              <GenerationStep
                label="AI screening results"
                complete={progress >= 40}
              />

              <GenerationStep
                label="Retinal evidence"
                complete={progress >= 60}
              />

              <GenerationStep
                label="Doctor review"
                complete={progress >= 80}
              />

              <GenerationStep
                label="Clinical report"
                complete={progress >= 100}
              />

            </div>

          </div>

        </div>
      )}

      {/* GENERATED REPORT */}
      {generated && (
        <>
          <div className="clinical-report">

            {/* Report Header */}
            <div className="clinical-report-header">

              <div className="report-logo">
                <div className="report-logo-icon">
                  <FileText size={25} />
                </div>

                <div>
                  <h2>NETRA</h2>
                  <span>
                    AI Diabetic Retinopathy Screening
                  </span>
                </div>
              </div>

              <div className="report-title">
                <h1>Clinical Screening Report</h1>
                <p>
                  Explainable AI-assisted retinal screening
                </p>
              </div>

            </div>

            {/* Patient Information */}
            <ReportSection title="Patient Information">

              <div className="report-grid">

                <ReportField
                  label="Patient Name"
                  value={report.patient}
                />

                <ReportField
                  label="Screening ID"
                  value={report.screeningId}
                />

                <ReportField
                  label="Age"
                  value={`${report.age} years`}
                />

                <ReportField
                  label="Gender"
                  value={report.gender}
                />

                <ReportField
                  label="Screening Location"
                  value={report.location}
                />

                <ReportField
                  label="Screening Date"
                  value={report.date}
                />

              </div>

            </ReportSection>

            {/* Diagnosis */}
            <ReportSection title="Final Diagnosis">

              <div className="diagnosis-report-card">

                <div>
                  <span>ICDR Grade</span>
                  <strong>
                    Grade {report.grade}
                  </strong>
                </div>

                <div>
                  <span>Diagnosis</span>
                  <strong>
                    {report.diagnosis}
                  </strong>
                </div>

                <div>
                  <span>AI Confidence</span>
                  <strong>
                    {report.confidence}%
                  </strong>
                </div>

                <div>
                  <span>Referral Status</span>
                  <strong className="report-referable">
                    {report.referral}
                  </strong>
                </div>

              </div>

            </ReportSection>

            {/* Retinal Evidence */}
            <ReportSection title="Retinal Evidence">

              <div className="evidence-report-grid">

                <EvidenceItem
                  label="Microaneurysms"
                  value={report.microaneurysms}
                />

                <EvidenceItem
                  label="Hemorrhages"
                  value={report.hemorrhages}
                />

                <EvidenceItem
                  label="Hard Exudates"
                  value={`${report.exudates} px`}
                />

                <EvidenceItem
                  label="Neovascularization"
                  value={report.neovascularization}
                />

              </div>

            </ReportSection>

            {/* Explainability */}
            <ReportSection title="AI Explainability">

              <div className="explainability-report">

                <div className="explainability-placeholder">
                  Grad-CAM
                </div>

                <div>
                  <h3>Why was Grade 2 assigned?</h3>

                  <p>
                    The AI model identified retinal lesion
                    patterns consistent with moderate
                    non-proliferative diabetic retinopathy.
                  </p>

                  <ul>
                    <li>
                      Multiple microaneurysms detected
                    </li>

                    <li>
                      Retinal hemorrhages detected
                    </li>

                    <li>
                      Hard exudate evidence detected
                    </li>

                    <li>
                      No neovascularization detected
                    </li>
                  </ul>
                </div>

              </div>

            </ReportSection>

            {/* Doctor Review */}
            <ReportSection title="Doctor Review">

              <div className="doctor-review-report">

                <ReportField
                  label="Decision"
                  value={report.doctorDecision}
                />

                <div className="doctor-notes">
                  <span>Clinical Notes</span>
                  <p>{report.doctorNotes}</p>
                </div>

              </div>

            </ReportSection>

            {/* Recommendation */}
            <ReportSection title="Recommendation">

              <div className="recommendation-report">
                <strong>
                  Ophthalmological referral recommended.
                </strong>

                <p>
                  The screening result is classified as
                  referable diabetic retinopathy. The patient
                  should undergo further evaluation by a
                  qualified eye-care professional.
                </p>
              </div>

            </ReportSection>

            {/* Footer */}
            <div className="clinical-report-footer">

              <div>
                <strong>NETRA</strong>
                <span>
                  AI-assisted screening system
                </span>
              </div>

              <span>
                Generated on {report.date}
              </span>

            </div>

          </div>

          {/* ACTIONS */}
          <div className="report-actions no-print">

            <button
              className="secondary-button"
              onClick={() =>
                navigate("/reports")
              }
            >
              <FileText size={18} />
              View Reports
            </button>

            <button
              className="primary-button"
              onClick={handlePrint}
            >
              <Printer size={18} />
              Print / Save as PDF
            </button>

          </div>

          <button
            className="back-button no-print"
            onClick={() =>
              navigate("/doctor-review")
            }
          >
            <ArrowLeft size={18} />
            Back to Doctor Review
          </button>
        </>
      )}

    </div>
  );
}


/* =========================
   COMPONENTS
========================= */

function GenerationStep({ label, complete }) {
  return (
    <div className="generation-step">

      <div
        className={
          complete
            ? "step-check complete"
            : "step-check"
        }
      >
        {complete && (
          <CheckCircle2 size={17} />
        )}
      </div>

      <span>{label}</span>

    </div>
  );
}


function ReportSection({ title, children }) {
  return (
    <section className="report-section">

      <h2>{title}</h2>

      {children}

    </section>
  );
}


function ReportField({ label, value }) {
  return (
    <div className="report-field">

      <span>{label}</span>

      <strong>{value}</strong>

    </div>
  );
}


function EvidenceItem({ label, value }) {
  return (
    <div className="evidence-report-item">

      <span>{label}</span>

      <strong>{value}</strong>

    </div>
  );
}


export default ReportGeneration;