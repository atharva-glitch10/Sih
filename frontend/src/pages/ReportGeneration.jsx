import { useEffect, useState } from "react";
import {
  FileText,
  CheckCircle2,
  Printer,
  ArrowLeft,
  Loader2,
  ExternalLink,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useScreening } from "../context/ScreeningContext";

function ReportGeneration() {
  const navigate = useNavigate();
  const { patient, diagnosis, doctorReview } = useScreening();

  const [generating, setGenerating] = useState(true);
  const [generated, setGenerated] = useState(false);
  const [progress, setProgress] = useState(0);

  const report = {
    screeningId: diagnosis?.patientID || patient.id || "NETRA-2026-0842",
    patient: patient.name || "Demo Patient",
    age: patient.age || 58,
    gender: patient.gender || "Female",
    location: patient.location || "Rural PHC Shirwal",
    date: new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }),

    grade: diagnosis?.icdrGrade ?? 2,
    diagnosis: diagnosis?.gradeLabel || "Moderate NPDR",
    confidence: Number((((diagnosis?.confidence || 0.894) <= 1 ? (diagnosis?.confidence || 0.894) * 100 : (diagnosis?.confidence || 89.4))).toFixed(1)),
    referral: diagnosis?.isReferrable ? "Referable" : "Non-Referable",

    microaneurysms: diagnosis?.biomarkers?.microaneurysms ?? diagnosis?.biomarkers?.MicroaneurysmsCount ?? 12,
    hemorrhages: diagnosis?.biomarkers?.hemorrhages ?? diagnosis?.biomarkers?.HemorrhagesCount ?? 6,
    exudates: diagnosis?.biomarkers?.hardExudatesArea ?? diagnosis?.biomarkers?.HardExudatesArea ?? 110,
    neovascularization: (diagnosis?.biomarkers?.neovascularization || diagnosis?.biomarkers?.Neovascularization) ? "Detected" : "Not Detected",

    doctorDecision: doctorReview?.decision || "Confirmed AI Result",
    doctorNotes: doctorReview?.notes || "AI findings reviewed. Screening evaluation complete.",
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

                <div className="explainability-placeholder" style={{ padding: 0, overflow: "hidden", background: "#000", minHeight: "160px", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  {report.screeningId ? (
                    <img
                      src={`/api/gradcam/${report.screeningId}`}
                      alt="Grad-CAM Heatmap"
                      style={{ width: "100%", height: "100%", objectFit: "cover", borderRadius: "6px", display: "block" }}
                      onError={(e) => { e.target.style.display = "none"; e.target.parentNode.querySelector("span").style.display = "block"; }}
                    />
                  ) : null}
                  <span style={{ display: "none", color: "#718096", fontSize: "13px" }}>Grad-CAM</span>
                </div>

                <div>
                  <h3>Why was Grade {report.grade} assigned?</h3>

                  <p>
                    {diagnosis?.ruleExplanation ||
                      `The AI model identified retinal lesion patterns consistent with ${report.diagnosis}.`}
                  </p>

                  <ul>
                    <li>
                      Microaneurysms detected: <strong>{report.microaneurysms}</strong>
                    </li>

                    <li>
                      Hemorrhages detected: <strong>{report.hemorrhages}</strong>
                    </li>

                    <li>
                      Hard exudate area: <strong>{report.exudates} px</strong>
                    </li>

                    <li>
                      Neovascularization: <strong>{report.neovascularization}</strong>
                    </li>

                    {diagnosis?.dmeRisk && (
                      <li>
                        DME Risk: <strong>{diagnosis.dmeRisk}</strong>
                        {diagnosis.dmeScore != null && ` (Score: ${diagnosis.dmeScore}/100)`}
                      </li>
                    )}
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
                {report.referral === "Referable" ? (
                  <>
                    <strong style={{ color: '#c53030' }}>
                      ⚠ Ophthalmological referral recommended.
                    </strong>
                    <p>
                      The screening result is classified as <strong>Referable</strong> diabetic
                      retinopathy (Grade {report.grade} — {report.diagnosis}). The patient
                      should undergo urgent evaluation by a qualified eye-care professional.
                    </p>
                  </>
                ) : (
                  <>
                    <strong style={{ color: '#276749' }}>
                      ✓ No immediate referral required.
                    </strong>
                    <p>
                      The screening result is classified as <strong>Non-Referable</strong>
                      (Grade {report.grade} — {report.diagnosis}). Routine monitoring and
                      annual follow-up are recommended.
                    </p>
                  </>
                )}
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

            <a
              href={`/api/reports/${report.screeningId}`}
              target="_blank"
              rel="noopener noreferrer"
              className="secondary-button"
              style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', textDecoration: 'none' }}
            >
              <ExternalLink size={18} />
              Open Backend Clinical Report
            </a>

            <button
              className="secondary-button"
              onClick={() =>
                navigate("/reports")
              }
            >
              <FileText size={18} />
              View All Reports
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