import { useState } from "react";

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
} from "lucide-react";

import { useNavigate } from "react-router-dom";


function NewScreening() {

  const navigate = useNavigate();

  const [patient, setPatient] = useState({
    name: "",
    age: "",
    gender: "",
    email: "",
    location: "",
  });

  const [image, setImage] = useState(null);

  const [preview, setPreview] = useState(null);


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
  // IMAGE UPLOAD
  // =========================

  const handleImageUpload = (e) => {

    const file = e.target.files[0];

    if (!file) return;

    setImage(file);

    setPreview(
      URL.createObjectURL(file)
    );

  };


  // =========================
  // SUBMIT
  // =========================

  const handleContinue = () => {

    if (
      !patient.name ||
      !patient.age ||
      !patient.gender ||
      !image
    ) {

      alert(
        "Please enter the required patient details and upload a fundus image."
      );

      return;
    }

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



        {!preview ? (

          /* =========================
             UPLOAD AREA
          ========================= */

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

            <h4>
              Upload Fundus Image
            </h4>

            <p>
              Click to browse or drag and drop
            </p>

            <span>
              JPG or PNG • Maximum 10 MB
            </span>

          </label>

        ) : (

          /* =========================
             IMAGE PREVIEW
          ========================= */

          <div className="image-preview-container">

            <div className="image-preview">

              <img
                src={preview}
                alt="Uploaded retinal fundus"
              />

            </div>


            <div className="image-details">

              <div className="uploaded-file">

                <ImageIcon size={20} />

                <div>

                  <strong>
                    {image?.name}
                  </strong>

                  <span>
                    {(image?.size / 1024 / 1024).toFixed(2)}
                    {" MB"}
                  </span>

                </div>

              </div>


              <label className="change-image">

                <input
                  type="file"
                  accept="image/jpeg,image/png,image/jpg"
                  onChange={handleImageUpload}
                  hidden
                />

                Change Image

              </label>

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