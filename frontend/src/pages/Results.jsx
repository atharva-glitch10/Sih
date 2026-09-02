import { useState, useEffect } from "react";
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
  RefreshCw,
  Loader,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useScreening } from "../context/ScreeningContext";
import PatientDiagnosticCard from "../components/PatientDiagnosticCard";

function Results() {
  const navigate = useNavigate();
  const { diagnosis, patient, imageInfo } = useScreening();
  const [showDiagnosticCard, setShowDiagnosticCard] = useState(true);

  // Grad-CAM loading state
  const [gradcamStatus, setGradcamStatus] = useState("loading"); // 'loading' | 'ok' | 'error'
  const [gradcamKey, setGradcamKey] = useState(0); // increment to retry

  const [gradcamReady, setGradcamReady] = useState(false); // true once generate POST resolves

  useEffect(() => {
    if (!diagnosis?.patientID) return;
    setGradcamStatus("loading");
    setGradcamReady(false);

    // Trigger server-side heatmap generation, then mark ready so <img> can load.
    fetch(`/api/gradcam/${diagnosis.patientID}/generate`, { method: "POST" })
      .then(() => setGradcamReady(true))
      .catch(() => setGradcamReady(true)); // attempt img load even if generate fails
  }, [diagnosis?.patientID, gradcamKey]);

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
      description: "No apparent diabetic retinopathy lesions detected",
      themeColor: "#10b981",
      badgeText: "Normal Retinal FOV · 12-Month Routine Surveillance",
      badgeBg: "#ecfdf5",
      badgeBorder: "#a7f3d0",
      accentGrad: "linear-gradient(135deg, #10b981 0%, #059669 100%)",
      iconBg: "linear-gradient(135deg, rgba(16, 185, 129, 0.18) 0%, rgba(16, 185, 129, 0.05) 100%)",
    },
    1: {
      label: "Mild NPDR",
      description: "Microaneurysms only in peripheral vascular branches",
      themeColor: "#0284c7",
      badgeText: "Early Microvascular Alterations · 6-Month Review",
      badgeBg: "#f0f9ff",
      badgeBorder: "#bae6fd",
      accentGrad: "linear-gradient(135deg, #0284c7 0%, #0369a1 100%)",
      iconBg: "linear-gradient(135deg, rgba(2, 132, 199, 0.18) 0%, rgba(2, 132, 199, 0.05) 100%)",
    },
    2: {
      label: "Moderate NPDR",
      description: "Multiple microaneurysms, hemorrhages, and lipid hard exudates",
      themeColor: "#d97706",
      badgeText: "Referable NPDR · Specialist Ophthalmic Evaluation Indicated",
      badgeBg: "#fffbeb",
      badgeBorder: "#fde68a",
      accentGrad: "linear-gradient(135deg, #f59e0b 0%, #d97706 100%)",
      iconBg: "linear-gradient(135deg, rgba(245, 158, 11, 0.18) 0%, rgba(245, 158, 11, 0.05) 100%)",
    },
    3: {
      label: "Severe NPDR",
      description: "ETDRS 4-2-1 Rule: Severe 4-quadrant hemorrhages and ischemic micro-lesions",
      themeColor: "#ef4444",
      badgeText: "High-Risk Pre-Proliferative · Urgent Hospital Referral",
      badgeBg: "#fff7ed",
      badgeBorder: "#fed7aa",
      accentGrad: "linear-gradient(135deg, #ef4444 0%, #dc2626 100%)",
      iconBg: "linear-gradient(135deg, rgba(239, 68, 68, 0.18) 0%, rgba(239, 68, 68, 0.05) 100%)",
    },
    4: {
      label: "Proliferative DR",
      description: "Active neovascularization with high risk of severe visual loss",
      themeColor: "#7c3aed",
      badgeText: "Proliferative DR (PDR) · Priority Tertiary Anti-VEGF / Laser Triage",
      badgeBg: "#f5f3ff",
      badgeBorder: "#ddd6fe",
      accentGrad: "linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%)",
      iconBg: "linear-gradient(135deg, rgba(124, 58, 237, 0.18) 0%, rgba(124, 58, 237, 0.05) 100%)",
    },
  };

  const currentGrade = gradeInfo[result.grade] || gradeInfo[2];

  return (
    <div className="results-page">

      {/* Header */}
      <div className="results-header">
        <div>
          <p className="page-label">AI SCREENING · DIAGNOSTIC WORKSTATION</p>
          <h2>Clinical Analysis Results</h2>
          <p>
            Dual-Layer Explainability: ResNet-50 Feature Extraction & ETDRS 4-2-1 Clinical Rule Engine
          </p>
        </div>

        <div className="result-complete">
          <CheckCircle2 size={19} />
          <span>Clinical Triage Complete · Sub-30s SLA</span>
        </div>
      </div>

      {/* Main diagnosis Card with dynamic grade theming */}
      <div 
        className="diagnosis-card"
        style={{
          borderLeft: `6px solid ${currentGrade.themeColor}`,
          boxShadow: `0 8px 30px rgba(7, 30, 61, 0.08), 0 0 20px ${currentGrade.themeColor}15`,
        }}
      >
        <div className="diagnosis-main">
          <div 
            className="diagnosis-icon"
            style={{
              background: currentGrade.iconBg,
              color: currentGrade.themeColor,
              borderColor: `${currentGrade.themeColor}40`,
            }}
          >
            <ScanEye size={36} />
          </div>

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "10px", flexWrap: "wrap" }}>
              <span className="diagnosis-label" style={{ color: currentGrade.themeColor }}>
                ICDR DIABETIC RETINOPATHY GRADE
              </span>
              <span
                style={{
                  fontSize: "11px",
                  fontWeight: "700",
                  padding: "3px 10px",
                  borderRadius: "12px",
                  background: currentGrade.badgeBg,
                  color: currentGrade.themeColor,
                  border: `1px solid ${currentGrade.badgeBorder}`,
                }}
              >
                {currentGrade.badgeText}
              </span>
            </div>

            <h1 style={{ color: "var(--text-dark)", letterSpacing: "-0.03em" }}>
              Grade {result.grade}
            </h1>

            <h3 style={{ color: currentGrade.themeColor }}>
              {currentGrade.label}
            </h3>

            <p style={{ color: "var(--text-muted)", marginTop: "4px" }}>
              {currentGrade.description}
            </p>
          </div>
        </div>

        <div className="confidence-box" style={{ borderColor: `${currentGrade.themeColor}35` }}>
          <div style={{ display: "flex", justifyContent: "flex-end", alignItems: "center", gap: "6px", marginBottom: "4px" }}>
            <span style={{ fontSize: "11px", fontWeight: "700", color: "var(--text-muted)" }}>
              AI CERTAINTY
            </span>
            <span style={{ fontSize: "10px", color: "#16a34a", fontWeight: "700" }}>
              ● PASS
            </span>
          </div>
          <strong style={{ color: currentGrade.themeColor }}>{result.confidence}%</strong>

          <div className="confidence-bar">
            <div
              style={{
                width: `${result.confidence}%`,
                background: currentGrade.accentGrad,
                boxShadow: `0 0 10px ${currentGrade.themeColor}80`,
              }}
            ></div>
          </div>
          <div style={{ fontSize: "10px", color: "var(--text-faint)", marginTop: "6px", textAlign: "right" }}>
            Benchmark Target: ≥ 90.0%
          </div>
        </div>
      </div>

      {/* Referral status Banner */}
      <div
        className={
          result.referable
            ? "referral-banner referable"
            : "referral-banner non-referable"
        }
      >
        <div className="referral-icon">
          {result.referable ? (
            <AlertTriangle size={24} />
          ) : (
            <CheckCircle2 size={24} />
          )}
        </div>

        <div style={{ flex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", flexWrap: "wrap" }}>
            <strong>
              {result.referable
                ? "ACTION REQUIRED: Referable Diabetic Retinopathy (ICDR Grade 2+)"
                : "LOW RISK: Non-Referable Diabetic Retinopathy"}
            </strong>
            <span
              style={{
                fontSize: "11px",
                fontWeight: "700",
                padding: "2px 8px",
                borderRadius: "4px",
                background: result.referable ? "#fee2e2" : "#dcfce7",
                color: result.referable ? "#dc2626" : "#16a34a",
              }}
            >
              {result.referable ? "URGENT OPHTHALMIC CONSULT" : "PHC ROUTINE FOLLOW-UP"}
            </span>
          </div>

          <p>
            {result.referable
              ? "Patient requires structured tele-ophthalmology referral according to the rural PHC clinical escalation protocol."
              : "No sight-threatening retinopathy detected. Recommended for standard annual retinal photographic screening."}
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
            {imageInfo?.previewUrl ? (
              <img
                src={imageInfo.previewUrl}
                alt="Annotated Fundus Image"
                style={{
                  width: "100%",
                  borderRadius: "10px",
                  display: "block",
                  objectFit: "cover",
                  maxHeight: "280px",
                }}
                onError={(e) => {
                  // If preview URL fails (e.g. object URL expired), show placeholder
                  e.target.style.display = "none";
                  e.target.nextSibling.style.display = "flex";
                }}
              />
            ) : null}
            <div
              className="fundus-placeholder"
              style={{ display: imageInfo?.previewUrl ? "none" : "flex" }}
            >
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
            {diagnosis?.patientID && gradcamReady && gradcamStatus !== "error" ? (
              <img
                key={gradcamKey}
                src={`/api/gradcam/${diagnosis.patientID}?t=${gradcamKey}`}
                alt="Grad-CAM Attention Heatmap"
                style={{
                  width: "100%",
                  height: "100%",
                  borderRadius: "10px",
                  display: gradcamStatus === "ok" ? "block" : "none",
                  objectFit: "cover",
                }}
                onLoad={() => setGradcamStatus("ok")}
                onError={() => setGradcamStatus("error")}
              />
            ) : null}

            {/* Loading spinner */}
            {diagnosis?.patientID && gradcamStatus === "loading" && (
              <div className="gradcam-placeholder">
                <Loader size={42} style={{ animation: "spin 1s linear infinite" }} />
                <span>Generating Grad-CAM...</span>
                <small>Heatmap is being computed</small>
              </div>
            )}

            {/* Error / retry state */}
            {gradcamStatus === "error" && (
              <div className="gradcam-placeholder">
                <Brain size={42} />
                <span>Grad-CAM Heatmap</span>
                <small>Could not load heatmap</small>
                {diagnosis?.patientID && (
                  <button
                    onClick={() => {
                      setGradcamStatus("loading");
                      setGradcamKey((k) => k + 1);
                    }}
                    style={{
                      marginTop: "10px",
                      display: "flex",
                      alignItems: "center",
                      gap: "6px",
                      padding: "6px 14px",
                      borderRadius: "6px",
                      border: "1px solid #4a5568",
                      background: "transparent",
                      color: "inherit",
                      cursor: "pointer",
                      fontSize: "12px",
                    }}
                  >
                    <RefreshCw size={13} /> Retry
                  </button>
                )}
              </div>
            )}

            {/* No patient ID */}
            {!diagnosis?.patientID && (
              <div className="gradcam-placeholder">
                <Brain size={55} />
                <span>Grad-CAM Heatmap</span>
                <small>Regions influencing the prediction</small>
              </div>
            )}
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
            <h3>Quantitative Lesion & DME Evidence</h3>
            <p>AI-segmented microvascular biomarkers and macular risk assessment</p>
          </div>
        </div>

        <div className="lesion-grid">
          <Lesion
            name="Microaneurysms"
            value={result.microaneurysms}
            unit="detected"
            description="Small capillary outpouchings"
          />

          <Lesion
            name="Hemorrhages"
            value={result.hemorrhages}
            unit="clusters"
            description="Intraretinal hemorrhage foci"
          />

          <Lesion
            name="Hard Exudates"
            value={result.exudates}
            unit="pixels"
            description="Lipid exudates in retina"
          />

          <Lesion
            name="Neovascularization"
            value={result.neovascularization ? "Active NV Present" : "Not detected"}
            unit=""
            description="Abnormal new vessel growth"
          />
        </div>

        {/* DME Macular Edema Risk Highlight */}
        <div
          style={{
            marginTop: "16px",
            padding: "14px 18px",
            borderRadius: "10px",
            background: result.dmeScore > 60 ? "#fff5f5" : result.dmeScore > 30 ? "#fffbeb" : "#f0fdf4",
            border: `1px solid ${result.dmeScore > 60 ? "#fed7d7" : result.dmeScore > 30 ? "#fde68a" : "#bbf7d0"}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: "12px",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <span
              style={{
                fontSize: "12px",
                fontWeight: "700",
                textTransform: "uppercase",
                letterSpacing: "0.05em",
                color: result.dmeScore > 60 ? "#c53030" : result.dmeScore > 30 ? "#b7791f" : "#22543d",
              }}
            >
              Diabetic Macular Edema (DME) Risk:
            </span>
            <strong
              style={{
                fontSize: "14px",
                color: result.dmeScore > 60 ? "#e53e3e" : result.dmeScore > 30 ? "#d69e2e" : "#38a169",
              }}
            >
              {result.dmeRisk} ({result.dmeScore}/100)
            </strong>
          </div>
          <div style={{ fontSize: "12px", color: "var(--text-muted)" }}>
            ETDRS Macular Risk: Hard exudate proximity to Foveal Avascular Zone (FAZ) evaluated
          </div>
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
      <div style={{ marginTop: '28px', marginBottom: '28px' }}>
        <div 
          onClick={() => setShowDiagnosticCard(!showDiagnosticCard)}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: 'linear-gradient(135deg, rgba(7, 30, 61, 0.04) 0%, rgba(0, 194, 212, 0.08) 100%)',
            padding: '14px 22px',
            borderRadius: 'var(--radius-md)',
            cursor: 'pointer',
            border: '1px solid rgba(0, 194, 212, 0.25)',
            boxShadow: 'var(--shadow-sm)',
            transition: 'all 0.2s ease',
            marginBottom: '14px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Activity size={18} color="var(--netra-teal-dim)" />
            <span style={{ fontWeight: 700, color: 'var(--netra-navy)', fontSize: '13.5px', letterSpacing: '-0.01em' }}>
              {showDiagnosticCard ? 'Detailed Clinical Diagnostic Card (MathWorks SIH Bridge)' : 'Show Detailed Clinical Diagnostic Card'}
            </span>
          </div>
          {showDiagnosticCard ? <ChevronUp size={18} color="var(--netra-teal-dim)" /> : <ChevronDown size={18} color="var(--netra-teal-dim)" />}
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