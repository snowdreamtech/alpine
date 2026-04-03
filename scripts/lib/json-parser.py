#!/usr/bin/env python3
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License.

"""
json-parser.py - High-performance JSON parser for shell scripts

Purpose:
    Provides robust JSON parsing with query path support.
    Fallback when Node.js is not available.

Usage:
    python3 json-parser.py '<json-string>' '<query-path>'
    echo '<json>' | python3 json-parser.py '<query-path>'

Examples:
    python3 json-parser.py '{"a":{"b":"value"}}' 'a.b'
    echo '{"version":"1.0"}' | python3 json-parser.py 'version'
"""

import json
import re
import sys


def evaluate_query(data, query):
    """
    Evaluates a dot-notation query path on a JSON object.

    Args:
        data: Parsed JSON data
        query: Dot-notation path (e.g., "tools.node.version")

    Returns:
        The value at the query path, or None if not found
    """
    if not query:
        return data

    parts = query.split(".")
    result = data

    for part in parts:
        if result is None:
            return None

        # Support array indexing: tools[0].version
        array_match = re.match(r"^(.+)\[(\d+)\]$", part)
        if array_match:
            key, index = array_match.groups()
            if isinstance(result, dict) and key in result:
                result = result[key]
                if isinstance(result, list):
                    idx = int(index)
                    if 0 <= idx < len(result):
                        result = result[idx]
                    else:
                        return None
                else:
                    return None
            else:
                return None
        else:
            if isinstance(result, dict):
                result = result.get(part)
            else:
                return None

    return result


def main():
    """Main entry point"""
    try:
        # Check if reading from stdin or arguments
        if sys.stdin.isatty():
            # Arguments mode
            if len(sys.argv) < 2:
                sys.stderr.write("Usage: json-parser.py <json-string> <query-path>\n")
                sys.exit(1)
            json_str = sys.argv[1]
            query = sys.argv[2] if len(sys.argv) > 2 else ""
        else:
            # Stdin mode
            json_str = sys.stdin.read()
            query = sys.argv[1] if len(sys.argv) > 1 else ""

        # Parse JSON with error handling
        data = json.loads(json_str)

        # Evaluate query
        result = evaluate_query(data, query)

        # Output result - handle None values gracefully
        if result is not None:
            if isinstance(result, (dict, list)):
                sys.stdout.write(json.dumps(result))
            else:
                sys.stdout.write(str(result))

        sys.exit(0)
    except json.JSONDecodeError:
        # JSON parsing error - silent failure for shell script fallback
        sys.exit(1)
    except Exception:
        # Any other error - silent failure for shell script fallback
        sys.exit(1)


if __name__ == "__main__":
    main()
