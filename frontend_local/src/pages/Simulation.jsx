import { useEffect, useState } from "react";
import {
  Activity,
  ArrowRight,
  Brain,
  CheckCircle2,
  Clock3,
  Gauge,
  Play,
  RotateCcw,
  Server,
  Users,
  Wifi,
  XCircle,
} from "lucide-react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

const initialChartData = [
  { time: "0", arrivals: 0, processed: 0, queue: 0 },
  { time: "10", arrivals: 18, processed: 15, queue: 3 },
  { time: "20", arrivals: 37, processed: 32, queue: 5 },
  { time: "30", arrivals: 56, processed: 48, queue: 8 },
  { time: "40", arrivals: 74, processed: 67, queue: 7 },
  { time: "50", arrivals: 91, processed: 84, queue: 7 },
];

function MetricCard({ icon: Icon, title, value, unit, subtitle }) {
  return (
    <div className="simulation-metric-card">
      <div className="simulation-metric-icon">
        <Icon size={20} />
      </div>

      <div className="simulation-metric-content">
        <span>{title}</span>
        <strong>
          {value} {unit && <small>{unit}</small>}
        </strong>
        <p>{subtitle}</p>
      </div>
    </div>
  );
}

function PipelineNode({ icon: Icon, title, subtitle, status, active }) {
  return (
    <div className={`pipeline-node ${active ? "active" : ""}`}>
      <div className="pipeline-node-icon">
        <Icon size={21} />
      </div>

      <div className="pipeline-node-text">
        <strong>{title}</strong>
        <span>{subtitle}</span>
      </div>

      <div className={`pipeline-status ${status}`}>
        {status === "ready" ? (
          <CheckCircle2 size={14} />
        ) : (
          <Activity size={14} />
        )}
        {status === "ready" ? "Ready" : "Processing"}
      </div>
    </div>
  );
}

function Simulation() {
  const [running, setRunning] = useState(false);
  const [completed, setCompleted] = useState(false);

  const [patients, setPatients] = useState(100000);
  const [aiStations, setAiStations] = useState(4);
  const [doctors, setDoctors] = useState(3);
  const [aiTime, setAiTime] = useState(25);
  const [reviewTime, setReviewTime] = useState(120);
  const [bandwidth, setBandwidth] = useState(10);

  const [progress, setProgress] = useState(0);
  const [processed, setProcessed] = useState(0);
  const [queue, setQueue] = useState(0);

  const [chartData, setChartData] = useState(initialChartData);

  useEffect(() => {
    if (!running) return;

    const interval = setInterval(() => {
      setProgress((prev) => {
        const next = prev + 2;

        if (next >= 100) {
          setRunning(false);
          setCompleted(true);
          return 100;
        }

        return next;
      });

      setProcessed((prev) => {
        const next = Math.min(
          patients,
          Math.floor((progress / 100) * patients)
        );

        return next;
      });

      setQueue((prev) => {
        const next = Math.max(
          0,
          Math.floor(
            (patients / 10000) *
              (doctors < 3 ? 1.8 : 1.1) *
              (Math.random() * 4)
          )
        );

        return next;
      });
    }, 120);

    return () => clearInterval(interval);
  }, [running, progress, patients, doctors]);

  useEffect(() => {
    if (!running) return;

    setChartData((prev) => {
      const nextTime =
        Number(prev[prev.length - 1]?.time || 0) + 10;

      const newPoint = {
        time: String(nextTime),
        arrivals: Math.floor(Math.random() * 20) + 70,
        processed: Math.floor(Math.random() * 18) + 65,
        queue: Math.floor(Math.random() * 12) + 2,
      };

      return [...prev.slice(-7), newPoint];
    });
  }, [progress, running]);

  const startSimulation = () => {
    setProgress(0);
    setProcessed(0);
    setQueue(0);
    setCompleted(false);
    setChartData(initialChartData);
    setRunning(true);
  };

  const resetSimulation = () => {
    setRunning(false);
    setCompleted(false);
    setProgress(0);
    setProcessed(0);
    setQueue(0);
    setChartData(initialChartData);
  };

  const aiThroughput = Math.round(
    (3600 / aiTime) * aiStations
  );

  const doctorThroughput = Math.round(
    (3600 / reviewTime) * doctors
  );

  const utilization = Math.min(
    99,
    Math.round((queue / Math.max(1, doctors * 3)) * 100)
  );

  return (
    <div className="simulation-page">

      {/* Header */}
      <div className="simulation-header">
        <div>
          <div className="simulation-title-row">
            <Activity size={25} />
            <h1>Telemedicine Simulation</h1>
          </div>

          <p>
            Simulate NETRA's rural diabetic retinopathy screening
            pipeline and healthcare resource capacity.
          </p>
        </div>

        <div className="simulation-actions">
          <button
            className="simulation-reset"
            onClick={resetSimulation}
          >
            <RotateCcw size={16} />
            Reset
          </button>

          <button
            className={`simulation-run ${
              running ? "running" : ""
            }`}
            onClick={startSimulation}
            disabled={running}
          >
            {running ? (
              <>
                <Activity size={17} />
                Simulation Running
              </>
            ) : (
              <>
                <Play size={17} />
                Run Simulation
              </>
            )}
          </button>
        </div>
      </div>

      {/* Demo Notice */}
      <div className="simulation-notice">
        <Activity size={18} />
        <div>
          <strong>Frontend Simulation Mode</strong>
          <span>
            These results are simulated for interface demonstration.
            The actual Simulink/SimEvents model will be connected later.
          </span>
        </div>
      </div>

      {/* Controls */}
      <div className="simulation-layout">

        <div className="simulation-controls-card">

          <div className="simulation-card-heading">
            <div>
              <h2>Simulation Parameters</h2>
              <p>Configure the telemedicine workload</p>
            </div>
          </div>

          <div className="simulation-form">

            <label>
              Annual Patients
              <input
                type="number"
                value={patients}
                onChange={(e) =>
                  setPatients(Number(e.target.value))
                }
                min="1000"
              />
              <span>patients / year</span>
            </label>

            <label>
              AI Screening Stations
              <input
                type="number"
                value={aiStations}
                onChange={(e) =>
                  setAiStations(Number(e.target.value))
                }
                min="1"
                max="50"
              />
              <span>stations</span>
            </label>

            <label>
              Doctors / Reviewers
              <input
                type="number"
                value={doctors}
                onChange={(e) =>
                  setDoctors(Number(e.target.value))
                }
                min="1"
                max="50"
              />
              <span>reviewers</span>
            </label>

            <label>
              AI Processing Time
              <input
                type="number"
                value={aiTime}
                onChange={(e) =>
                  setAiTime(Number(e.target.value))
                }
                min="1"
              />
              <span>seconds / image</span>
            </label>

            <label>
              Doctor Review Time
              <input
                type="number"
                value={reviewTime}
                onChange={(e) =>
                  setReviewTime(Number(e.target.value))
                }
                min="10"
              />
              <span>seconds / case</span>
            </label>

            <label>
              Network Bandwidth
              <input
                type="number"
                value={bandwidth}
                onChange={(e) =>
                  setBandwidth(Number(e.target.value))
                }
                min="1"
              />
              <span>Mbps</span>
            </label>

          </div>

          <div className="simulation-capacity">
            <div>
              <span>Estimated AI capacity</span>
              <strong>
                {aiThroughput.toLocaleString()} cases/hr
              </strong>
            </div>

            <div>
              <span>Estimated review capacity</span>
              <strong>
                {doctorThroughput.toLocaleString()} cases/hr
              </strong>
            </div>
          </div>

        </div>

        {/* Live Status */}
        <div className="simulation-status-card">

          <div className="simulation-card-heading">
            <div>
              <h2>Simulation Status</h2>
              <p>Current system state</p>
            </div>

            <span
              className={`simulation-state ${
                running
                  ? "state-running"
                  : completed
                  ? "state-complete"
                  : "state-ready"
              }`}
            >
              {running
                ? "Running"
                : completed
                ? "Completed"
                : "Ready"}
            </span>
          </div>

          <div className="simulation-progress">
            <div className="progress-label">
              <span>Simulation progress</span>
              <strong>{progress}%</strong>
            </div>

            <div className="simulation-progress-bar">
              <div
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>

          <div className="simulation-live-grid">
            <div>
              <span>Processed</span>
              <strong>{processed.toLocaleString()}</strong>
            </div>

            <div>
              <span>In Queue</span>
              <strong>{queue}</strong>
            </div>

            <div>
              <span>Bandwidth</span>
              <strong>{bandwidth} Mbps</strong>
            </div>

            <div>
              <span>Utilization</span>
              <strong>{utilization}%</strong>
            </div>
          </div>

        </div>

      </div>

      {/* Pipeline */}
      <div className="simulation-card pipeline-card-large">

        <div className="simulation-card-heading">
          <div>
            <h2>Telemedicine Pipeline</h2>
            <p>
              End-to-end patient screening and referral workflow
            </p>
          </div>
        </div>

        <div className="simulation-pipeline">

          <PipelineNode
            icon={Users}
            title="Patients"
            subtitle="Rural PHCs"
            status="ready"
            active={running}
          />

          <ArrowRight className="pipeline-arrow" />

          <PipelineNode
            icon={Wifi}
            title="Image Upload"
            subtitle={`${bandwidth} Mbps`}
            status="ready"
            active={running}
          />

          <ArrowRight className="pipeline-arrow" />

          <PipelineNode
            icon={Gauge}
            title="IQA"
            subtitle="Quality check"
            status="ready"
            active={running}
          />

          <ArrowRight className="pipeline-arrow" />

          <PipelineNode
            icon={Brain}
            title="AI Analysis"
            subtitle={`${aiTime}s / image`}
            status="ready"
            active={running}
          />

          <ArrowRight className="pipeline-arrow" />

          <PipelineNode
            icon={Clock3}
            title="Review Queue"
            subtitle={`${queue} waiting`}
            status={queue > 0 ? "processing" : "ready"}
            active={running}
          />

          <ArrowRight className="pipeline-arrow" />

          <PipelineNode
            icon={Server}
            title="Doctor Review"
            subtitle={`${doctors} reviewers`}
            status="ready"
            active={running}
          />

        </div>

      </div>

      {/* Metrics */}
      <div className="simulation-metrics-grid">

        <MetricCard
          icon={Activity}
          title="AI Throughput"
          value={aiThroughput}
          unit="cases/hr"
          subtitle={`${aiStations} active AI stations`}
        />

        <MetricCard
          icon={Users}
          title="Review Capacity"
          value={doctorThroughput}
          unit="cases/hr"
          subtitle={`${doctors} doctors`}
        />

        <MetricCard
          icon={Clock3}
          title="Average Review Time"
          value={reviewTime}
          unit="sec"
          subtitle="Per referable case"
        />

        <MetricCard
          icon={Gauge}
          title="System Utilization"
          value={utilization}
          unit="%"
          subtitle="Current simulated load"
        />

      </div>

      {/* Chart */}
      <div className="simulation-card simulation-chart-card">

        <div className="simulation-card-heading">
          <div>
            <h2>Patient Flow & Queue</h2>
            <p>
              Simulated arrivals, processed cases and queue length
            </p>
          </div>
        </div>

        <div className="simulation-chart">
          <ResponsiveContainer width="100%" height={320}>
            <AreaChart data={chartData}>

              <CartesianGrid
                strokeDasharray="3 3"
                vertical={false}
              />

              <XAxis
                dataKey="time"
                tick={{ fontSize: 11 }}
                label={{
                  value: "Simulation Time",
                  position: "insideBottom",
                  offset: -5,
                }}
              />

              <YAxis
                tick={{ fontSize: 11 }}
              />

              <Tooltip />

              <Area
                type="monotone"
                dataKey="arrivals"
                stroke="#008EA0"
                fill="#008EA0"
                fillOpacity={0.12}
                name="Arrivals"
              />

              <Area
                type="monotone"
                dataKey="processed"
                stroke="#085979"
                fill="#085979"
                fillOpacity={0.08}
                name="Processed"
              />

              <Area
                type="monotone"
                dataKey="queue"
                stroke="#D4343F"
                fill="#D4343F"
                fillOpacity={0.08}
                name="Queue"
              />

            </AreaChart>
          </ResponsiveContainer>
        </div>

      </div>

      {/* Simulink Integration */}
      <div className="simulink-info">

        <div className="simulink-icon">
          <Activity size={23} />
        </div>

        <div>
          <h3>MATLAB / Simulink Integration</h3>
          <p>
            This interface is designed to receive simulation outputs
            from the NETRA Simulink/SimEvents model. The backend will
            later send patient arrival, queue, throughput, bandwidth
            and resource-utilization metrics to this page.
          </p>
        </div>

        <span className="integration-badge">
          Frontend Ready
        </span>

      </div>

    </div>
  );
}

export default Simulation;