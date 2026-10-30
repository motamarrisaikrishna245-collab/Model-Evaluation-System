# EvalAI — Local AI Exam Evaluation System

EvalAI is a local web application for Admin-controlled university answer-sheet evaluation. It runs in Chrome at one URL:

```text
http://localhost:8000
```

The system uses a React frontend served by FastAPI, SQLite for local data, OCR/document extraction, structured marking-scheme parsing, and a local Ollama-compatible LLM. It does not require a paid external AI API and does not silently fabricate marks when the model is unavailable.

## What is implemented

- One role only: `ADMIN`.
- Admin login with secure password hashing and JWT sessions.
- Examination creation and explicit document workflow.
- PDF question paper upload with direct extraction and OCR fallback.
- PDF evaluation scheme upload with rubric criteria and mark limits.
- Multiple PDF/image/TXT answer-sheet uploads.
- Student identity extraction from the answer sheet; uncertain identity is flagged rather than invented.
- Question/subquestion answer segmentation and page-aware metadata.
- Local Ollama semantic evaluation using the supplied question and marking scheme.
- Criteria-level marks, partial credit, relevance, correctness, completeness, English clarity, confidence, missing concepts, incorrect points, duplicate points, and concise evidence.
- Separate AI marks and Admin final marks.
- Admin review comments, finalization, audit logs, retry status, comparison sorting, and CSV export.
- Original uploaded files remain in organized `data/` folders.
- Background evaluation jobs with progress and error states.

## Requirements

- Windows, macOS, or Linux laptop.
- Python 3.11+.
- Node.js 20+ and npm for building the frontend.
- Recommended: 16 GB RAM for a 7B local model; 8 GB may work with a smaller quantized model.
- Optional NVIDIA/AMD/Apple GPU improves local model speed.
- Tesseract OCR is recommended for scanned/image-only PDFs. PyMuPDF handles direct text extraction and rasterization.
- Ollama or another local runtime that exposes the Ollama `/api/chat` interface.

## Install and configure

From `D:\ML project` on Windows:

```powershell
cd "D:\ML project"
python -m venv backend\.venv
& backend\.venv\Scripts\python.exe -m pip install -r backend\requirements.txt
cd frontend
npm install
npm run build
cd ..
Copy-Item backend\.env.example backend\.env
```

Install Ollama from its official installer, then download a model suitable for the laptop. For example:

```powershell
ollama serve
ollama pull qwen2.5:7b
```

Edit `backend\.env`:

```text
ADMIN_EMAIL=admin@localhost
ADMIN_PASSWORD=change-me
LLM_PROVIDER=local
LOCAL_LLM_BASE_URL=http://localhost:11434
LOCAL_LLM_MODEL=qwen2.5:7b
OCR_ENABLED=true
```

Change the Admin password before using the system with real examination data. If the selected model is unavailable, the application shows an error and creates no fabricated AI marks.

## Run

Preferred launcher:

```text
Start Local EvalAI.bat
```

The launcher starts FastAPI, which serves both the React production build and the API. Open:

```text
http://localhost:8000
```

Manual command:

```powershell
cd "D:\ML project\backend"
& .\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Default local login is the email and password configured in `backend\.env`.

## Exact workflow

1. Sign in as Admin.
2. Create an examination.
3. Upload the question paper.
4. Upload the evaluation scheme. The scheme is the primary marking authority.
5. Upload all answer sheets.
6. Click `START EVALUATION`. Uploading files never starts evaluation automatically.
7. Monitor the background status and progress.
8. Inspect every question's OCR text, criteria marks, evidence, confidence, and original answer file.
9. Save Admin final marks and a reason/comment where needed.
10. Compare students and export CSV.
11. Click `FINALIZE RESULTS` after required reviews.

## Local AI evaluation rules

The LLM receives the question, maximum marks, exact rubric criteria, and student answer. The prompt requires semantic understanding, alternative valid wording, partial credit, no grammar penalty when technical meaning is clear, no invented requirements, and duplicate points counted once. Returned JSON is validated with Pydantic. Criteria marks are clamped to the supplied criterion maximum and question totals are clamped to the question maximum.

The system does not execute student code. Diagram and program presence are assessed only when the question or scheme indicates they are required. Low OCR, uncertain identity, uncertain question matching, and low LLM confidence appear in review status.

## Project structure

```text
backend/
  app/
    main.py                 FastAPI + static React serving
    models.py               SQLite/SQLAlchemy tables
    schemas.py              Pydantic API schemas
    security.py             Password hashing and JWT
    seed.py                 Single Admin bootstrap
    routers/workflow.py     Auth, uploads, jobs, reviews, results, audit
    services/files.py       Safe uploads, PDF extraction, OCR fallback
    services/document_parser.py
    services/ai_evaluator.py Local Ollama provider and JSON validation
    services/evaluation.py  Segmentation, identity, scoring persistence
frontend/
  src/App.jsx              Admin dashboard and review UI
  src/api.js               API client
  src/styles.css           Responsive university administration UI
model/
  README.md                Optional historical training notes; not used by default
  dataset_schema.json      Optional future calibration schema
data/
  question_papers/
  evaluation_schemes/
  answer_sheets/
  processed/
  ocr/
  evaluations/
  exports/
```

## Testing and verification

Backend syntax/import check:

```powershell
& backend\.venv\Scripts\python.exe -m compileall -q backend\app
& backend\.venv\Scripts\python.exe -c "from app.main import app; print(app.title)"
```

Frontend production build:

```powershell
cd frontend
npm run build
```

The application should be tested with representative typed PDFs, scanned PDFs, handwritten pages where OCR permits, subquestions, skipped questions, duplicate points, missing diagrams, and low-confidence identity cases. Tests must not require a paid API.

## Troubleshooting

- **Local AI model is not available:** run `ollama serve`, verify `LOCAL_LLM_BASE_URL`, and confirm `ollama list` contains the configured model.
- **Model name not configured:** set `LOCAL_LLM_MODEL` in `backend\.env`, restart FastAPI, and retry the examination.
- **OCR is low confidence:** install/configure Tesseract and review the original answer image/PDF in the Admin screen.
- **Port 8000 is busy:** stop the process using port 8000 or run Uvicorn on another port and open that port manually.
- **Frontend is missing:** run `cd frontend; npm install; npm run build`.
- **Corrupt or unsupported PDF:** replace the source file; the failed examination remains marked `Error` and can be retried.
- **Low memory:** use a smaller quantized local model and evaluate sequentially; the job intentionally avoids many simultaneous model requests.

## Data and privacy

Documents and the SQLite database remain in the local project directory. Do not publish `backend/.env`, the `data/` directory, answer sheets, or the SQLite database. Uploaded student programs are never executed.
