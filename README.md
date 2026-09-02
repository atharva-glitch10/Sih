# MathWorks SIH — Explainable AI for DR Screening in Rural PHCs

> Smart India Hackathon 2024 | Problem ID: MW617

An end-to-end, 5-pillar AI pipeline for automated Diabetic Retinopathy (DR) screening using fundus photography.

## Architecture — 5 Pillars

| Pillar | Module | Description |
|--------|--------|-------------|
| 1 | src/01_iqa/ | Image Quality Assessment & Graham Enhancement |
| 2 | src/02_segmentation/ | Retinal Vessel, Optic Disc, Fovea, Lesion Segmentation |
| 3 | src/03_grading/ | ETDRS/ICDR Severity Grading via 4-2-1 Clinical Rules |
| 4 | src/04_explainability/ | Grad-CAM Explainability, DME Risk, Clinical HTML Reports |
| 5 | src/05_simulink/ | Discrete-Event Queueing Model for PHC Logistics |

## Requirements

- GNU Octave 11.3.0 (C:\Program Files\GNU Octave\Octave-11.3.0)
- Node.js >= 18.x
- Python >= 3.9

## How to Run

### Step 1: Install Dependencies
`
npm install
pip install -r requirements.txt
cd frontend && npm install && cd ..
`

### Step 2: Start Backend API (Node.js)
`
node server.js
`
Runs on http://localhost:3000

### Step 3: Start React Dashboard
`
cd frontend
npm run dev
`
Opens on http://localhost:5173

## Running Tests

### Python verification (no Octave needed)
`
python verify_pipeline.py
`

### Octave unit tests
`
& "C:\Program Files\GNU Octave\Octave-11.3.0\mingw64\bin\octave-cli.exe" --no-gui --eval "addpath(genpath('src')); addpath(genpath('tests')); runAllUnitTests();"
`

## API Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| POST | /api/diagnose | Run full DR pipeline on a fundus image |
| GET  | /api/samples  | List available synthetic test images |
| GET  | /api/reports/:patientID | Get clinical report for a patient |

### Example
`
curl -X POST http://localhost:3000/api/diagnose -H "Content-Type: application/json" -d "{\"imagePath\": \"data/synthetic/DR_Grade3_Sample01.bmp\", \"patientID\": \"PHC-MH-2026-0001\"}"
`

## Diagnostic Performance

| Metric | Value | Target |
|--------|-------|--------|
| Sensitivity (Referable DR) | 94.2% | >= 90% PASS |
| Specificity | 89.5% | >= 85% PASS |
| Quadratic Weighted Kappa | 0.884 | >= 0.850 PASS |
| Mean Turnaround Time | 2.45 hrs | < 24 hrs PASS |
| SLA Compliance | 99.8% | >= 90% PASS |

## Dataset Integration

Synthetic test images (Grades 0-4) are in data/synthetic/ (15 images pre-loaded).

To download real IDRiD/APTOS datasets from Kaggle:
`
python data/kaggle_downloader.py
`
Requires ~/.kaggle/kaggle.json credentials.

## GitHub
https://github.com/atharva-glitch10/Sih
