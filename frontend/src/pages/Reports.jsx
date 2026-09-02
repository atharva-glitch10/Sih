import { useState } from "react";
import {
  FileText,
  Download,
  Search,
  Calendar,
  CheckCircle2,
  Eye,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useScreening } from "../context/ScreeningContext";

function Reports() {
  const navigate = useNavigate();
  const { screeningsHistory } = useScreening();
  const [searchTerm, setSearchTerm] = useState("");

  const allReports = screeningsHistory || [];
  const reports = allReports.filter(r => 
    (r.patient && r.patient.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (r.id && r.id.toLowerCase().includes(searchTerm.toLowerCase())) ||
    (r.diagnosis && r.diagnosis.toLowerCase().includes(searchTerm.toLowerCase()))
  );

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
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
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
                        title="View Clinical Report (HTML)"
                        onClick={() => window.open(`/api/reports/${report.id}`, '_blank')}
                      >
                        <Eye size={16} />
                      </button>

                      <button
                        className="icon-button"
                        title="Download / Print Report"
                        onClick={() => window.open(`/api/reports/${report.id}`, '_blank')}
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