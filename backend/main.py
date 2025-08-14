from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from services.resume_parser import resume_parser
from services.keyword_extractor import keyword_extractor
from typing import Optional
import uvicorn

app = FastAPI(
    title="AI Resume Optimization API",
    description="Backend for mobile resume optimization assistant",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "AI Resume Assistant API",
        "version": "0.1.0",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "ai-resume-api"}

@app.post("/api/v1/resume/upload")
async def upload_resume(file: UploadFile = File(...)):
    """Parse uploaded resume and extract text"""
    result = await resume_parser.parse_resume(file)
    return result

@app.post("/api/v1/resume/analyze")
async def analyze_resume(
    file: UploadFile = File(...),
    job_description: Optional[str] = Form(None)
):
    """Analyze resume against job description"""
    
    # Parse resume
    resume_result = await resume_parser.parse_resume(file)
    
    if not resume_result.get("success"):
        return resume_result
    
    resume_text = resume_result["text"]
    
    if job_description:
        # Extract keywords from job description
        jd_keywords = keyword_extractor.extract_keywords_from_job_description(job_description)
        
        # Analyze match
        match_analysis = keyword_extractor.analyze_resume_match(resume_text, jd_keywords)
        
        return {
            "success": True,
            "resume": resume_result,
            "job_analysis": jd_keywords,
            "match_analysis": match_analysis
        }
    else:
        # Basic resume analysis without JD
        return {
            "success": True,
            "resume": resume_result,
            "message": "Resume parsed successfully. Add job description for detailed analysis."
        }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
