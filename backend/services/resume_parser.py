# Try different import approaches
try:
    import fitz  # This is the actual PyMuPDF import
except ImportError:
    try:
        import pymupdf as fitz
    except ImportError:
        fitz = None

import docx2txt
import re
from typing import Optional
from fastapi import UploadFile

class ResumeParser:
    
    def __init__(self):
        if fitz is None:
            print("Warning: PyMuPDF not available. PDF parsing will be limited.")
    
    async def parse_resume(self, file: UploadFile) -> dict:
        """Extract text from PDF, DOCX, or TXT files"""
        
        file_content = await file.read()
        content_type = file.content_type
        filename = file.filename.lower() if file.filename else ""
        
        try:
            if content_type == "application/pdf" or filename.endswith('.pdf'):
                if fitz:
                    text = self._parse_pdf(file_content)
                else:
                    return {"error": "PDF parsing not available", "success": False}
            elif (content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" 
                  or filename.endswith('.docx')):
                text = self._parse_docx(file_content)
            elif content_type == "text/plain" or filename.endswith('.txt'):
                text = file_content.decode('utf-8')
            else:
                raise ValueError(f"Unsupported file type: {content_type}")
            
            # Clean and process text
            cleaned_text = self._clean_text(text)
            
            # Extract sections
            sections = self._extract_sections(cleaned_text)
            
            return {
                "filename": file.filename,
                "text": cleaned_text,
                "sections": sections,
                "word_count": len(cleaned_text.split()),
                "success": True
            }
            
        except Exception as e:
            return {
                "filename": file.filename,
                "error": str(e),
                "success": False
            }
    
    def _parse_pdf(self, file_content: bytes) -> str:
        """Extract text from PDF using PyMuPDF"""
        doc = fitz.open(stream=file_content, filetype="pdf")
        text = ""
        for page in doc:
            text += page.get_text()
        doc.close()
        return text
    
    def _parse_docx(self, file_content: bytes) -> str:
        """Extract text from DOCX"""
        import tempfile
        import os
        
        with tempfile.NamedTemporaryFile(delete=False, suffix='.docx') as tmp_file:
            tmp_file.write(file_content)
            tmp_file.flush()
            text = docx2txt.process(tmp_file.name)
            os.unlink(tmp_file.name)
        
        return text
    
    def _clean_text(self, text: str) -> str:
        """Clean and normalize text"""
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'[^\w\s\-\.\@\(\)\+]', ' ', text)
        text = ' '.join(text.split())
        return text.strip()
    
    def _extract_sections(self, text: str) -> dict:
        """Extract common resume sections"""
        sections = {}
        
        section_patterns = {
            'contact': r'(contact|personal|info)',
            'summary': r'(summary|profile|objective)',
            'experience': r'(experience|employment|work|career)',
            'education': r'(education|academic|degree)',
            'skills': r'(skills|technical|competencies)',
            'projects': r'(projects|portfolio)'
        }
        
        for section, pattern in section_patterns.items():
            match = re.search(f'{pattern}.*?(?=\n[A-Z]|$)', text, re.IGNORECASE | re.DOTALL)
            if match:
                sections[section] = match.group(0).strip()
        
        return sections

# Create global instance
resume_parser = ResumeParser()
