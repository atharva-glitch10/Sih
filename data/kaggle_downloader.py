"""
Kaggle Dataset Downloader & Standardizer for MathWorks SIH DR Screening Pipeline.
Uses Kaggle API token to download and unpack:
  1. IDRiD (Indian Diabetic Retinopathy Image Dataset)
  2. APTOS 2019 Blindness Detection Dataset
  3. DRIVE Retinal Vessel Segmentation Benchmark
"""

import os
import sys
import zipfile
import subprocess
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent
RAW_DIR = DATA_DIR / "raw"
PROCESSED_DIR = DATA_DIR / "processed"

# Set token in environment
os.environ["KAGGLE_API_TOKEN"] = "KGAT_3a1b09c004d8a5c0ff3cedc31abc6798"

DATASETS = {
    "DRIVE_vessels": {
        "slug": "andrewmvd/drive-digital-retinal-images-for-vessel-extraction",
        "is_competition": False,
        "description": "DRIVE Vessel Segmentation Benchmark (29 MB)"
    },
    "IDRiD_grading": {
        "slug": "mariaherrerot/idrid-dataset",
        "is_competition": False,
        "description": "IDRiD: Indian Diabetic Retinopathy Grading Dataset (174 MB)"
    },
    "APTOS_2019_sample": {
        "slug": "sovitrath/diabetic-retinopathy-224x224-2019-data",
        "is_competition": False,
        "description": "APTOS 2019 Standardized Indian Retinopathy Dataset (249 MB)"
    }
}

def download_dataset(dataset_key):
    if dataset_key not in DATASETS:
        print(f"[ERROR] Unknown dataset key: {dataset_key}. Available: {list(DATASETS.keys())}")
        return False

    info = DATASETS[dataset_key]
    target_dir = RAW_DIR / dataset_key
    target_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n=======================================================")
    print(f"  Downloading: {info['description']}")
    print(f"  Target: {target_dir}")
    print(f"=======================================================")

    try:
        if info["is_competition"]:
            cmd = ["kaggle", "competitions", "download", "-c", info["slug"], "-p", str(target_dir)]
        else:
            cmd = ["kaggle", "datasets", "download", "-d", info["slug"], "-p", str(target_dir), "--unzip"]

        print(f"[EXEC] Running: {' '.join(cmd)}")
        res = subprocess.run(cmd, capture_output=True, text=True)

        if res.returncode == 0:
            print(f"[SUCCESS] Downloaded and extracted {dataset_key} successfully.")
            # Unpack any lingering zip files if not auto-unzipped
            for zip_file in target_dir.glob("*.zip"):
                with zipfile.ZipFile(zip_file, 'r') as z:
                    z.extractall(target_dir)
                zip_file.unlink()
            return True
        else:
            print(f"[WARN] Kaggle download error: {res.stderr or res.stdout}")
            return False
    except Exception as e:
        print(f"[ERROR] Exception during download: {e}")
        return False

def list_available():
    print("\nAvailable Kaggle Datasets for MathWorks SIH:")
    for k, v in DATASETS.items():
        print(f"  * {k:20s} : {v['description']} [{v['slug']}]")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        target = sys.argv[1]
        if target == "all":
            for k in DATASETS:
                download_dataset(k)
        else:
            download_dataset(target)
    else:
        list_available()
        print("\nUsage:")
        print("  python data/kaggle_downloader.py DRIVE_vessels")
        print("  python data/kaggle_downloader.py IDRiD_grading")
        print("  python data/kaggle_downloader.py APTOS_2019_sample")
        print("  python data/kaggle_downloader.py all")
