import re
from typing import List, Dict
from collections import Counter

class KeywordExtractor:
    
    def __init__(self):
        # Common tech skills and action words
        self.tech_skills = [
            'python', 'java', 'javascript', 'react', 'angular', 'vue', 'node',
            'sql', 'mongodb', 'postgresql', 'aws', 'azure', 'docker', 'kubernetes',
            'machine learning', 'ai', 'data science', 'tensorflow', 'pytorch',
            'git', 'agile', 'scrum', 'rest api', 'microservices', 'html', 'css',
            'bootstrap', 'django', 'flask', 'express', 'spring', 'hibernate'
        ]
        
        self.action_verbs = [
            'developed', 'created', 'implemented', 'designed', 'built', 'managed',
            'led', 'optimized', 'improved', 'increased', 'reduced', 'achieved',
            'delivered', 'collaborated', 'analyzed', 'architected', 'maintained',
            'deployed', 'tested', 'debugged', 'integrated', 'automated'
        ]
    
    def extract_keywords_from_job_description(self, jd_text: str) -> Dict:
        """Extract keywords from job description using simple text analysis"""
        
        jd_text_clean = self._clean_text(jd_text)
        
        # Find technical skills mentioned
        tech_skills = self._find_tech_skills(jd_text_clean)
        
        # Extract requirements using pattern matching
        requirements = self._extract_requirements(jd_text)
        
        # Find important words (frequency-based)
        important_words = self._extract_frequent_words(jd_text_clean)
        
        return {
            "tech_skills": tech_skills,
            "requirements": requirements,
            "important_words": important_words,
            "total_keywords": len(tech_skills) + len(requirements)
        }
    
    def analyze_resume_match(self, resume_text: str, jd_keywords: Dict) -> Dict:
        """Analyze how well resume matches job description"""
        
        resume_clean = self._clean_text(resume_text)
        
        # Check for matching tech skills
        jd_tech_skills = jd_keywords.get('tech_skills', [])
        matching_tech = []
        missing_tech = []
        
        for skill in jd_tech_skills:
            if self._is_keyword_present(skill, resume_clean):
                matching_tech.append(skill)
            else:
                missing_tech.append(skill)
        
        # Check for matching requirements
        jd_requirements = jd_keywords.get('requirements', [])
        matching_req = []
        missing_req = []
        
        for req in jd_requirements:
            if self._is_keyword_present(req, resume_clean):
                matching_req.append(req)
            else:
                missing_req.append(req)
        
        # Calculate scores
        total_items = len(jd_tech_skills) + len(jd_requirements)
        matched_items = len(matching_tech) + len(matching_req)
        
        match_percentage = (matched_items / total_items * 100) if total_items > 0 else 0
        ats_score = self._calculate_ats_score(resume_clean, jd_keywords, matched_items, total_items)
        
        return {
            "matching_tech_skills": matching_tech,
            "missing_tech_skills": missing_tech,
            "matching_requirements": matching_req,
            "missing_requirements": missing_req,
            "match_percentage": round(match_percentage, 2),
            "ats_score": ats_score,
            "suggestions": self._generate_suggestions(missing_tech + missing_req)
        }
    
    def _clean_text(self, text: str) -> str:
        """Clean text for processing"""
        return re.sub(r'\s+', ' ', text.lower()).strip()
    
    def _find_tech_skills(self, text: str) -> List[str]:
        """Find technical skills in text"""
        found_skills = []
        for skill in self.tech_skills:
            if skill.lower() in text:
                found_skills.append(skill)
        return found_skills
    
    def _extract_requirements(self, text: str) -> List[str]:
        """Extract requirements from job description"""
        requirements = []
        
        # Look for common requirement patterns
        req_patterns = [
            r'(?:requirements?|qualifications?|must have)[:\s]+(.*?)(?=\n\s*\n|\n\s*[A-Z][a-z]+:|$)',
            r'(?:experience with|knowledge of|proficient in|skilled in)[:\s]+([^\n.]+)',
            r'(?:\d+\+?\s*years?)[^\n]+',
        ]
        
        for pattern in req_patterns:
            matches = re.findall(pattern, text, re.IGNORECASE | re.DOTALL)
            for match in matches:
                if isinstance(match, str):
                    # Split by common separators and clean
                    items = re.split(r'[,;•\n\-\*]', match)
                    for item in items:
                        item = item.strip()
                        if 3 <= len(item) <= 80 and not item.startswith(('http', 'www')):
                            requirements.append(item)
        
        # Remove duplicates and return top 10
        return list(set(requirements))[:10]
    
    def _extract_frequent_words(self, text: str) -> List[str]:
        """Extract frequently mentioned important words"""
        # Remove common stop words
        stop_words = {'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'}
        
        words = re.findall(r'\b[a-z]{3,15}\b', text)
        word_freq = Counter(word for word in words if word not in stop_words)
        
        # Return top 10 most frequent words
        return [word for word, freq in word_freq.most_common(10) if freq > 1]
    
    def _is_keyword_present(self, keyword: str, text: str) -> bool:
        """Check if keyword is present in text"""
        keyword_lower = keyword.lower()
        text_lower = text.lower()
        
        # Direct match
        if keyword_lower in text_lower:
            return True
        
        # Check for partial matches for compound terms
        words = keyword_lower.split()
        if len(words) > 1:
            return all(word in text_lower for word in words)
        
        return False
    
    def _calculate_ats_score(self, resume_text: str, jd_keywords: Dict, matched_items: int, total_items: int) -> int:
        """Calculate ATS compatibility score"""
        score = 0
        
        # Keyword matching (60% of score)
        if total_items > 0:
            score += int((matched_items / total_items) * 60)
        
        # Action verbs presence (25% of score)
        action_verb_count = sum(1 for verb in self.action_verbs if verb in resume_text)
        score += min(25, action_verb_count * 2)
        
        # Resume length and structure (15% of score)
        word_count = len(resume_text.split())
        if 150 <= word_count <= 1000:
            score += 15
        elif word_count >= 100:
            score += 10
        
        return min(100, score)
    
    def _generate_suggestions(self, missing_items: List[str]) -> List[str]:
        """Generate improvement suggestions"""
        suggestions = []
        
        # Limit to top 5 missing items
        for item in missing_items[:5]:
            if any(tech in item.lower() for tech in self.tech_skills):
                suggestions.append(f"Add '{item}' to your technical skills section")
            else:
                suggestions.append(f"Consider including '{item}' in relevant experience descriptions")
        
        if not suggestions:
            suggestions = [
                "Add more action verbs to strengthen your experience descriptions",
                "Include specific technologies and tools you've worked with",
                "Quantify your achievements with numbers and percentages"
            ]
        
        return suggestions

# Create global instance
keyword_extractor = KeywordExtractor()
