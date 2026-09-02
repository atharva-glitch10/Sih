import { useState, useEffect } from "react";
import {
  User,
  Calendar,
  Mail,
  MapPin,
  Upload,
  Image as ImageIcon,
  ArrowLeft,
  ArrowRight,
  ScanEye,
  CheckCircle2,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useScreening } from "../context/ScreeningContext";
import { fetchSamples, uploadImage } from "../services/api";

function NewScreening() {
  const navigate = useNavigate();
  const {
    patient: contextPatient,
    updatePatient,
    imageInfo: contextImageInfo,
    updateImageInfo,
  } = useScreening();

  const [patient, setPatient] = useState({
    name: contextPatient.name || "Sunita Sharma",
    age: contextPatient.age || "58",
    gender: contextPatient.gender || "Female",
    email: contextPatient.email || "sunita.sharma@ruralhealth.gov.in",
    location: contextPatient.location || "Rural PHC Shirwal, Satara",
  });

  const [imageSource, setImageSource] = useState("sample"); // 'sample' | 'upload'
  const [samples, setSamples] = useState([]);
  const [selectedSample, setSelectedSample] = useState(null);

  const [uploadedFile, setUploadedFile] = useState(null);
  const [preview, setPreview] = useState(contextImageInfo?.previewUrl || "/data/synthetic/DR_Grade3_Sample01.bmp");
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    fetchSamples().then((data) => {
      if (data && data.length > 0) {
        setSamples(data);
        const initial = data.find((s) => s.path === contextImageInfo?.path) || data[0];
        setSelectedSample(initial);
        if (!contextImageInfo?.isUploaded) {
          setPreview(`/${initial.path}`);
        }
      }
    });
  }, []);

  // =========================
  // PATIENT INPUT
  // =========================
  const handleChange = (e) => {
    setPatient({
      ...patient,
      [e.target.name]: e.target.value,
    });
  };

  // =========================
  // IMAGE SELECTION / UPLOAD
  // =========================
  const handleSelectSample = (sample) => {
    setSelectedSample(sample);
    setPreview(`/${sample.path}`);
  };

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setUploadedFile(file);
    setPreview(URL.createObjectURL(file));
  };

  // =========================
  // SUBMIT
  // =========================
  const handleContinue = async () => {
    if (!patient.name || !patient.age || !patient.gender) {
      alert("Please enter the required patient details.");
      return;
    }

    let finalImagePath = selectedSample?.path || "data/synthetic/DR_Grade3_Sample01.bmp";
    let isUploaded = false;

    if (imageSource === "upload" && uploadedFile) {
      setUploading(true);
      try {
        const uploadRes = await uploadImage(uploadedFile);
        finalImagePath = uploadRes.path;
        isUploaded = true;
      } catch (err) {
        console.warn("Upload failed, proceeding with local preview:", err);
      } finally {
        setUploading(false);
      }
    }

    // Save into shared context
    updatePatient({
      ...patient,
      id: contextPatient.id || `PHC-MH-2026-${Math.floor(1000 + Math.random() * 9000)}`,
    });

    updateImageInfo({
      path: finalImagePath,
      name: uploadedFile ? uploadedFile.name : selectedSample?.name || "DR_Sample.bmp",
      previewUrl: preview,
      isUploaded,
    });

    navigate("/image-quality");
  };


  return (

    <div className="screening-page">


      {/* =================================
          PAGE HEADER
      ================================= */}

      <div className="screening-header">

        <div>

          <p className="page-label">
            NEW SCREENING
          </p>

          <h2>
            Start a New Screening
          </h2>

          <p>
            Enter patient details and upload
            a retinal fundus image for analysis.
          </p>

        </div>


        <div className="screening-status">

          <div className="status-dot"></div>

          AI Engine Ready

        </div>

      </div>



      {/* =================================
          PATIENT INFORMATION
      ================================= */}

      <div className="screening-card">

        <div className="section-heading">

          <div className="section-icon">

            <User size={19} />

          </div>

          <div>

            <h3>
              Patient Information
            </h3>

            <p>
              Enter the patient's basic details.
            </p>

          </div>

        </div>



        <div className="form-grid">


          {/* Name */}

          <div className="form-group">

            <label>
              Patient Name
              <span>*</span>
            </label>

            <div className="input-wrapper">

              <User size={17} />

              <input
                type="text"
                name="name"
                placeholder="Enter patient name"
                value={patient.name}
                onChange={handleChange}
              />

            </div>

          </div>



          {/* Age */}

          <div className="form-group">

            <label>
              Age
              <span>*</span>
            </label>

            <div className="input-wrapper">

              <Calendar size={17} />

              <input
                type="number"
                name="age"
                placeholder="Age"
                min="1"
                max="120"
                value={patient.age}
                onChange={handleChange}
              />

            </div>

          </div>



          {/* Gender */}

          <div className="form-group">

            <label>
              Gender
              <span>*</span>
            </label>

            <select
              name="gender"
              value={patient.gender}
              onChange={handleChange}
            >

              <option value="">
                Select gender
              </option>

              <option value="Female">
                Female
              </option>

              <option value="Male">
                Male
              </option>

              <option value="Other">
                Other
              </option>

            </select>

          </div>



          {/* Email */}

          <div className="form-group">

            <label>
              Email
              <span className="optional">
                Optional
              </span>
            </label>

            <div className="input-wrapper">

              <Mail size={17} />

              <input
                type="email"
                name="email"
                placeholder="patient@example.com"
                value={patient.email}
                onChange={handleChange}
              />

            </div>

          </div>



          {/* Location */}

          <div className="form-group full-width">

            <label>
              PHC / Location
            </label>

            <div className="input-wrapper">

              <MapPin size={17} />

              <input
                type="text"
                name="location"
                placeholder="Enter PHC or village name"
                value={patient.location}
                onChange={handleChange}
              />

            </div>

          </div>

        </div>

      </div>



      {/* =================================
          FUNDUS IMAGE
      ================================= */}

      <div className="screening-card">

        <div className="section-heading">

          <div className="section-icon">

            <ScanEye size={19} />

          </div>

          <div>

            <h3>
              Retinal Fundus Image
            </h3>

            <p>
              Upload a clear retinal image captured
              using a fundus camera.
            </p>

          </div>

        </div>



        {/* Source Toggle Tabs */}
        <div style={{ display: 'flex', gap: '10px', marginBottom: '16px' }}>
          <button
            type="button"
            onClick={() => setImageSource('sample')}
            style={{
              flex: 1,
              padding: '10px 14px',
              borderRadius: '8px',
              border: imageSource === 'sample' ? '2px solid #2b6cb0' : '1px solid #cbd5e1',
              background: imageSource === 'sample' ? '#ebf8ff' : '#fff',
              color: imageSource === 'sample' ? '#2b6cb0' : '#4a5568',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
            }}
          >
            <ScanEye size={16} /> Select Sample Image (Dataset)
          </button>
          <button
            type="button"
            onClick={() => setImageSource('upload')}
            style={{
              flex: 1,
              padding: '10px 14px',
              borderRadius: '8px',
              border: imageSource === 'upload' ? '2px solid #2b6cb0' : '1px solid #cbd5e1',
              background: imageSource === 'upload' ? '#ebf8ff' : '#fff',
              color: imageSource === 'upload' ? '#2b6cb0' : '#4a5568',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
            }}
          >
            <Upload size={16} /> Upload Custom Image
          </button>
        </div>

        {imageSource === 'sample' && (
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: '#4a5568', marginBottom: '6px' }}>
              Choose Retinal Fundus Sample from Backend:
            </label>
            <select
              value={selectedSample?.path || ''}
              onChange={(e) => {
                const found = samples.find((s) => s.path === e.target.value);
                if (found) handleSelectSample(found);
              }}
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                background: '#fff',
                fontWeight: 500,
              }}
            >
              {samples.map((s) => (
                <option key={s.path} value={s.path}>
                  {s.name} {s.name.includes('Grade0') ? '— Grade 0 (No DR)' :
                            s.name.includes('Grade1') ? '— Grade 1 (Mild NPDR)' :
                            s.name.includes('Grade2') ? '— Grade 2 (Moderate NPDR)' :
                            s.name.includes('Grade3') ? '— Grade 3 (Severe NPDR)' :
                            s.name.includes('Grade4') ? '— Grade 4 (Proliferative DR)' : ''}
                </option>
              ))}
            </select>
          </div>
        )}

        {imageSource === 'upload' && !uploadedFile && (
          <label className="upload-area">
            <input
              type="file"
              accept="image/jpeg,image/png,image/jpg"
              onChange={handleImageUpload}
              hidden
            />
            <div className="upload-icon">
              <Upload size={26} />
            </div>
            <h4>Upload Fundus Image</h4>
            <p>Click to browse or drag and drop</p>
            <span>JPG, PNG or BMP • Maximum 10 MB</span>
          </label>
        )}

        {preview && (imageSource === 'sample' || uploadedFile) && (
          <div className="image-preview-container">
            <div className="image-preview" style={{ maxHeight: '280px', display: 'flex', justifyContent: 'center', background: '#000', borderRadius: '8px', overflow: 'hidden' }}>
              <img
                src={preview}
                alt="Selected retinal fundus"
                style={{ maxHeight: '280px', objectFit: 'contain' }}
              />
            </div>

            <div className="image-details">
              <div className="uploaded-file">
                <ImageIcon size={20} />
                <div>
                  <strong>{uploadedFile ? uploadedFile.name : selectedSample?.name || 'Selected Fundus Image'}</strong>
                  <span>{imageSource === 'sample' ? 'Synthetic Dataset Sample' : `${(uploadedFile?.size / 1024 / 1024).toFixed(2)} MB`}</span>
                </div>
              </div>

              {imageSource === 'upload' ? (
                <label className="change-image">
                  <input
                    type="file"
                    accept="image/jpeg,image/png,image/jpg"
                    onChange={handleImageUpload}
                    hidden
                  />
                  Change Image
                </label>
              ) : (
                <span style={{ fontSize: '12px', color: '#2b6cb0', fontWeight: 600 }}>Ready for AI Analysis</span>
              )}
            </div>
          </div>
        )}

      </div>



      {/* =================================
          IMAGE QUALITY NOTE
      ================================= */}

      <div className="quality-info">

        <div className="quality-info-icon">

          <ScanEye size={18} />

        </div>

        <div>

          <strong>
            Image Quality Assessment
          </strong>

          <p>
            NETRA will automatically check focus,
            illumination, retinal field of view,
            and image quality before AI analysis.
          </p>

        </div>

      </div>



      {/* =================================
          ACTIONS
      ================================= */}

      <div className="screening-actions">

        <button
          className="secondary-button"
          onClick={() => navigate("/")}
        >

          <ArrowLeft size={17} />

          Cancel

        </button>


        <button
          className="primary-button"
          onClick={handleContinue}
        >

          Continue to Image Quality

          <ArrowRight size={17} />

        </button>

      </div>

    </div>

  );
}


export default NewScreening;