import { useMemo, useState } from "react";
import {
  AlertTriangle,
  Calendar,
  Eye,
  Filter,
  Search,
  ScanEye,
  UserRound,
  X,
} from "lucide-react";
import { useNavigate } from "react-router-dom";

const patientsData = [
  {
    id: "NETRA-2026-0842",
    name: "Demo Patient",
    age: 58,
    gender: "Female",
    phc: "Rural PHC Shirwal",
    grade: 2,
    diagnosis: "Moderate NPDR",
    referral: "Referable",
    date: "02 Sep 2026",
    confidence: 89.4,
  },
  {
    id: "NETRA-2026-0841",
    name: "Patient A",
    age: 64,
    gender: "Male",
    phc: "PHC Khed",
    grade: 1,
    diagnosis: "Mild NPDR",
    referral: "Non-Referable",
    date: "02 Sep 2026",
    confidence: 91.8,
  },
  {
    id: "NETRA-2026-0840",
    name: "Patient B",
    age: 52,
    gender: "Female",
    phc: "PHC Bhor",
    grade: 0,
    diagnosis: "No DR",
    referral: "Non-Referable",
    date: "01 Sep 2026",
    confidence: 96.2,
  },
  {
    id: "NETRA-2026-0839",
    name: "Patient C",
    age: 67,
    gender: "Male",
    phc: "Rural PHC Shirwal",
    grade: 3,
    diagnosis: "Severe NPDR",
    referral: "Referable",
    date: "01 Sep 2026",
    confidence: 94.5,
  },
  {
    id: "NETRA-2026-0838",
    name: "Patient D",
    age: 61,
    gender: "Female",
    phc: "PHC Khed",
    grade: 4,
    diagnosis: "Proliferative DR",
    referral: "Referable",
    date: "31 Aug 2026",
    confidence: 97.1,
  },
  {
    id: "NETRA-2026-0837",
    name: "Patient E",
    age: 49,
    gender: "Male",
    phc: "PHC Bhor",
    grade: 0,
    diagnosis: "No DR",
    referral: "Non-Referable",
    date: "31 Aug 2026",
    confidence: 95.4,
  },
  {
    id: "NETRA-2026-0836",
    name: "Patient F",
    age: 56,
    gender: "Female",
    phc: "Rural PHC Shirwal",
    grade: 2,
    diagnosis: "Moderate NPDR",
    referral: "Referable",
    date: "30 Aug 2026",
    confidence: 88.7,
  },
  {
    id: "NETRA-2026-0835",
    name: "Patient G",
    age: 70,
    gender: "Male",
    phc: "PHC Khed",
    grade: 1,
    diagnosis: "Mild NPDR",
    referral: "Non-Referable",
    date: "30 Aug 2026",
    confidence: 90.3,
  },
];

const gradeLabels = {
  0: "No DR",
  1: "Mild NPDR",
  2: "Moderate NPDR",
  3: "Severe NPDR",
  4: "Proliferative DR",
};

function Patients() {
  const navigate = useNavigate();

  const [search, setSearch] = useState("");
  const [gradeFilter, setGradeFilter] = useState("All");
  const [referralFilter, setReferralFilter] = useState("All");
  const [selectedPatient, setSelectedPatient] = useState(null);

  const filteredPatients = useMemo(() => {
    return patientsData.filter((patient) => {
      const searchMatch =
        patient.name.toLowerCase().includes(search.toLowerCase()) ||
        patient.id.toLowerCase().includes(search.toLowerCase()) ||
        patient.phc.toLowerCase().includes(search.toLowerCase());

      const gradeMatch =
        gradeFilter === "All" ||
        patient.grade === Number(gradeFilter);

      const referralMatch =
        referralFilter === "All" ||
        patient.referral === referralFilter;

      return searchMatch && gradeMatch && referralMatch;
    });
  }, [search, gradeFilter, referralFilter]);

  const clearFilters = () => {
    setSearch("");
    setGradeFilter("All");
    setReferralFilter("All");
  };

  return (
    <div className="patients-page">

      {/* Header */}
      <div className="patients-header">
        <div>
          <h1>Patients</h1>
          <p>
            View and manage patients screened through the NETRA system
          </p>
        </div>

        <button
          className="primary-button"
          onClick={() => navigate("/screening")}
        >
          <ScanEye size={18} />
          New Screening
        </button>
      </div>

      {/* Demo Notice */}
      <div className="patients-demo-notice">
        <AlertTriangle size={17} />
        <span>
          <strong>Demo Data:</strong> Patient records shown here are
          sample records for frontend demonstration.
        </span>
      </div>

      {/* Summary Cards */}
      <div className="patient-summary-grid">

        <div className="patient-summary-card">
          <div className="patient-summary-icon">
            <UserRound size={20} />
          </div>
          <div>
            <span>Total Patients</span>
            <strong>1,284</strong>
          </div>
        </div>

        <div className="patient-summary-card">
          <div className="patient-summary-icon referral-icon">
            <AlertTriangle size={20} />
          </div>
          <div>
            <span>Referable</span>
            <strong>284</strong>
          </div>
        </div>

        <div className="patient-summary-card">
          <div className="patient-summary-icon">
            <Calendar size={20} />
          </div>
          <div>
            <span>Screened Today</span>
            <strong>24</strong>
          </div>
        </div>

        <div className="patient-summary-card">
          <div className="patient-summary-icon">
            <ScanEye size={20} />
          </div>
          <div>
            <span>AI Screenings</span>
            <strong>1,273</strong>
          </div>
        </div>

      </div>

      {/* Patient Table Card */}
      <div className="patients-card">

        {/* Toolbar */}
        <div className="patients-toolbar">

          <div className="patient-search">
            <Search size={17} />
            <input
              type="text"
              placeholder="Search patient name, ID or PHC..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <div className="patient-filters">

            <div className="filter-control">
              <Filter size={15} />

              <select
                value={gradeFilter}
                onChange={(e) => setGradeFilter(e.target.value)}
              >
                <option value="All">All Grades</option>
                <option value="0">Grade 0</option>
                <option value="1">Grade 1</option>
                <option value="2">Grade 2</option>
                <option value="3">Grade 3</option>
                <option value="4">Grade 4</option>
              </select>
            </div>

            <select
              className="referral-filter"
              value={referralFilter}
              onChange={(e) =>
                setReferralFilter(e.target.value)
              }
            >
              <option value="All">All Status</option>
              <option value="Referable">Referable</option>
              <option value="Non-Referable">
                Non-Referable
              </option>
            </select>

            {(search ||
              gradeFilter !== "All" ||
              referralFilter !== "All") && (
              <button
                className="clear-filters"
                onClick={clearFilters}
              >
                Clear
              </button>
            )}

          </div>

        </div>

        {/* Result Count */}
        <div className="patients-result-info">
          Showing{" "}
          <strong>{filteredPatients.length}</strong>{" "}
          of <strong>{patientsData.length}</strong> demo records
        </div>

        {/* Table */}
        <div className="patients-table-wrapper">
          <table className="patients-table">

            <thead>
              <tr>
                <th>Patient</th>
                <th>Patient ID</th>
                <th>PHC / Location</th>
                <th>ICDR Grade</th>
                <th>Diagnosis</th>
                <th>Referral</th>
                <th>Screened</th>
                <th>Action</th>
              </tr>
            </thead>

            <tbody>

              {filteredPatients.length > 0 ? (
                filteredPatients.map((patient) => (
                  <tr key={patient.id}>

                    <td>
                      <div className="patient-name-cell">
                        <div className="patient-avatar-large">
                          {patient.name.charAt(0)}
                        </div>

                        <div>
                          <strong>{patient.name}</strong>
                          <span>
                            {patient.age} yrs · {patient.gender}
                          </span>
                        </div>
                      </div>
                    </td>

                    <td>
                      <span className="patient-id">
                        {patient.id}
                      </span>
                    </td>

                    <td>{patient.phc}</td>

                    <td>
                      <span
                        className={`grade-badge grade-${patient.grade}`}
                      >
                        Grade {patient.grade}
                      </span>
                    </td>

                    <td>
                      <span className="diagnosis-text">
                        {patient.diagnosis}
                      </span>
                    </td>

                    <td>
                      <span
                        className={
                          patient.referral === "Referable"
                            ? "status-badge referable"
                            : "status-badge non-referable"
                        }
                      >
                        {patient.referral}
                      </span>
                    </td>

                    <td className="patient-date">
                      {patient.date}
                    </td>

                    <td>
                      <button
                        className="view-patient-button"
                        onClick={() =>
                          setSelectedPatient(patient)
                        }
                        title="View patient"
                      >
                        <Eye size={16} />
                      </button>
                    </td>

                  </tr>
                ))
              ) : (
                <tr>
                  <td
                    colSpan="8"
                    className="no-patients"
                  >
                    <Search size={28} />
                    <strong>No patients found</strong>
                    <span>
                      Try changing your search or filters.
                    </span>
                  </td>
                </tr>
              )}

            </tbody>

          </table>
        </div>

      </div>

      {/* Patient Details Modal */}
      {selectedPatient && (
        <div
          className="patient-modal-overlay"
          onClick={() => setSelectedPatient(null)}
        >
          <div
            className="patient-modal"
            onClick={(e) => e.stopPropagation()}
          >

            <div className="patient-modal-header">
              <div>
                <h2>Patient Details</h2>
                <p>{selectedPatient.id}</p>
              </div>

              <button
                className="modal-close"
                onClick={() => setSelectedPatient(null)}
              >
                <X size={19} />
              </button>
            </div>

            <div className="patient-modal-profile">
              <div className="patient-avatar-large modal-avatar">
                {selectedPatient.name.charAt(0)}
              </div>

              <div>
                <h3>{selectedPatient.name}</h3>
                <span>
                  {selectedPatient.age} years ·{" "}
                  {selectedPatient.gender}
                </span>
              </div>
            </div>

            <div className="patient-details-grid">

              <div>
                <span>PHC / Location</span>
                <strong>{selectedPatient.phc}</strong>
              </div>

              <div>
                <span>Screening Date</span>
                <strong>{selectedPatient.date}</strong>
              </div>

              <div>
                <span>ICDR Grade</span>
                <strong>
                  Grade {selectedPatient.grade}
                </strong>
              </div>

              <div>
                <span>Diagnosis</span>
                <strong>
                  {gradeLabels[selectedPatient.grade]}
                </strong>
              </div>

              <div>
                <span>AI Confidence</span>
                <strong>
                  {selectedPatient.confidence}%
                </strong>
              </div>

              <div>
                <span>Referral Status</span>
                <strong
                  className={
                    selectedPatient.referral === "Referable"
                      ? "modal-referable"
                      : "modal-nonreferable"
                  }
                >
                  {selectedPatient.referral}
                </strong>
              </div>

            </div>

            <div className="patient-modal-actions">
              <button
                className="secondary-button"
                onClick={() => setSelectedPatient(null)}
              >
                Close
              </button>

              <button
                className="primary-button"
                onClick={() => {
                  setSelectedPatient(null);
                  navigate("/results");
                }}
              >
                View Screening Result
                <Eye size={16} />
              </button>
            </div>

          </div>
        </div>
      )}

    </div>
  );
}

export default Patients;