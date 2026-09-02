import { useState } from "react";
import {
  CheckCircle2,
  AlertTriangle,
  ScanEye,
  Brain,
  Activity,
  FileText,
  ArrowLeft,
  ArrowRight,
  ChevronDown,
  ChevronUp,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useScreening } from "../context/ScreeningContext";
import PatientDiagnosticCard from "../components/PatientDiagnosticCard";

function Results() {
  const navigate = useNavigate();
  const { diagnosis, patient } = useScreening();
  const [showDiagnosticCard, setShowDiagnosticCard] = useState(true);

  // Live results from backend engine (with fallback defaults)
  const result = {
    grade: diagnosis?.icdrGrade ?? 2,
    confidence: Number((((diagnosis?.confidence || 0.894) <= 1 ? (diagnosis?.confidence || 0.894) * 100 : (diagnosis?.confidence || 89.4))).toFixed(1)),
    referable: diagnosis?.isReferrable ?? true,
    microaneurysms: diagnosis?.biomarkers?.microaneurysms ?? diagnosis?.biomarkers?.MicroaneurysmsCount ?? 12,
    hemorrhages: diagnosis?.biomarkers?.hemorrhages ?? diagnosis?.biomarkers?.HemorrhagesCount ?? 6,
    exudates: diagnosis?.biomarkers?.hardExudatesArea ?? diagnosis?.biomarkers?.HardExudatesArea ?? 110,
    neovascularization: diagnosis?.biomarkers?.neovascularization ?? false,
    dmeRisk: diagnosis?.dmeRisk || "Moderate Risk",
    dmeScore: diagnosis?.dmeScore || 75,
    ruleExplanation: diagnosis?.ruleExplanation || "4-2-1 Rule evaluated.",
  };

  const gradeInfo = {
    0: {
      label: "No DR",
      description: "No apparent diabetic retinopathy",
    },
    1: {
      label: "Mild NPDR",
      description: "Mild non-proliferative diabetic retinopathy",
    },
    2: {
      label: "Moderate NPDR",
      description: "Moderate non-proliferative diabetic retinopathy",
    },
    3: {
      label: "Severe NPDR",
      description: "Severe non-proliferative diabetic retinopathy",
    },
    4: {
      label: "Proliferative DR",
      description: "Proliferative diabetic retinopathy",
    },
  };

  const currentGrade = gradeInfo[result.grade];

  return (
    <div className="results-page">

      {/* Header */}
      <div className="results-header">
        <div>
          <p className="page-label">SCREENING RESULTS</p>
          <h2>AI Analysis Results</h2>
          <p>
            NETRA has completed the diabetic retinopathy assessment.
          </p>
        </div>

        <div className="result-complete">
          <CheckCircle2 size={19} />
          Analysis Complete
        </div>
      </div>

      {/* Main diagnosis */}
      <div className="diagnosis-card">

        <div className="diagnosis-main">
          <div className="diagnosis-icon">
            <ScanEye size={30} />
          </div>

          <div>
            <span className="diagnosis-label">
              ICDR DIABETIC RETINOPATHY GRADE
            </span>

            <h1>Grade {result.grade}</h1>

            <h3>{currentGrade.label}</h3>

            <p>{currentGrade.description}</p>
          </div>
        </div>

        <div className="confidence-box">
          <span>AI Confidence</span>
          <strong>{result.confidence}%</strong>

          <div className="confidence-bar">
            <div
              style={{ width: `${result.confidence}%` }}
            ></div>
          </div>
        </div>
      </div>

      {/* Referral status */}
      <div
        className={
          result.referable
            ? "referral-banner referable"
            : "referral-banner non-referable"
        }
      >
        <div className="referral-icon">
          {result.referable ? (
            <AlertTriangle size={23} />
          ) : (
            <CheckCircle2 size={23} />
          )}
        </div>

        <div>
          <strong>
            {result.referable
              ? "Referable Diabetic Retinopathy"
              : "Non-Referable Diabetic Retinopathy"}
          </strong>

          <p>
            {result.referable
              ? "The patient should be referred for further ophthalmic evaluation."
              : "Routine monitoring and follow-up are recommended."}
          </p>
        </div>
      </div>

      {/* Analysis columns */}
      <div className="results-grid">

        {/* Fundus image */}
        <div className="results-card">
          <div className="card-title">
            <div className="section-icon">
              <ScanEye size={19} />
            </div>

            <div>
              <h3>Retinal Evidence</h3>
              <p>AI-detected retinal abnormalities</p>
            </div>
          </div>

          <div className="result-image">
            <div className="fundus-placeholder">
              <ScanEye size={55} />
              <span>Annotated Fundus Image</span>
              <small>Lesion overlays will appear here</small>
            </div>
          </div>
        </div>

        {/* Grad CAM */}
        <div className="results-card">
          <div className="card-title">
            <div className="section-icon">
              <Brain size={19} />
            </div>

            <div>
              <h3>AI Explainability</h3>
              <p>Grad-CAM attention map</p>
            </div>
          </div>

          <div className="gradcam-image">
            {diagnosis?.patientID ? (
              <img
                src={`/api/gradcam/${diagnosis.patientID}`}
                alt="Grad-CAM Attention Heatmap"
                style={{
                  width: "100%",
                  borderRadius: "10px",
                  display: "block",
                  objectFit: "cover",
                }}
                onError={(e) => {
                  e.target.style.display = "none";
                  e.target.nextSibling.style.display = "flex";
                }}
              />
            ) : null}
            <div
              className="gradcam-placeholder"
              style={{ display: diagnosis?.patientID ? "none" : "flex" }}
            >
              <Brain size={55} />
              <span>Grad-CAM Heatmap</span>
              <small>Regions influencing the prediction</small>
            </div>
          </div>
        </div>
      </div>

      {/* Lesion evidence */}
      <div className="results-card lesion-card">
        <div className="card-title">
          <div className="section-icon">
            <Activity size={19} />
          </div>

          <div>
            <h3>Lesion Evidence</h3>
            <p>Quantitative evidence supporting the prediction</p>
          </div>
        </div>

        <div className="lesion-grid">

          <Lesion
            name="Microaneurysms"
            value={result.microaneurysms}
            unit="detected"
            description="Small retinal vascular abnormalities"
          />

          <Lesion
            name="Hemorrhages"
            value={result.hemorrhages}
            unit="detected"
            description="Retinal bleeding regions"
          />

          <Lesion
            name="Hard Exudates"
            value={result.exudates}
            unit="pixels"
            description="Lipid deposits in the retina"
          />

          <Lesion
            name="Neovascularization"
            value={result.neovascularization ? "Detected" : "Not detected"}
            unit=""
            description="Abnormal new blood vessel growth"
          />

        </div>
      </div>

      {/* 4-2-1 explanation */}
      <div className="explanation-card">

        <div className="explanation-header">
          <div className="section-icon">
            <Brain size={19} />
          </div>

          <div>
            <h3>Why did NETRA assign Grade {result.grade}?</h3>
            <p>
              Explainable clinical reasoning based on detected lesions.
            </p>
          </div>
        </div>

        <div className="rule-list">

          <div className="rule-item">
            <div className="rule-number">4</div>
            <div>
              <strong>Severe retinal involvement</strong>
              <p>
                The number and distribution of retinal lesions are evaluated
                against the clinical severity criteria.
              </p>
            </div>
          </div>

          <div className="rule-item">
            <div className="rule-number">2</div>
            <div>
              <strong>Hemorrhage and microaneurysm evidence</strong>
              <p>
                Multiple detected microaneurysms and hemorrhages contribute
                to the severity assessment.
              </p>
            </div>
          </div>

          <div className="rule-item">
            <div className="rule-number">1</div>
            <div>
              <strong>Quadrant-based retinal assessment</strong>
              <p>
                Lesion distribution across retinal quadrants is considered
                during the final grading process.
              </p>
            </div>
          </div>

        </div>
      </div>

      {/* Explainable Diagnostic Card (MathWorks SIH Pipeline) */}
      <div style={{ marginTop: '24px', marginBottom: '24px' }}>
        <div 
          onClick={() => setShowDiagnosticCard(!showDiagnosticCard)}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: '#ebf4ff',
            padding: '12px 18px',
            borderRadius: '8px',
            cursor: 'pointer',
            border: '1px solid #bee3f8',
            marginBottom: '12px',
          }}
        >
          <span style={{ fontWeight: 700, color: '#2b6cb0', fontSize: '14px' }}>
            {showDiagnosticCard ? '▼ Detailed Clinical Diagnostic Card (MathWorks SIH Bridge)' : '▶ Show Detailed Clinical Diagnostic Card'}
          </span>
          {showDiagnosticCard ? <ChevronUp size={18} color="#2b6cb0" /> : <ChevronDown size={18} color="#2b6cb0" />}
        </div>

        {showDiagnosticCard && diagnosis && (
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <PatientDiagnosticCard data={diagnosis} />
          </div>
        )}
      </div>

      {/* Actions */}
      <div className="screening-actions">

        <button
          className="secondary-button"
          onClick={() => navigate("/analysis")}
        >
          <ArrowLeft size={17} />
          Back
        </button>

        <button
          className="primary-button"
          onClick={() => navigate("/doctor-review")}
        >
          Continue to Doctor Review
          <ArrowRight size={17} />
        </button>

        <button 
          className="report-button"
          onClick={() => navigate("/report-generation")}
        >
          <FileText size={17} />
          Generate Report
        </button>

      </div>

    </div>
  );
}

function Lesion({ name, value, unit, description }) {
  return (
    <div className="lesion-item">
      <div className="lesion-dot"></div>

      <div className="lesion-content">
        <strong>{name}</strong>

        <div className="lesion-value">
          {value}
          {unit && <span>{unit}</span>}
        </div>

        <p>{description}</p>
      </div>
    </div>
  );
}

export default Results;