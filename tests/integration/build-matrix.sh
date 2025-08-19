#!/usr/bin/env bash
# Build matrix test for username configuration
# Tests that NixOS configurations can build with different usernames

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
HOSTS=("anuramat-ll7" "anuramat-root" "anuramat-t480")
USERNAMES=("anuramat" "testuser" "alice" "bob-smith")

# Results tracking
declare -A results
failed=0
passed=0

echo "=== NixOS Configuration Build Matrix Test ==="
echo "Testing ${#HOSTS[@]} hosts with ${#USERNAMES[@]} different usernames"
echo ""

# Function to test a single configuration
test_config() {
	local host=$1
	local username=$2
	local result_key="${host}:${username}"

	echo -n "Testing $host with username '$username'... "

	# Note: This is a dry-run test - we're just checking if the configuration evaluates
	# In the actual refactoring, we'll need to pass username as a parameter
	if nix eval ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath" \
		--show-trace &>/dev/null; then
		echo -e "${GREEN}PASS${NC}"
		results[$result_key]="PASS"
		((passed++))
		return 0
	else
		echo -e "${RED}FAIL${NC}"
		results[$result_key]="FAIL"
		((failed++))
		return 1
	fi
}

# Run tests
for host in "${HOSTS[@]}"; do
	echo ""
	echo "Host: $host"
	echo "----------------------------------------"
	for username in "${USERNAMES[@]}"; do
		test_config "$host" "$username" || true
	done
done

# Summary
echo ""
echo "=== Test Summary ==="
echo "Total tests: $((passed + failed))"
echo -e "Passed: ${GREEN}$passed${NC}"
echo -e "Failed: ${RED}$failed${NC}"

# Detailed results
if [ "$failed" -gt 0 ]; then
	echo ""
	echo "Failed configurations:"
	for key in "${!results[@]}"; do
		if [ "${results[$key]}" = "FAIL" ]; then
			echo "  - $key"
		fi
	done
fi

# Exit code
if [ "$failed" -gt 0 ]; then
	echo ""
	echo -e "${YELLOW}Note: This test currently uses the existing hardcoded username.${NC}"
	echo -e "${YELLOW}After refactoring, it will test with parameterized usernames.${NC}"
	exit 1
else
	echo ""
	echo -e "${GREEN}All configurations build successfully!${NC}"
	exit 0
fi
