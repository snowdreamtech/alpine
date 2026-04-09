#!/usr/bin/env sh
# Test sed regex compatibility across platforms

echo "=== Testing sed -E compatibility ==="

# Test 1: Simple string extraction
TEST1='"tool" = "1.0.0"'
RESULT1=$(echo "$TEST1" | sed -E 's/^[^=]*=[[:space:]]*"([^"]*)".*/\1/')
echo "Test 1 (simple): $TEST1"
echo "  Result: $RESULT1"
echo "  Expected: 1.0.0"
[ "$RESULT1" = "1.0.0" ] && echo "  ✓ PASS" || echo "  ✗ FAIL"

# Test 2: TOML table extraction
TEST2='"github:checkmake/checkmake" = { version = "v0.3.2", bin = "checkmake" }'
RESULT2=$(echo "$TEST2" | sed -E 's/.*version[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/')
echo ""
echo "Test 2 (table): $TEST2"
echo "  Result: $RESULT2"
echo "  Expected: v0.3.2"
[ "$RESULT2" = "v0.3.2" ] && echo "  ✓ PASS" || echo "  ✗ FAIL"

# Test 3: Empty version
TEST3='"tool" = { version = "", bin = "tool" }'
RESULT3=$(echo "$TEST3" | sed -E 's/.*version[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/')
echo ""
echo "Test 3 (empty): $TEST3"
echo "  Result: '$RESULT3'"
echo "  Expected: '' (empty string)"
[ -z "$RESULT3" ] && echo "  ✓ PASS" || echo "  ✗ FAIL"

# Test 4: Version with spaces
TEST4='"tool" = { version = "1.0.0" , bin = "tool" }'
RESULT4=$(echo "$TEST4" | sed -E 's/.*version[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/')
echo ""
echo "Test 4 (spaces): $TEST4"
echo "  Result: $RESULT4"
echo "  Expected: 1.0.0"
[ "$RESULT4" = "1.0.0" ] && echo "  ✓ PASS" || echo "  ✗ FAIL"

# Test 5: Basename extraction
TEST5="github:foo/bar"
RESULT5=$(echo "$TEST5" | sed -E 's/^[^:]+://; s/.*\///')
echo ""
echo "Test 5 (basename): $TEST5"
echo "  Result: $RESULT5"
echo "  Expected: bar"
[ "$RESULT5" = "bar" ] && echo "  ✓ PASS" || echo "  ✗ FAIL"

echo ""
echo "=== Platform Info ==="
echo "OS: $(uname -s)"
echo "sed version:"
sed --version 2>&1 | head -1 || echo "BSD sed (no --version)"
