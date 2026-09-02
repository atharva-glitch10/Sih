import {
  FileText,
  Download,
  Search,
  Calendar,
  CheckCircle2,
  Eye,
} from "lucide-react";

function Reports() {
  const reports = [
    {
      id: "NETRA-2026-0842",
      patient: "Demo Patient",
      age: 58,
      grade: 2,
      diagnosis: "Moderate NPDR",
      status: "Referable",
      date: "02 Sep 2026",
    },
    {
      id: "NETRA-2026-0841",
      patient: "Patient A",
      age: 64,
      grade: 1,
      diagnosis: "Mild NPDR",
      status: "Non-Referable",
      date: "02 Sep 2026",
    },
    {
      id: "NETRA-2026-0840",
      patient: "Patient B",
      age: 52,
      grade: 0,
      diagnosis: "No DR",
      status: "Non-Referable",
      date: "01 Sep 2026",
    },
    {
      id: "NETRA-2026-0839",
      patient: "Patient C",
      age: 67,
      grade: 3,
      diagnosis: "Severe NPDR",
      status: "Referable",
      date: "01 Sep 2026",
    },
  ];

  return (
    <div className="reports-page">

      {/* Header */}
      <div className="reports-header">
        <div>
          <p className="page-label">CLINICAL REPORTS</p>

          <h2> Screening Reports</h2>

          <p>
            View and export completed NETRA screening reports.
          </p>
        </div>

        <button
          className="primary-button"
          onClick={() => navigate("/report-generation")}
        >
        <FileText size={18} />
         Generate Report
        </button>
      </div>

      {/* Statistics */}
      <div className="report-stats">

        <ReportStat
          title="Total Reports"
          value="1,284"
        />

        <ReportStat
          title="Referable DR"
          value="284"
          danger
        />

        <ReportStat
          title="Non-Referable"
          value="989"
        />

        <ReportStat
          title="Pending Review"
          value="11"
        />

      </div>

      {/* Search / Filters */}
      <div className="report-toolbar">

        <div className="report-search">
          <Search size={17} />

          <input
            type="text"
            placeholder="Search patient or screening ID..."
          />
        </div>

        <button className="filter-button">
          <Calendar size={16} />
          Date
        </button>

        <button className="filter-button">
          All Grades
        </button>

        <button className="filter-button">
          All Status
        </button>

      </div>

      {/* Reports table */}
      <div className="reports-card">

        <div className="reports-card-header">
          <div>
            <h3>Completed Screenings</h3>
            <p>Recently generated clinical reports</p>
          </div>

          <span className="report-count">
            {reports.length} shown
          </span>
        </div>

        <div className="reports-table-wrapper">

          <table className="reports-table">

            <thead>
              <tr>
                <th>Screening ID</th>
                <th>Patient</th>
                <th>ICDR Grade</th>
                <th>Diagnosis</th>
                <th>Referral</th>
                <th>Date</th>
                <th>Actions</th>
              </tr>
            </thead>

            <tbody>

              {reports.map((report) => (
                <tr key={report.id}>

                  <td>
                    <strong className="screening-id">
                      {report.id}
                    </strong>
                  </td>

                  <td>
                    <div className="report-patient">
                      <strong>{report.patient}</strong>
                      <span>
                        {report.age} years
                      </span>
                    </div>
                  </td>

                  <td>
                    <span
                      className={`grade-badge grade-${report.grade}`}
                    >
                      Grade {report.grade}
                    </span>
                  </td>

                  <td>
                    <span className="diagnosis-text">
                      {report.diagnosis}
                    </span>
                  </td>

                  <td>
                    <span
                      className={
                        report.status === "Referable"
                          ? "referral-badge referable"
                          : "referral-badge non-referable"
                      }
                    >
                      {report.status}
                    </span>
                  </td>

                  <td>
                    <span className="report-date">
                      {report.date}
                    </span>
                  </td>

                  <td>

                    <div className="report-actions">

                      <button
                        className="icon-button"
                        title="View Report"
                      >
                        <Eye size={16} />
                      </button>

                      <button
                        className="icon-button"
                        title="Download Report"
                      >
                        <Download size={16} />
                      </button>

                    </div>

                  </td>

                </tr>
              ))}

            </tbody>

          </table>

        </div>
      </div>

      {/* Report information */}
      <div className="report-info">

        <div className="report-info-icon">
          <CheckCircle2 size={20} />
        </div>

        <div>
          <strong>Clinical Report Format</strong>

          <p>
            Each report contains patient information, image quality
            assessment, ICDR grade, lesion evidence, AI confidence,
            explainability information, doctor review and referral
            recommendation.
          </p>
        </div>

      </div>

    </div>
  );
}

function ReportStat({ title, value, danger = false }) {
  return (
    <div className="report-stat">
      <span>{title}</span>

      <strong className={danger ? "danger-number" : ""}>
        {value}
      </strong>
    </div>
  );
}

export default Reports;