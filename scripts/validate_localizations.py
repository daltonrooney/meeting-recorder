#!/usr/bin/env python3
"""
Validates the String Catalog for completeness and consistency.

This script checks:
1. All keys have translations for all target languages
2. JSON format is valid
3. No placeholder/untranslated strings remain
4. Format placeholders are consistent across languages

Exit codes:
0 - All validations passed
1 - Missing translations
2 - Invalid JSON
3 - Placeholder values found
4 - Format placeholder mismatches
"""

import json
import sys
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple


# Target languages (excluding base language 'en')
TARGET_LANGUAGES = ['es', 'fr', 'de', 'ja', 'zh-Hans']
ALL_LANGUAGES = ['en'] + TARGET_LANGUAGES

# Format placeholder patterns
FORMAT_PLACEHOLDER_PATTERN = re.compile(r'%[@df]|%.0f')


def load_string_catalog(catalog_path: Path) -> Dict:
    """Load and parse the String Catalog JSON file."""
    try:
        with open(catalog_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ ERROR: Invalid JSON format in {catalog_path}")
        print(f"   {e}")
        sys.exit(2)
    except FileNotFoundError:
        print(f"❌ ERROR: String Catalog not found at {catalog_path}")
        sys.exit(2)


def check_missing_translations(catalog: Dict) -> List[str]:
    """Check for keys missing translations in any target language."""
    errors = []
    strings = catalog.get('strings', {})

    for key, value in strings.items():
        localizations = value.get('localizations', {})

        # Check each target language
        for lang in ALL_LANGUAGES:
            if lang not in localizations:
                errors.append(f"Key '{key}' is missing '{lang}' translation")
            else:
                # Check that the localization has a stringUnit
                string_unit = localizations[lang].get('stringUnit', {})
                if not string_unit:
                    errors.append(f"Key '{key}' has invalid '{lang}' localization structure")
                elif not string_unit.get('value'):
                    errors.append(f"Key '{key}' has empty '{lang}' translation value")

    return errors


def check_placeholder_values(catalog: Dict) -> List[str]:
    """Check for placeholder or untranslated values in non-English localizations."""
    errors = []
    strings = catalog.get('strings', {})

    # Common placeholder indicators
    placeholder_indicators = [
        'placeholder',
        'todo',
        'FIXME',
        'TBD',
        'XXX',
    ]

    # Keys that are expected to have identical values across languages
    # (separators, symbols, etc.)
    identical_value_allowed = [
        'transcript.header.separator',
    ]

    for key, value in strings.items():
        localizations = value.get('localizations', {})

        # Get English value for comparison
        en_value = localizations.get('en', {}).get('stringUnit', {}).get('value', '')

        # Check non-English translations
        for lang in TARGET_LANGUAGES:
            if lang not in localizations:
                continue

            translation = localizations[lang].get('stringUnit', {}).get('value', '')

            # Check for placeholder indicators
            for indicator in placeholder_indicators:
                if indicator.lower() in translation.lower():
                    errors.append(f"Key '{key}' has placeholder value in '{lang}': '{translation}'")
                    break

            # Check if non-English translation is identical to English (suspicious)
            # Skip keys that are expected to be the same (like numbers, symbols, separators)
            if translation == en_value and len(translation) > 20 and key not in identical_value_allowed:
                # Only flag longer strings that are suspiciously identical
                errors.append(f"Key '{key}' has identical '{lang}' translation to English (possible untranslated): '{translation}'")

    return errors


def extract_format_placeholders(text: str) -> Set[str]:
    """Extract format placeholders from a string."""
    return set(FORMAT_PLACEHOLDER_PATTERN.findall(text))


def check_format_placeholder_consistency(catalog: Dict) -> List[str]:
    """Check that format placeholders are consistent across all translations."""
    errors = []
    strings = catalog.get('strings', {})

    for key, value in strings.items():
        localizations = value.get('localizations', {})

        # Get English placeholders as reference
        en_value = localizations.get('en', {}).get('stringUnit', {}).get('value', '')
        en_placeholders = extract_format_placeholders(en_value)

        # Skip keys without format placeholders
        if not en_placeholders:
            continue

        # Check each language has the same placeholders
        for lang in TARGET_LANGUAGES:
            if lang not in localizations:
                continue

            translation = localizations[lang].get('stringUnit', {}).get('value', '')
            lang_placeholders = extract_format_placeholders(translation)

            if lang_placeholders != en_placeholders:
                errors.append(
                    f"Key '{key}' has inconsistent format placeholders in '{lang}':\n"
                    f"   English: {sorted(en_placeholders)}\n"
                    f"   {lang}: {sorted(lang_placeholders)}"
                )

    return errors


def main():
    """Main validation function."""
    # Locate the String Catalog
    catalog_path = Path(__file__).parent.parent / 'CallTranscription' / 'Resources' / 'Localizable.xcstrings'

    print(f"🔍 Validating String Catalog: {catalog_path}")
    print()

    # Load the catalog
    catalog = load_string_catalog(catalog_path)

    # Get total key count
    total_keys = len(catalog.get('strings', {}))
    print(f"📊 Total keys: {total_keys}")
    print(f"🌍 Target languages: {', '.join(ALL_LANGUAGES)}")
    print()

    # Run validations
    all_errors = []

    # 1. Check for missing translations
    print("✓ Checking for missing translations...")
    missing_errors = check_missing_translations(catalog)
    if missing_errors:
        all_errors.extend(missing_errors)
        print(f"  ❌ Found {len(missing_errors)} missing translation(s)")
    else:
        print(f"  ✅ All {total_keys} keys have complete translations")

    # 2. Check for placeholder values
    print("✓ Checking for placeholder values...")
    placeholder_errors = check_placeholder_values(catalog)
    if placeholder_errors:
        all_errors.extend(placeholder_errors)
        print(f"  ❌ Found {len(placeholder_errors)} placeholder value(s)")
    else:
        print("  ✅ No placeholder values found")

    # 3. Check format placeholder consistency
    print("✓ Checking format placeholder consistency...")
    format_errors = check_format_placeholder_consistency(catalog)
    if format_errors:
        all_errors.extend(format_errors)
        print(f"  ❌ Found {len(format_errors)} format placeholder inconsistency(ies)")
    else:
        print("  ✅ All format placeholders are consistent")

    print()

    # Report results
    if all_errors:
        print(f"❌ VALIDATION FAILED: {len(all_errors)} error(s) found")
        print()
        print("Errors:")
        for i, error in enumerate(all_errors, 1):
            print(f"{i}. {error}")

        # Determine exit code based on error types
        if missing_errors:
            sys.exit(1)
        elif placeholder_errors:
            sys.exit(3)
        elif format_errors:
            sys.exit(4)
    else:
        print("✅ VALIDATION PASSED: All checks successful!")
        print(f"   {total_keys} keys × {len(ALL_LANGUAGES)} languages = {total_keys * len(ALL_LANGUAGES)} string units validated")
        sys.exit(0)


if __name__ == '__main__':
    main()
