import React from 'react';

export default function PatientDiagnosticCard({ data }) {
  if (!data) return <div style={{padding:'1rem',color:'#718096'}}>No diagnostic data loaded.</div>;

  const isReferrable = data.isReferrable;
  const probs = data.probabilities || [0, 0, 0, 0, 0];
  const bio = data.biomarkers || {};
  const gradeColors = ['#276749', '#2b6cb0', '#d69e2e', '#dd6b20', '#c53030'];
  const grade = data.icdrGrade ?? 0;

  const sev = (v, lo, hi) =>
    v === 0   ? { label: 'None', color: '#276749' } :
    v < lo    ? { label: 'Mild', color: '#d69e2e' } :
    v < hi    ? { label: 'Moderate', color: '#dd6b20' } :
                { label: 'Severe', color: '#c53030' };

  const styles = {
    card: { padding: '24px', background: '#fff', borderRadius: '12px', boxShadow: '0 4px 16px rgba(0,0,0,.08)', border: '1px solid #e2e8f0', maxWidth: '680px', width: '100%', fontFamily: '"Segoe UI", Roboto, Helvetica, sans-serif' },
    header: { display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px', paddingBottom: '14px', borderBottom: '1px solid #e2e8f0' },
    badge: { padding: '5px 14px', borderRadius: '999px', fontSize: '12px', fontWeight: 700, color: '#fff', background: isReferrable ? '#c53030' : '#276749' },
    grid2: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '16px' },
    statBox: { padding: '14px', background: '#f7fafc', borderRadius: '8px', border: '1px solid #e2e8f0' },
    label: { fontSize: '11px', color: '#718096', textTransform: 'uppercase', letterSpacing: '0.5px', fontWeight: 600 },
    bigVal: { fontSize: '20px', fontWeight: 800, marginTop: '4px' },
    small: { fontSize: '11px', color: '#a0aec0', marginTop: '3px' },
    table: { width: '100%', borderCollapse: 'collapse', fontSize: '13px' },
    th: { background: '#ebf4ff', color: '#2b6cb0', fontWeight: 700, padding: '6px 10px', textAlign: 'left', fontSize: '11px', textTransform: 'uppercase' },
    td: { padding: '5px 10px', borderBottom: '1px solid #f0f4f8' },
    sectionTitle: { fontSize: '12px', fontWeight: 700, color: '#2b6cb0', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '8px' },
    btn: { display: 'inline-block', padding: '9px 20px', background: '#2b6cb0', color: '#fff', fontWeight: 600, borderRadius: '7px', textDecoration: 'none', fontSize: '13px', transition: 'background .2s' },
  };

  return (
    <div style={styles.card}>
      {/* Header */}
      <div style={styles.header}>
        <div>
          <div style={{ fontSize: '18px', fontWeight: 800, color: '#1a365d' }}>Patient: {data.patientID}</div>
          <div style={{ fontSize: '12px', color: '#718096', marginTop: '3px' }}>IQA: <b>{data.iqaScore}</b></div>
        </div>
        <span style={styles.badge}>{isReferrable ? '⚠️ REFERRABLE DR' : '✓ NON-REFERRABLE'}</span>
      </div>

      {/* Grade + DME */}
      <div style={styles.grid2}>
        <div style={styles.statBox}>
          <div style={styles.label}>ICDR Severity Grade</div>
          <div style={{ ...styles.bigVal, color: gradeColors[grade] }}>Grade {grade}</div>
          <div style={{ fontSize: '13px', color: '#4a5568', marginTop: '2px' }}>{data.gradeLabel}</div>
          <div style={styles.small}>Confidence: {((data.confidence || 0.94) * 100).toFixed(1)}%</div>
        </div>
        <div style={styles.statBox}>
          <div style={styles.label}>DME Risk Level</div>
          <div style={{ ...styles.bigVal, color: '#dd6b20', fontSize: '15px', marginTop: '6px' }}>{data.dmeRisk || 'N/A'}</div>
          <div style={styles.small}>Score: {data.dmeScore ?? '—'} / 100</div>
          <div style={styles.small}>Diabetic Macular Edema Assessment</div>
        </div>
      </div>

      {/* Probability Bar */}
      <div style={{ marginBottom: '16px' }}>
        <div style={styles.sectionTitle}>Class Probability Distribution (Grades 0–4)</div>
        <div style={{ display: 'flex', gap: '2px', height: '10px', borderRadius: '99px', overflow: 'hidden', background: '#e2e8f0' }}>
          {probs.map((prob, idx) => (
            <div
              key={idx}
              style={{ width: `${Math.max(2, prob * 100)}%`, height: '100%', background: gradeColors[idx] }}
              title={`Grade ${idx}: ${(prob * 100).toFixed(1)}%`}
            />
          ))}
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#a0aec0', marginTop: '3px' }}>
          <span>G0: No DR</span><span>G1: Mild</span><span>G2: Moderate</span><span>G3: Severe</span><span>G4: PDR</span>
        </div>
      </div>

      {/* Biomarkers Table */}
      <div style={{ marginBottom: '16px' }}>
        <div style={styles.sectionTitle}>Explainable Biomarker Quantification</div>
        <table style={styles.table}>
          <thead>
            <tr>
              <th style={styles.th}>Biomarker</th>
              <th style={styles.th}>Value</th>
              <th style={styles.th}>Severity</th>
              <th style={styles.th}>Clinical Note</th>
            </tr>
          </thead>
          <tbody>
            {[
              { name: 'Microaneurysms (MAs)', val: bio.microaneurysms ?? bio.MicroaneurysmsCount ?? 0, lo: 5, hi: 15, note: 'Early capillary leakage' },
              { name: 'Hemorrhages (HMs)', val: bio.hemorrhages ?? bio.HemorrhagesCount ?? 0, lo: 3, hi: 15, note: '4-2-1 Rule indicator' },
              { name: 'Hard Exudates (HE)', val: bio.hardExudatesArea ?? bio.HardExudatesArea ?? 0, lo: 50, hi: 200, note: 'Lipid deposition (px)' },
            ].map((row, i) => {
              const s = sev(row.val, row.lo, row.hi);
              return (
                <tr key={i} style={{ background: i % 2 === 1 ? '#f7fafc' : '#fff' }}>
                  <td style={styles.td}>{row.name}</td>
                  <td style={{ ...styles.td, fontWeight: 700 }}>{row.val}</td>
                  <td style={{ ...styles.td, color: s.color, fontWeight: 600 }}>{s.label}</td>
                  <td style={{ ...styles.td, color: '#718096' }}>{row.note}</td>
                </tr>
              );
            })}
            <tr style={{ background: '#fff' }}>
              <td style={styles.td}>Vessel Density</td>
              <td style={{ ...styles.td, fontWeight: 700 }}>{((bio.vesselDensity ?? bio.VesselDensity ?? 0) * 100).toFixed(1)}%</td>
              <td style={styles.td}>—</td>
              <td style={{ ...styles.td, color: '#718096' }}>Vascular tree coverage</td>
            </tr>
            <tr style={{ background: '#f7fafc' }}>
              <td style={styles.td}>Neovascularization</td>
              <td colSpan={3} style={{ ...styles.td, fontWeight: 700, color: (bio.neovascularization || bio.Neovascularization) ? '#c53030' : '#276749' }}>
                {(bio.neovascularization || bio.Neovascularization) ? 'Detected ⚠️ — Hallmark of Proliferative DR' : 'Not Detected ✓'}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      {/* Report Button */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
        <a
          href={`/api/reports/${data.patientID}`}
          target="_blank"
          rel="noreferrer"
          style={styles.btn}
        >
          📋 View Full Clinical Report
        </a>
      </div>
    </div>
  );
}
