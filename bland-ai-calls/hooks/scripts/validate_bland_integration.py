#!/usr/bin/env python3
"""
Validation hook for Bland.ai integration code.
Scores integration against 100-point rubric across 5 categories.

Usage: python3 validate_bland_integration.py <file_path>
"""

import sys
import os
import re
import json
from pathlib import Path

def validate_integration(file_path):
    """Main validation function"""
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return
    
    # Only validate relevant files
    if not should_validate(file_path):
        return
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    file_name = os.path.basename(file_path)
    file_ext = os.path.splitext(file_path)[1]
    
    # Initialize scoring
    score = {
        'Security': {'score': 0, 'max': 25, 'issues': []},
        'Error Handling': {'score': 0, 'max': 25, 'issues': []},
        'Data Management': {'score': 0, 'max': 20, 'issues': []},
        'Architecture': {'score': 0, 'max': 20, 'issues': []},
        'Best Practices': {'score': 0, 'max': 10, 'issues': []}
    }
    
    # Run validations based on file type
    if file_ext == '.cls':
        validate_apex_class(content, file_name, score)
    elif file_ext == '.xml' and 'namedCredential' in file_name:
        validate_named_credential(content, score)
    elif file_ext == '.xml' and 'object' in file_name:
        validate_custom_object(content, score)
    
    # Calculate total score
    total_score = sum(cat['score'] for cat in score.values())
    total_max = sum(cat['max'] for cat in score.values())
    
    # Print results
    print_validation_results(file_name, score, total_score, total_max)


def should_validate(file_path):
    """Check if file should be validated"""
    file_name = os.path.basename(file_path)
    
    # Validate Apex classes related to Bland.ai
    if file_path.endswith('.cls') and 'BlandAI' in file_name:
        return True
    
    # Validate Named Credentials
    if 'namedCredential' in file_path and 'bland' in file_path.lower():
        return True
    
    # Validate Call custom object
    if 'Call__c' in file_name:
        return True
    
    return False


def validate_apex_class(content, file_name, score):
    """Validate Apex class for Bland.ai integration"""
    
    # Security checks (25 points)
    security_score = 25
    
    if 'with sharing' in content or 'without sharing' in content:
        score['Security']['score'] += 5
    else:
        security_score -= 5
        score['Security']['issues'].append("Missing sharing keyword (with sharing/without sharing)")
    
    # Check for hardcoded API keys
    if re.search(r'(api[_-]?key|authorization|bearer)\s*[:=]\s*["\'][^"\']+["\']', content, re.IGNORECASE):
        security_score -= 10
        score['Security']['issues'].append("⚠️ CRITICAL: Potential hardcoded API key detected")
    else:
        score['Security']['score'] += 10
    
    # Check for Named Credential usage
    if 'callout:' in content:
        score['Security']['score'] += 10
    else:
        security_score -= 10
        score['Security']['issues'].append("Should use Named Credential (callout:NamedCredential)")
    
    # Error Handling checks (25 points)
    error_score = 25
    
    # Check for try-catch blocks
    if 'try {' in content and 'catch' in content:
        score['Error Handling']['score'] += 10
    else:
        error_score -= 10
        score['Error Handling']['issues'].append("Missing try-catch error handling")
    
    # Check for timeout configuration
    if 'setTimeout' in content:
        score['Error Handling']['score'] += 5
    else:
        error_score -= 5
        score['Error Handling']['issues'].append("Missing timeout configuration")
    
    # Check for validation
    if 'isBlank' in content or 'isEmpty' in content or 'validate' in content.lower():
        score['Error Handling']['score'] += 5
    else:
        error_score -= 5
        score['Error Handling']['issues'].append("Missing input validation")
    
    # Check for logging
    if 'System.debug' in content or 'log' in content.lower():
        score['Error Handling']['score'] += 5
    else:
        error_score -= 5
        score['Error Handling']['issues'].append("Missing error logging")
    
    # Data Management checks (20 points)
    data_score = 20
    
    # Check for CRUD/FLS checks
    if 'isCreateable' in content or 'isUpdateable' in content or 'isAccessible' in content:
        score['Data Management']['score'] += 10
    else:
        data_score -= 10
        score['Data Management']['issues'].append("Missing CRUD/FLS security checks")
    
    # Check for bulkification (no SOQL/DML in loops)
    if re.search(r'for\s*\([^)]+\)\s*\{[^}]*\b(insert|update|delete|undelete|upsert|SELECT)\b', content, re.DOTALL):
        data_score -= 5
        score['Data Management']['issues'].append("⚠️ Potential SOQL/DML in loop detected")
    else:
        score['Data Management']['score'] += 5
    
    # Check for proper list handling
    if 'List<' in content:
        score['Data Management']['score'] += 5
    
    # Architecture checks (20 points)
    arch_score = 20
    
    # Check for proper class structure (methods, separation of concerns)
    if 'public static' in content or 'private static' in content:
        score['Architecture']['score'] += 5
    
    # Check for async patterns (Queueable, Future)
    if 'Queueable' in content or '@future' in content:
        score['Architecture']['score'] += 10
    else:
        arch_score -= 10
        score['Architecture']['issues'].append("Consider using async patterns (Queueable) for callouts")
    
    # Check for proper documentation
    if '/**' in content and '@description' in content:
        score['Architecture']['score'] += 5
    else:
        arch_score -= 5
        score['Architecture']['issues'].append("Missing ApexDoc comments")
    
    # Best Practices checks (10 points)
    bp_score = 10
    
    # Check for API version (should be 62.0+)
    # This would require reading meta.xml file
    
    # Check for proper exception types
    if 'CalloutException' in content or 'Exception' in content:
        score['Best Practices']['score'] += 5
    
    # Check for proper HTTP status code handling
    if 'getStatusCode' in content:
        score['Best Practices']['score'] += 5
    else:
        bp_score -= 5
        score['Best Practices']['issues'].append("Should check HTTP status codes")


def validate_named_credential(content, score):
    """Validate Named Credential XML"""
    
    # Security checks
    if '<password>' in content and '{!$Credential' in content:
        score['Security']['score'] += 15
    else:
        score['Security']['issues'].append("Named Credential should use {!$Credential.Password}")
    
    # Check for proper endpoint
    if 'https://api.bland.ai' in content:
        score['Security']['score'] += 10
    else:
        score['Security']['issues'].append("Endpoint should be https://api.bland.ai/v1")
    
    # Best practices
    if '<label>' in content:
        score['Best Practices']['score'] += 5
    
    # Give full marks for other categories if XML is well-formed
    score['Error Handling']['score'] = 25
    score['Data Management']['score'] = 20
    score['Architecture']['score'] = 20
    score['Best Practices']['score'] = 5


def validate_custom_object(content, score):
    """Validate Call__c custom object metadata"""
    
    # Check for required fields
    required_fields = ['Bland_Call_ID__c', 'Status__c', 'Phone_Number__c', 'Duration__c']
    
    for field in required_fields:
        if field in content:
            score['Data Management']['score'] += 3
    
    # Check for External ID on Bland_Call_ID__c
    if '<externalId>true</externalId>' in content:
        score['Data Management']['score'] += 5
    else:
        score['Data Management']['issues'].append("Bland_Call_ID__c should be marked as External ID")
    
    # Give full marks for other categories
    score['Security']['score'] = 25
    score['Error Handling']['score'] = 25
    score['Architecture']['score'] = 20
    score['Best Practices']['score'] = 10


def print_validation_results(file_name, score, total_score, total_max):
    """Print formatted validation results"""
    
    percentage = (total_score / total_max) * 100
    
    # Determine rating
    if percentage >= 90:
        rating = "⭐⭐⭐⭐⭐ Excellent"
    elif percentage >= 80:
        rating = "⭐⭐⭐⭐ Very Good"
    elif percentage >= 70:
        rating = "⭐⭐⭐ Good"
    elif percentage >= 60:
        rating = "⭐⭐ Needs Work"
    else:
        rating = "⭐ Block - Critical Issues"
    
    print("\n" + "="*80)
    print(f"📊 BLAND.AI INTEGRATION SCORE: {total_score}/{total_max} {rating}")
    print("="*80)
    print(f"File: {file_name}")
    print()
    
    # Print category breakdown
    for category, data in score.items():
        cat_score = data['score']
        cat_max = data['max']
        cat_pct = (cat_score / cat_max) * 100 if cat_max > 0 else 0
        bar = "█" * int(cat_pct / 10) + "░" * (10 - int(cat_pct / 10))
        
        icon = "✅" if cat_pct >= 80 else "⚠️" if cat_pct >= 60 else "❌"
        print(f"{icon} {category:20s} {cat_score:2d}/{cat_max:2d}  {bar} {cat_pct:5.1f}%")
        
        # Print issues
        if data['issues']:
            for issue in data['issues']:
                print(f"   └─ {issue}")
    
    print("\n" + "="*80)
    print()
    
    # Print recommendations based on score
    if percentage < 90:
        print("📋 Recommendations:")
        if score['Security']['score'] < score['Security']['max'] * 0.8:
            print("   • Review security best practices (Named Credentials, sharing keywords)")
        if score['Error Handling']['score'] < score['Error Handling']['max'] * 0.8:
            print("   • Add comprehensive error handling and logging")
        if score['Data Management']['score'] < score['Data Management']['max'] * 0.8:
            print("   • Implement CRUD/FLS checks and bulkification")
        if score['Architecture']['score'] < score['Architecture']['max'] * 0.8:
            print("   • Use async patterns (Queueable) for callouts")
        print()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 validate_bland_integration.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    validate_integration(file_path)
