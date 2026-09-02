import { useState } from "react";
import {
  ScanEye,
  CheckCircle2,
  AlertTriangle,
  UserRound,
  MessageSquare,
  FileText,
  ArrowLeft,
  Save,
} from "lucide-react";

import { useNavigate } from "react-router-dom";

function DoctorReview() {
  const navigate = useNavigate();

  const [decision, setDecision] = useState("");
  const [notes, setNotes] = useState("");

  const aiResult = {
    grade: 2,
    diagnosis: "Moderate NPDR",
    confidence: 89.4,
    referable: true,
  };

  const handleFinalize = () => {
    if (!decision) {
      alert("Please select a review decision.");
      return;
    }

    alert("Doctor review finalized successfully.");
    navigate("/report-generation");
  };

  return (
    <div className="review-page">

      {/* Header */}
      <div className="review-header">
        <div>
          <p className="page-label">DOCTOR REVIEW</p>
          <h2>Tele-Ophthalmologist Review</h2>
          <p>
            Review the AI findings before finalizing the screening result.
          </p>
        </div>

        <div className="review-status">
          <div className="review-status-dot"></div>
          Awaiting Review
        </div>
      </div>

      {/* Patient information */}
      <div className="review-patient-card">

        <div className="patient-icon">
          <UserRound size={22} />
        </div>

        <div className="patient-details">
          <strong>Patient Screening</strong>

          <div className="patient-meta">
            <span>Patient: Demo Patient</span>
            <span>Age: 58</span>
            <span>Gender: Female</span>
            <span>PHC: Rural PHC Shirwal</span>
          </div>
        </div>

        <div className="patient-id">
          <span>Screening ID</span>
          <strong>NETRA-2026-0842</strong>
        </div>

      </div>

      {/* AI summary */}
      <div className="review-summary">

        <div className="summary-item">
          <span>AI Grade</span>
          <strong>Grade {aiResult.grade}</strong>
        </div>

        <div className="summary-item">
          <span>Diagnosis</span>
          <strong>{aiResult.diagnosis}</strong>
        </div>

        <div className="summary-item">
          <span>Confidence</span>
          <strong>{aiResult.confidence}%</strong>
        </div>

        <div className="summary-item referable-summary">
          <span>Referral</span>
          <strong>
            {aiResult.referable ? "Required" : "Not Required"}
          </strong>
        </div>

      </div>

      {/* Review content */}
      <div className="review-grid">

        {/* AI evidence */}
        <div className="review-card">

          <div className="card-title">
            <div className="section-icon">
              <ScanEye size={19} />
            </div>

            <div>
              <h3>AI Evidence</h3>
              <p>Evidence used by NETRA for classification</p>
            </div>
          </div>

          <div className="review-image-grid">

            <div className="review-image">
              <div className="fundus-placeholder">
                <ScanEye size={42} />
                <span>Fundus Image</span>
              </div>

              <small>Original</small>
            </div>

            <div className="review-image heatmap">
              <div className="fundus-placeholder">
                <ScanEye size={42} />
                <span>Grad-CAM</span>
              </div>

              <small>AI Attention</small>
            </div>

          </div>

          <div className="evidence-list">

            <Evidence
              label="Microaneurysms"
              value="12 detected"
            />

            <Evidence
              label="Hemorrhages"
              value="6 detected"
            />

            <Evidence
              label="Hard Exudates"
              value="110 pixels"
            />

            <Evidence
              label="Neovascularization"
              value="Not detected"
            />

          </div>

        </div>

        {/* Doctor decision */}
        <div className="review-card">

          <div className="card-title">
            <div className="section-icon">
              <MessageSquare size={19} />
            </div>

            <div>
              <h3>Clinical Review</h3>
              <p>Record your assessment of the AI result</p>
            </div>
          </div>

          <label className="review-label">
            Review Decision
          </label>

          <div className="decision-options">

            <button
              className={
                decision === "confirmed"
                  ? "decision-button selected"
                  : "decision-button"
              }
              onClick={() => setDecision("confirmed")}
            >
              <CheckCircle2 size={19} />

              <div>
                <strong>Confirm AI Result</strong>
                <span>AI grade is clinically acceptable</span>
              </div>
            </button>

            <button
              className={
                decision === "modified"
                  ? "decision-button selected"
                  : "decision-button"
              }
              onClick={() => setDecision("modified")}
            >
              <AlertTriangle size={19} />

              <div>
                <strong>Modify AI Result</strong>
                <span>Clinical assessment differs from AI</span>
              </div>
            </button>

          </div>

          {decision === "modified" && (
            <div className="grade-selection">

              <label className="review-label">
                Select Clinical Grade
              </label>

              <div className="grade-buttons">
                {[0, 1, 2, 3, 4].map((grade) => (
                  <button key={grade}>
                    {grade}
                  </button>
                ))}
              </div>

            </div>
          )}

          <label className="review-label notes-label">
            Clinical Notes
          </label>

          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Enter observations, recommendations or clinical notes..."
            rows="6"
          />

        </div>

      </div>

      {/* Recommendation */}
      <div className="review-recommendation">

        <div className="recommendation-icon">
          <AlertTriangle size={21} />
        </div>

        <div>
          <strong>NETRA Recommendation</strong>

          <p>
            Refer the patient for further ophthalmic evaluation based on the
            detected retinal lesions and AI classification.
          </p>
        </div>

      </div>

      {/* Actions */}
      <div className="screening-actions">

        <button
          className="secondary-button"
          onClick={() => navigate("/results")}
        >
          <ArrowLeft size={17} />
          Back to Results
        </button>

        <button
          className="primary-button"
          onClick={handleFinalize}
        >
          <Save size={17} />
          Finalize Review
        </button>

        <button className="report-button">
          <FileText size={17} />
          Generate Report
        </button>

      </div>

    </div>
  );
}

function Evidence({ label, value }) {
  return (
    <div className="evidence-row">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

export default DoctorReview;