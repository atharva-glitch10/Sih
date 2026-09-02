import React, { createContext, useContext, useState, useEffect } from 'react';
import { runDiagnosis } from '../services/api';

const ScreeningContext = createContext();

const DEFAULT_PATIENT = {
  id: 'PHC-MH-2026-0842',
  name: 'Sunita Sharma',
  age: '58',
  gender: 'Female',
  email: 'sunita.sharma@ruralhealth.gov.in',
  location: 'Rural PHC Shirwal, Satara',
};

const DEFAULT_IMAGE = {
  path: 'data/synthetic/DR_Grade3_Sample01.bmp',
  name: 'DR_Grade3_Sample01.bmp',
  previewUrl: '/data/synthetic/DR_Grade3_Sample01.bmp',
  isUploaded: false,
};

const DEFAULT_IQA = {
  status: 'Gradeable',
  score: 86,
  focus: 91,
  illumination: 84,
  fov: 88,
};

const DEFAULT_HISTORY = [
  {
    id: 'NETRA-2026-0842',
    patient: 'Sunita Sharma',
    age: 58,
    grade: 3,
    diagnosis: 'Severe NPDR',
    status: 'Referable',
    date: '02 Sep 2026',
    time: '10 min ago',
    location: 'Rural PHC Shirwal',
  },
  {
    id: 'NETRA-2026-0841',
    patient: 'Ramesh Patil',
    age: 64,
    grade: 1,
    diagnosis: 'Mild NPDR',
    status: 'Non-Referable',
    date: '02 Sep 2026',
    time: '32 min ago',
    location: 'Rural PHC Shirwal',
  },
  {
    id: 'NETRA-2026-0840',
    patient: 'Anjali Deshmukh',
    age: 52,
    grade: 0,
    diagnosis: 'No DR',
    status: 'Non-Referable',
    date: '01 Sep 2026',
    time: '1 hr ago',
    location: 'Rural PHC Shirwal',
  },
  {
    id: 'NETRA-2026-0839',
    patient: 'Kishore Jadhav',
    age: 67,
    grade: 4,
    diagnosis: 'Proliferative DR (PDR)',
    status: 'Referable',
    date: '01 Sep 2026',
    time: '3 hr ago',
    location: 'Rural PHC Shirwal',
  },
];

export function ScreeningProvider({ children }) {
  const [patient, setPatient] = useState(() => {
    const saved = localStorage.getItem('netra_current_patient');
    return saved ? JSON.parse(saved) : DEFAULT_PATIENT;
  });

  const [imageInfo, setImageInfo] = useState(() => {
    const saved = localStorage.getItem('netra_current_image');
    return saved ? JSON.parse(saved) : DEFAULT_IMAGE;
  });

  const [iqa, setIqa] = useState(DEFAULT_IQA);

  const [diagnosis, setDiagnosis] = useState(() => {
    const saved = localStorage.getItem('netra_current_diagnosis');
    return saved ? JSON.parse(saved) : null;
  });

  const [doctorReview, setDoctorReview] = useState({
    decision: 'Confirmed AI Result',
    notes: 'AI findings reviewed. Severe diabetic retinopathy detected. Urgent specialist referral required.',
    timestamp: new Date().toISOString(),
  });

  const [screeningsHistory, setScreeningsHistory] = useState(() => {
    const saved = localStorage.getItem('netra_screenings_history');
    return saved ? JSON.parse(saved) : DEFAULT_HISTORY;
  });

  const [isDiagnosing, setIsDiagnosing] = useState(false);
  const [diagnosisError, setDiagnosisError] = useState(null);

  // Sync current screening data with localStorage
  useEffect(() => {
    try {
      localStorage.setItem('netra_current_patient', JSON.stringify(patient));
    } catch {}
  }, [patient]);

  useEffect(() => {
    try {
      localStorage.setItem('netra_current_image', JSON.stringify(imageInfo));
    } catch {}
  }, [imageInfo]);

  useEffect(() => {
    try {
      if (diagnosis) {
        localStorage.setItem('netra_current_diagnosis', JSON.stringify(diagnosis));
      }
    } catch {}
  }, [diagnosis]);

  useEffect(() => {
    try {
      localStorage.setItem('netra_screenings_history', JSON.stringify(screeningsHistory));
    } catch {}
  }, [screeningsHistory]);

  const updatePatient = (fields) => {
    setPatient((prev) => ({ ...prev, ...fields }));
  };

  const updateImageInfo = (info) => {
    setImageInfo((prev) => ({ ...prev, ...info }));
  };

  const executeDiagnosis = async () => {
    setIsDiagnosing(true);
    setDiagnosisError(null);
    try {
      const result = await runDiagnosis({
        imagePath: imageInfo.path,
        patientId: patient.id || 'PHC-MH-2026-0842',
      });
      setDiagnosis(result);

      // Add to screenings history
      const newRecord = {
        id: result.patientID || patient.id,
        patient: patient.name || 'Patient',
        age: parseInt(patient.age) || 55,
        grade: result.icdrGrade ?? 0,
        diagnosis: result.gradeLabel || 'Evaluated',
        status: result.isReferrable ? 'Referable' : 'Non-Referable',
        date: new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }),
        time: 'Just now',
        location: patient.location || 'Rural PHC',
      };

      setScreeningsHistory((prev) => [
        newRecord,
        ...prev.filter((r) => r.id !== newRecord.id),
      ]);

      return result;
    } catch (err) {
      setDiagnosisError(err.message);
      throw err;
    } finally {
      setIsDiagnosing(false);
    }
  };

  const updateDoctorReview = (decision, notes) => {
    setDoctorReview({
      decision,
      notes,
      timestamp: new Date().toISOString(),
    });
  };

  const resetScreening = () => {
    const randomId = `PHC-MH-2026-${Math.floor(1000 + Math.random() * 9000)}`;
    setPatient({
      id: randomId,
      name: '',
      age: '',
      gender: '',
      email: '',
      location: 'Rural PHC Shirwal, Satara',
    });
    setImageInfo(DEFAULT_IMAGE);
    setDiagnosis(null);
    setDoctorReview({ decision: '', notes: '', timestamp: null });
  };

  return (
    <ScreeningContext.Provider
      value={{
        patient,
        updatePatient,
        imageInfo,
        updateImageInfo,
        iqa,
        setIqa,
        diagnosis,
        setDiagnosis,
        doctorReview,
        updateDoctorReview,
        screeningsHistory,
        isDiagnosing,
        diagnosisError,
        executeDiagnosis,
        resetScreening,
      }}
    >
      {children}
    </ScreeningContext.Provider>
  );
}

export function useScreening() {
  const ctx = useContext(ScreeningContext);
  if (!ctx) {
    throw new Error('useScreening must be used within a ScreeningProvider');
  }
  return ctx;
}
