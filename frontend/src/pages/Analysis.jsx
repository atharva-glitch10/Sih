import { useEffect, useState } from "react";
import {
  ScanEye,
  Brain,
  CircleDot,
  Activity,
  CheckCircle2,
  ArrowLeft,
  ArrowRight,
  AlertTriangle,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useScreening } from "../context/ScreeningContext";

function Analysis() {
  const navigate = useNavigate();
  const { executeDiagnosis, diagnosis, isDiagnosing, diagnosisError } = useScreening();

  const [progress, setProgress] = useState(0);
  const [completed, setCompleted] = useState(false);
  const [apiDone, setApiDone] = useState(false);

  useEffect(() => {
    let isMounted = true;

    // Trigger backend diagnosis
    executeDiagnosis()
      .then(() => {
        if (isMounted) setApiDone(true);
      })
      .catch((err) => {
        console.warn("Diagnosis call completed with fallback:", err);
        if (isMounted) setApiDone(true);
      });

    // Animate stages smoothly
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 90 && !apiDone) {
          return 90; // Wait for API response before 100%
        }
        if (prev >= 100) {
          clearInterval(interval);
          setCompleted(true);
          return 100;
        }
        return prev + 2;
      });
    }, 40);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [apiDone]);

  const steps = [
    {
      title: "Image preprocessing",
      description: "Normalizing retinal image",
      icon: ScanEye,
      complete: progress >= 20,
    },
    {
      title: "Retinal structure analysis",
      description: "Detecting optic disc and vessels",
      icon: CircleDot,
      complete: progress >= 45,
    },
    {
      title: "Lesion detection",
      description: "Searching for DR biomarkers",
      icon: Activity,
      complete: progress >= 70,
    },
    {
      title: "DR classification",
      description: "Predicting ICDR severity",
      icon: Brain,
      complete: progress >= 100,
    },
  ];

  return (
    <div className="analysis-page">

      {/* Header */}
      <div className="analysis-header">
        <div>
          <p className="page-label">AI ANALYSIS</p>
          <h2>Retinal AI Analysis</h2>
          <p>
            NETRA is analyzing the retinal image for diabetic retinopathy
            indicators.
          </p>
        </div>

        <div className="analysis-engine">
          <span className="analysis-dot"></span>
          AI Engine {completed ? "Complete" : "Running"}
        </div>
      </div>

      {/* Progress */}
      <div className="analysis-progress-card">
        <div className="progress-top">
          <div>
            <strong>
              {completed
                ? "Analysis completed"
                : "Analyzing retinal image..."}
            </strong>

            <span>
              {completed
                ? "All AI analysis stages have been completed."
                : "Please wait while NETRA processes the retinal image."}
            </span>
          </div>

          <strong className="progress-number">
            {progress}%
          </strong>
        </div>

        <div className="analysis-progress">
          <div
            className="analysis-progress-fill"
            style={{ width: `${progress}%` }}
          ></div>
        </div>
      </div>

      {/* Main analysis area */}
      <div className="analysis-grid">

        {/* Image */}
        <div className="analysis-card">
          <div className="card-title">
            <div className="section-icon">
              <ScanEye size={19} />
            </div>

            <div>
              <h3>Retinal Image</h3>
              <p>Input image being analyzed</p>
            </div>
          </div>

          <div className="analysis-image">
            <div className="fundus-placeholder">
              <ScanEye size={58} />
              <span>Fundus Image</span>
              <small>AI processing preview</small>
            </div>

            {!completed && (
              <div className="scanning-line"></div>
            )}
          </div>
        </div>

        {/* Processing stages */}
        <div className="analysis-card">
          <div className="card-title">
            <div className="section-icon">
              <Brain size={19} />
            </div>

            <div>
              <h3>Analysis Pipeline</h3>
              <p>AI processing stages</p>
            </div>
          </div>

          <div className="analysis-steps">
            {steps.map((step) => {
              const Icon = step.icon;

              return (
                <div className="analysis-step" key={step.title}>
                  <div
                    className={
                      step.complete
                        ? "analysis-step-icon complete"
                        : "analysis-step-icon"
                    }
                  >
                    {step.complete ? (
                      <CheckCircle2 size={19} />
                    ) : (
                      <Icon size={19} />
                    )}
                  </div>

                  <div className="analysis-step-text">
                    <strong>{step.title}</strong>
                    <span>{step.description}</span>
                  </div>

                  <div className="analysis-step-status">
                    {step.complete ? "Complete" : "Processing"}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Biomarkers */}
      <div className="analysis-card biomarker-card">
        <div className="card-title">
          <div className="section-icon">
            <Activity size={19} />
          </div>

          <div>
            <h3>Lesion Detection</h3>
            <p>Retinal biomarkers identified by NETRA</p>
          </div>
        </div>

        <div className="biomarker-grid">

          <Biomarker
            name="Microaneurysms"
            value={completed ? `${diagnosis?.biomarkers?.microaneurysms ?? diagnosis?.biomarkers?.MicroaneurysmsCount ?? 0} detected` : "Analyzing..."}
          />

          <Biomarker
            name="Hemorrhages"
            value={completed ? `${diagnosis?.biomarkers?.hemorrhages ?? diagnosis?.biomarkers?.HemorrhagesCount ?? 0} detected` : "Analyzing..."}
          />

          <Biomarker
            name="Hard Exudates"
            value={completed ? `${diagnosis?.biomarkers?.hardExudatesArea ?? diagnosis?.biomarkers?.HardExudatesArea ?? 0} px` : "Analyzing..."}
          />

          <Biomarker
            name="Neovascularization"
            value={completed ? ((diagnosis?.biomarkers?.neovascularization || diagnosis?.biomarkers?.Neovascularization) ? "Detected ⚠️" : "Not detected ✓") : "Analyzing..."}
          />

        </div>
      </div>

      {/* Actions */}
      <div className="screening-actions">

        <button
          className="secondary-button"
          onClick={() => navigate("/image-quality")}
        >
          <ArrowLeft size={17} />
          Back
        </button>

        <button
          className="primary-button"
          disabled={!completed}
          onClick={() => navigate("/results")}
        >
          View Analysis Results
          <ArrowRight size={17} />
        </button>

      </div>
    </div>
  );
}

function Biomarker({ name, value }) {
  return (
    <div className="biomarker">
      <div className="biomarker-indicator"></div>

      <div>
        <strong>{name}</strong>
        <span>{value}</span>
      </div>
    </div>
  );
}

export default Analysis;