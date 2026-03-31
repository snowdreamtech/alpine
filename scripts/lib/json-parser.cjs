#!/usr/bin/env node
// Copyright (c) 2026 SnowdreamTech. All rights reserved.
// Licensed under the MIT License.

/**
 * json-parser.js - High-performance JSON parser for shell scripts
 *
 * Purpose:
 *   Provides robust JSON parsing with JSONPath-like query support.
 *   Replaces fragile awk-based parsing with proper JSON handling.
 *
 * Usage:
 *   node json-parser.js '<json-string>' '<query-path>'
 *   echo '<json>' | node json-parser.js '<query-path>'
 *
 * Examples:
 *   node json-parser.js '{"a":{"b":"value"}}' 'a.b'
 *   echo '{"version":"1.0"}' | node json-parser.js 'version'
 *
 * Note:
 *   This file uses CommonJS (require/module.exports) to ensure compatibility
 *   as a standalone utility script across different Node.js environments.
 */

const fs = require("fs");

/**
 * Evaluates a dot-notation query path on a JSON object.
 * @param {any} data - Parsed JSON data
 * @param {string} query - Dot-notation path (e.g., "tools.node.version")
 * @returns {any} - The value at the query path, or null if not found
 */
function evaluateQuery(data, query) {
  if (!query) return data;

  const parts = query.split(".");
  let result = data;

  for (const part of parts) {
    if (result === null || result === undefined) {
      return null;
    }

    // Support array indexing: tools[0].version
    const arrayMatch = part.match(/^(.+)\[(\d+)\]$/);
    if (arrayMatch) {
      const [, key, index] = arrayMatch;
      result = result[key];
      if (Array.isArray(result)) {
        result = result[parseInt(index, 10)];
      } else {
        return null;
      }
    } else {
      result = result[part];
    }
  }

  return result;
}

/**
 * Main entry point
 */
function main() {
  try {
    let jsonStr, query;

    // Check if reading from stdin or arguments
    if (process.stdin.isTTY) {
      // Arguments mode
      if (process.argv.length < 3) {
        process.stderr.write("Usage: json-parser.js <json-string> <query-path>\n");
        process.exit(1);
      }
      jsonStr = process.argv[2];
      query = process.argv[3] || "";
    } else {
      // Stdin mode
      jsonStr = fs.readFileSync(0, "utf-8");
      query = process.argv[2] || "";
    }

    // Parse JSON
    const data = JSON.parse(jsonStr);

    // Evaluate query
    const result = evaluateQuery(data, query);

    // Output result
    if (result !== null && result !== undefined) {
      if (typeof result === "object") {
        process.stdout.write(JSON.stringify(result));
      } else {
        process.stdout.write(String(result));
      }
    }

    process.exit(0);
  } catch (error) {
    // Silent failure - shell scripts will handle fallback
    process.exit(1);
  }
}

main();
