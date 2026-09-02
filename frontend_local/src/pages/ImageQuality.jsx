import {
  CheckCircle2,
  AlertTriangle,
  XCircle,
  ScanEye,
  ArrowLeft,
  ArrowRight,
  Focus,
  Sun,
  CircleDot,
} from "lucide-react";

import { useNavigate } from "react-router-dom";

function ImageQuality() {
  const navigate = useNavigate();

  // Demo values for now.
  // Later these will come from the MATLAB/FastAPI backend.
  const quality = {
    status: "Gradeable",
    score: 86,
    focus: 91,
    illumination: 84,
    fov: 88,
  };

  const getStatusIcon = () => {
    if (quality.status === "Gradeable") {
      return <CheckCircle2 size={24} />;
    }

    if (quality.status === "Borderline") {
      return <AlertTriangle size={24} />;
    }

    return <XCircle size={24} />;
  };

  return (
    <div className="iqa-page">

      {/* Header */}
      <div className="iqa-header">
        <div>
          <p className="page-label">IMAGE QUALITY ASSESSMENT</p>
          <h2>Retinal Image Quality</h2>
          <p>
            NETRA has analyzed the uploaded fundus image for AI readiness.
          </p>
        </div>

        <div className={`iqa-status ${quality.status.toLowerCase()}`}>
          {getStatusIcon()}
          <div>
            <strong>{quality.status}</strong>
            <span>Image Quality Status</span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="iqa-grid">

        {/* Image */}
        <div className="iqa-card image-card">
          <div className="card-title">
            <div className="section-icon">
              <ScanEye size={19} />
            </div>

            <div>
              <h3>Uploaded Fundus Image</h3>
              <p>Image received from PHC workstation</p>
            </div>
          </div>

          <div className="fundus-preview">
            <div className="fundus-placeholder">
              <ScanEye size={54} />
              <span>Fundus Image Preview</span>
              <small>Demo image</small>
            </div>
          </div>

          <div className="image-quality-score">
            <div>
              <span>Overall Quality Score</span>
              <strong>{quality.score}/100</strong>
            </div>

            <div className="score-bar">
              <div
                className="score-fill"
                style={{ width: `${quality.score}%` }}
              ></div>
            </div>
          </div>
        </div>

        {/* Quality Checks */}
        <div className="iqa-card">
          <div className="card-title">
            <div className="section-icon">
              <CheckCircle2 size={19} />
            </div>

            <div>
              <h3>Quality Checks</h3>
              <p>Automated image assessment</p>
            </div>
          </div>

          <div className="quality-checks">

            <QualityCheck
              icon={<Focus size={20} />}
              title="Focus & Sharpness"
              value={quality.focus}
              status="Good"
            />

            <QualityCheck
              icon={<Sun size={20} />}
              title="Illumination"
              value={quality.illumination}
              status="Good"
            />

            <QualityCheck
              icon={<CircleDot size={20} />}
              title="Retinal Field of View"
              value={quality.fov}
              status="Good"
            />

          </div>
        </div>
      </div>

      {/* Status Message */}
      <div className={`iqa-message ${quality.status.toLowerCase()}`}>
        <div className="iqa-message-icon">
          {getStatusIcon()}
        </div>

        <div>
          <strong>
            {quality.status === "Gradeable"
              ? "Image is suitable for AI analysis"
              : quality.status === "Borderline"
              ? "Image quality is borderline"
              : "Image cannot be analyzed"}
          </strong>

          <p>
            {quality.status === "Gradeable"
              ? "The image meets the minimum quality requirements for retinal lesion detection and diabetic retinopathy grading."
              : quality.status === "Borderline"
              ? "NETRA recommends enhancement before continuing with AI analysis."
              : "Please capture another fundus image with better focus, illumination and retinal coverage."}
          </p>
        </div>
      </div>

      {/* Recapture Guidance */}
      {quality.status !== "Gradeable" && (
        <div className="recapture-card">
          <div className="recapture-icon">
            <AlertTriangle size={20} />
          </div>

          <div>
            <h3>Recapture Guidance</h3>
            <ul>
              <li>Ensure the patient's eye is properly aligned.</li>
              <li>Keep the fundus camera steady.</li>
              <li>Ensure adequate retinal illumination.</li>
              <li>Capture the complete retinal field of view.</li>
            </ul>
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="screening-actions">

        <button
          className="secondary-button"
          onClick={() => navigate("/screening")}
        >
          <ArrowLeft size={17} />
          Back
        </button>

        <button
          className="primary-button"
          onClick={() => navigate("/analysis")}
          disabled={quality.status === "Ungradeable"}
        >
          Continue to AI Analysis
          <ArrowRight size={17} />
        </button>

      </div>
    </div>
  );
}

function QualityCheck({ icon, title, value, status }) {
  return (
    <div className="quality-check">
      <div className="quality-check-icon">
        {icon}
      </div>

      <div className="quality-check-info">
        <div className="quality-check-title">
          <strong>{title}</strong>
          <span>{status}</span>
        </div>

        <div className="quality-progress">
          <div
            className="quality-progress-fill"
            style={{ width: `${value}%` }}
          ></div>
        </div>
      </div>

      <strong className="quality-value">
        {value}
      </strong>
    </div>
  );
}

export default ImageQuality;