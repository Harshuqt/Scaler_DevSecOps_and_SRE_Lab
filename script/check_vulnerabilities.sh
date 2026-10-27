
#!/bin/bash

# Check whether jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is not installed."
    exit 1
fi

# Check that reports exist and contain valid JSON
for report in bandit-report.json trivy-report.json; do
    if [[ ! -f "$report" ]]; then
        echo "ERROR: Report not found: $report"
        exit 1
    fi

    if ! jq empty "$report" >/dev/null 2>&1; then
        echo "ERROR: Invalid JSON in $report"
        exit 1
    fi
done

# Check Bandit for High vulnerabilities
if jq -e '.results[]? | select(.issue_severity == "HIGH")' bandit-report.json >/dev/null; then
    echo "FAIL: High severity SAST vulnerability found."
    exit 1
fi

# Check Trivy for High or Critical vulnerabilities
if jq -e '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL")' trivy-report.json >/dev/null; then
    echo "FAIL: High or Critical container vulnerability found."
    exit 1
fi

echo "PASS: No High or Critical vulnerabilities found."
exit 0