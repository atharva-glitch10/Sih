import { useEffect, useState } from "react";
import {
  Activity,
  AlertTriangle,
  ArrowRight,
  CheckCircle2,
  Clock3,
  ScanEye,
  Users,
} from "lucide-react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { useNavigate } from "react-router-dom";
import { useScreening } from "../context/ScreeningContext";

const gradeData = [
  { grade: "Grade 0", label: "No DR", count: 822 },
  { grade: "Grade 1", label: "Mild NPDR", count: 143 },
  { grade: "Grade 2", label: "Moderate NPDR", count: 96 },
  { grade: "Grade 3", label: "Severe NPDR", count: 45 },
  { grade: "Grade 4", label: "Proliferative DR", count: 178 },
];

const recentScreenings = [
  {
    id: "NETRA-2026-0842",
    patient: "Demo Patient",
    age: 58,
    grade: 2,
    diagnosis: "Moderate NPDR",
    status: "Referable",
    time: "10 min ago",
  },
  {
    id: "NETRA-2026-0841",
    patient: "Patient A",
    age: 64,
    grade: 1,
    diagnosis: "Mild NPDR",
    status: "Non-Referable",
    time: "32 min ago",
  },
  {
    id: "NETRA-2026-0840",
    patient: "Patient B",
    age: 52,
    grade: 0,
    diagnosis: "No DR",
    status: "Non-Referable",
    time: "1 hr ago",
  },
  {
    id: "NETRA-2026-0839",
    patient: "Patient C",
    age: 67,
    grade: 3,
    diagnosis: "Severe NPDR",
    status: "Referable",
    time: "2 hrs ago",
  },
];

function AnimatedNumber({ value, duration = 900 }) {
  const [displayValue, setDisplayValue] = useState(0);

  useEffect(() => {
    let start = 0;
    const increment = value / (duration / 30);

    const timer = setInterval(() => {
      start += increment;

      if (start >= value) {
        setDisplayValue(value);
        clearInterval(timer);
      } else {
        setDisplayValue(Math.floor(start));
      }
    }, 30);

    return () => clearInterval(timer);
  }, [value, duration]);

  return <>{displayValue.toLocaleString()}</>;
}

function StatCard({ icon: Icon, title, value, subtitle, className = "" }) {
  return (
    <div className={`dashboard-stat-card ${className}`}>
      <div className="stat-card-top">
        <div className="stat-icon">
          <Icon size={21} />
        </div>
      </div>

      <div className="stat-value">
        <AnimatedNumber value={value} />
      </div>

      <div className="stat-title">{title}</div>
      <div className="stat-subtitle">{subtitle}</div>
    </div>
  );
}

function Dashboard() {
  const navigate = useNavigate();
  const { screeningsHistory, resetScreening } = useScreening();
  const [selectedGrade, setSelectedGrade] = useState(null);

  const recentList = screeningsHistory && screeningsHistory.length > 0 ? screeningsHistory.slice(0, 6) : recentScreenings;

  const totalPatients = gradeData.reduce((sum, item) => sum + item.count, 0);
  const drPatients = totalPatients - gradeData[0].count;
  const referable = gradeData
    .filter((item) => Number(item.grade.split(" ")[1]) >= 2)
    .reduce((sum, item) => sum + item.count, 0);

  const handleBarClick = (data) => {
    if (data && data.activePayload?.length) {
      const clickedGrade = data.activePayload[0].payload;
      setSelectedGrade(clickedGrade);
    }
  };

  return (
    <div className="dashboard-page">

      {/* Header */}
      <div className="dashboard-header">
        <div>
          <h1>Dashboard</h1>
          <p>Overview of NETRA diabetic retinopathy screening activity</p>
        </div>

        <button
          className="primary-button"
          onClick={() => {
            resetScreening();
            navigate("/screening");
          }}
        >
          <ScanEye size={18} />
          New Screening
        </button>
      </div>

      {/* Demo Data Notice */}
      <div className="demo-notice">
        <AlertTriangle size={18} />
        <span>
          <strong>Demo Mode:</strong> Dashboard statistics are sample values
          for interface demonstration and are not clinical performance results.
        </span>
      </div>

      {/* Main Stats */}
      <div className="dashboard-stats">

        <StatCard
          icon={Users}
          title="Patients Screened"
          value={totalPatients}
          subtitle="Total screenings"
        />

        <StatCard
          icon={Activity}
          title="Patients with DR"
          value={drPatients}
          subtitle={`${Math.round((drPatients / totalPatients) * 100)}% of screened patients`}
        />

        <StatCard
          icon={AlertTriangle}
          title="Referable DR"
          value={referable}
          subtitle="ICDR Grade 2+"
          className="stat-alert"
        />

        <StatCard
          icon={Clock3}
          title="Pending Review"
          value={11}
          subtitle="Awaiting doctor review"
          className="stat-pending"
        />

      </div>

      {/* Main Grid */}
      <div className="dashboard-main-grid">

        {/* DR Distribution */}
        <div className="dashboard-card distribution-card">

          <div className="card-header">
            <div>
              <h2>DR Diagnosis Distribution</h2>
              <p>Patients grouped by ICDR severity level</p>
            </div>

            {selectedGrade && (
              <button
                className="clear-selection"
                onClick={() => setSelectedGrade(null)}
              >
                Clear
              </button>
            )}
          </div>

          <div className="chart-container">
            <ResponsiveContainer width="100%" height={320}>
              <BarChart
                data={gradeData}
                onClick={handleBarClick}
                margin={{
                  top: 10,
                  right: 10,
                  left: 0,
                  bottom: 10,
                }}
              >
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                />

                <XAxis
                  dataKey="grade"
                  tick={{ fontSize: 12 }}
                />

                <YAxis
                  allowDecimals={false}
                  tick={{ fontSize: 12 }}
                />

                <Tooltip
                  cursor={{ opacity: 0.08 }}
                  formatter={(value, name, props) => [
                    `${value} patients`,
                    props.payload.label,
                  ]}
                />

                <Bar
                  dataKey="count"
                  fill="#008EA0"
                  radius={[7, 7, 0, 0]}
                  cursor="pointer"
                />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {selectedGrade && (
            <div className="selected-grade">
              <div>
                <strong>
                  {selectedGrade.grade}: {selectedGrade.label}
                </strong>
                <span>
                  {selectedGrade.count} patients
                </span>
              </div>

              <div className="selected-percentage">
                {((selectedGrade.count / totalPatients) * 100).toFixed(1)}%
              </div>
            </div>
          )}

        </div>

        {/* Referral Summary */}
        <div className="dashboard-card referral-card">

          <div className="card-header">
            <div>
              <h2>Referral Summary</h2>
              <p>Screening outcome overview</p>
            </div>
          </div>

          <div className="referral-summary">

            <div className="referral-number">
              <strong>{referable}</strong>
              <span>Referable</span>
            </div>

            <div className="referral-number">
              <strong>{gradeData[0].count + gradeData[1].count}</strong>
              <span>Non-Referable</span>
            </div>

          </div>

          <div className="referral-bar">
            <div
              className="referral-fill"
              style={{
                width: `${(referable / totalPatients) * 100}%`,
              }}
            />
          </div>

          <div className="referral-legend">
            <span>
              <i className="legend-dot referable-dot"></i>
              Referable · Grade 2+
            </span>

            <span>
              <i className="legend-dot nonreferable-dot"></i>
              Non-Referable
            </span>
          </div>

          <div className="referral-message">
            <AlertTriangle size={17} />
            <span>
              Patients with Grade 2 or above should be considered for
              referral according to the screening workflow.
            </span>
          </div>

        </div>

      </div>

      {/* Bottom Grid */}
      <div className="dashboard-bottom-grid">

        {/* Recent Screenings */}
        <div className="dashboard-card recent-card">

          <div className="card-header">
            <div>
              <h2>Recent Screenings</h2>
              <p>Latest patients processed by NETRA</p>
            </div>

            <button
              className="text-button"
              onClick={() => navigate("/reports")}
            >
              View all
              <ArrowRight size={16} />
            </button>
          </div>

          <div className="recent-table-wrapper">
            <table className="recent-table">
              <thead>
                <tr>
                  <th>Patient</th>
                  <th>ICDR Grade</th>
                  <th>Diagnosis</th>
                  <th>Status</th>
                  <th>Time</th>
                </tr>
              </thead>

              <tbody>
                {recentList.map((screening) => (
                  <tr key={screening.id}>
                    <td>
                      <div className="patient-cell">
                        <div className="patient-avatar">
                          {screening.patient.charAt(0)}
                        </div>

                        <div>
                          <strong>{screening.patient}</strong>
                          <span>
                            {screening.id} · {screening.age} yrs
                          </span>
                        </div>
                      </div>
                    </td>

                    <td>
                      <span className={`grade-badge grade-${screening.grade}`}>
                        Grade {screening.grade}
                      </span>
                    </td>

                    <td>{screening.diagnosis}</td>

                    <td>
                      <span
                        className={
                          screening.status === "Referable"
                            ? "status-badge referable"
                            : "status-badge non-referable"
                        }
                      >
                        {screening.status}
                      </span>
                    </td>

                    <td className="time-cell">{screening.time}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

        </div>

        {/* Pipeline Status */}
        <div className="dashboard-card pipeline-card">

          <div className="card-header">
            <div>
              <h2>AI Pipeline</h2>
              <p>NETRA system status</p>
            </div>

            <span className="online-badge">
              <span></span>
              Online
            </span>
          </div>

          <div className="pipeline-list">

            <div className="pipeline-item">
              <CheckCircle2 size={19} />
              <div>
                <strong>Image Quality Assessment</strong>
                <span>Ready</span>
              </div>
            </div>

            <div className="pipeline-item">
              <CheckCircle2 size={19} />
              <div>
                <strong>Retinal Segmentation</strong>
                <span>Ready</span>
              </div>
            </div>

            <div className="pipeline-item">
              <CheckCircle2 size={19} />
              <div>
                <strong>DR Classification</strong>
                <span>Ready</span>
              </div>
            </div>

            <div className="pipeline-item">
              <CheckCircle2 size={19} />
              <div>
                <strong>Explainability Engine</strong>
                <span>Ready</span>
              </div>
            </div>

          </div>

          <button
            className="pipeline-button"
            onClick={() => navigate("/simulation")}
          >
            Open Pipeline Simulation
            <ArrowRight size={16} />
          </button>

        </div>

      </div>

    </div>
  );
}

export default Dashboard;