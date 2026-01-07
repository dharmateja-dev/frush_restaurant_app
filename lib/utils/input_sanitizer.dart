/// Utility class for sanitizing user input to prevent XSS and injection attacks
class InputSanitizer {
  /// List of dangerous patterns to detect (script tags, event handlers, etc.)
  static final List<RegExp> _dangerousPatterns = [
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false), // onclick, onerror, etc.
    RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false),
    RegExp(r'<embed[^>]*>', caseSensitive: false),
    RegExp(r'<object[^>]*>.*?</object>', caseSensitive: false),
  ];

  /// Sanitizes input by removing or escaping dangerous content
  /// Returns sanitized string safe for storage and display
  static String sanitize(String input) {
    if (input.isEmpty) return input;

    String sanitized = input;

    // Remove or escape dangerous patterns
    for (var pattern in _dangerousPatterns) {
      sanitized = sanitized.replaceAll(pattern, '');
    }

    // Remove potentially dangerous HTML tags (keep safe ones like emphasis)
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>', multiLine: true), '');

    return sanitized.trim();
  }

  /// Validates if input contains dangerous content
  /// Returns true if dangerous patterns are detected
  static bool containsDangerousContent(String input) {
    if (input.isEmpty) return false;

    for (var pattern in _dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }

    // Check for HTML tags
    if (RegExp(r'<[^>]*>').hasMatch(input)) {
      return true;
    }

    return false;
  }

  /// Escapes special HTML characters
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
/*******************************************************************************************
* Copyright (c) 2025 Movenetics Digital. All rights reserved.
*
* This software and associated documentation files are the property of 
* Movenetics Digital. Unauthorized copying, modification, distribution, or use of this 
* Software, via any medium, is strictly prohibited without prior written permission.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
* LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
* OTHER DEALINGS IN THE SOFTWARE.
*
* Company: Movenetics Digital
* Author: Aman Bhandari 
*******************************************************************************************/
