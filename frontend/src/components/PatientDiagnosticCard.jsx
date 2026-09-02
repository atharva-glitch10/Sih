import React from 'react';

export default function PatientDiagnosticCard({ data }) {
  if (!data) return <div className="p-4 text-gray-500">No diagnostic data loaded.</div>;

  const isReferrable = data.isReferrable;
  const probs = data.probabilities || [0, 0, 0, 0, 0];
  
  return (
    <div className="p-6 bg-white rounded-xl shadow-md border border-gray-200 max-w-2xl w-full">
      {/* Header */}
      <div className="flex justify-between items-center mb-4 pb-3 border-b">
        <div>
          <h2 className="text-xl font-bold text-gray-800">Patient: {data.patientID}</h2>
          <span className="text-sm text-gray-500">IQA Status: <strong>{data.iqaScore}</strong></span>
        </div>
        <span className={`px-3 py-1 rounded-full text-sm font-semibold ${
          isReferrable ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'
        }`}>
          {isReferrable ? 'REFERRABLE DR' : 'NON-REFERRABLE'}
        </span>
      </div>

      {/* Main Diagnosis Grid */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="p-4 bg-gray-50 rounded-lg">
          <p className="text-xs text-gray-500 uppercase tracking-wide">ICDR Severity Grade</p>
          <p className="text-2xl font-black text-indigo-600">Grade {data.icdrGrade} ({data.gradeLabel})</p>
          <p className="text-xs text-gray-500 mt-1">Confidence: {((data.confidence || 0.94) * 100).toFixed(1)}%</p>
        </div>

        <div className="p-4 bg-gray-50 rounded-lg">
          <p className="text-xs text-gray-500 uppercase tracking-wide">DME Risk Level</p>
          <p className="text-2xl font-black text-amber-600">{data.dmeRisk}</p>
          <p className="text-xs text-gray-500 mt-1">Diabetic Macular Edema Assessment</p>
        </div>
      </div>

      {/* Class Probabilities Bar */}
      <div className="mb-6">
        <p className="text-xs font-semibold text-gray-600 mb-2">Class Probability Distribution (Grades 0 to 4)</p>
        <div className="flex gap-1 h-3 rounded-full overflow-hidden bg-gray-200">
          {probs.map((prob, idx) => (
            <div 
              key={idx} 
              style={{ width: `${Math.max(2, prob * 100)}%` }}
              className={`h-full ${['bg-green-500', 'bg-blue-400', 'bg-yellow-400', 'bg-orange-500', 'bg-red-600'][idx]}`}
              title={`Grade ${idx}: ${(prob * 100).toFixed(1)}%`}
            />
          ))}
        </div>
        <div className="flex justify-between text-[10px] text-gray-400 mt-1">
          <span>G0: No DR</span>
          <span>G1: Mild</span>
          <span>G2: Moderate</span>
          <span>G3: Severe</span>
          <span>G4: PDR</span>
        </div>
      </div>

      {/* Report Download Action */}
      <div className="flex justify-end">
        <a 
          href={`/api/reports/${data.patientID}`} 
          target="_blank" 
          rel="noreferrer"
          className="px-4 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition"
        >
          View Generated HTML Clinical Report
        </a>
      </div>
    </div>
  );
}
