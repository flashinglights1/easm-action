#!/bin/bash

# Nuclei Mass Scale Monitor Script
# This script monitors all nuclei-mass-scan workflows and provides detailed status

set -e

REPO="osamahamad/idea"
WORKFLOW="nuclei-mass-scan.yml"
LIMIT=${1:-50}  # Default limit of 50, can be overridden with first argument

echo "🔍 Nuclei Mass Scale Monitor"
echo "================================"
echo "Repository: $REPO"
echo "Workflow: $WORKFLOW"
echo "Limit: $LIMIT workflows"
echo "Started at: $(date)"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "   echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "   sudo apt update && sudo apt install gh -y"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub. Please run: gh auth login"
    exit 1
fi

echo "📊 Fetching workflow status..."

# Get workflows with different statuses
echo "🟡 Running workflows:"
RUNNING_COUNT=$(gh run list --repo $REPO --workflow=$WORKFLOW --status=in_progress --limit $LIMIT --json databaseId,number,status,createdAt,displayTitle --jq '.[]' 2>/dev/null | jq -s 'length' || echo "0")
if [ "$RUNNING_COUNT" -gt 0 ]; then
    gh run list --repo $REPO --workflow=$WORKFLOW --status=in_progress --limit $LIMIT --json number,status,createdAt,displayTitle --jq '.[] | "  - Run #\(.number): \(.displayTitle) (Started: \(.createdAt))"'
else
    echo "  No running workflows"
fi

echo ""
echo "⏳ Queued workflows:"
QUEUED_COUNT=$(gh run list --repo $REPO --workflow=$WORKFLOW --status=queued --limit $LIMIT --json databaseId,number,status,createdAt,displayTitle --jq '.[]' 2>/dev/null | jq -s 'length' || echo "0")
if [ "$QUEUED_COUNT" -gt 0 ]; then
    gh run list --repo $REPO --workflow=$WORKFLOW --status=queued --limit $LIMIT --json number,status,createdAt,displayTitle --jq '.[] | "  - Run #\(.number): \(.displayTitle) (Queued: \(.createdAt))"'
else
    echo "  No queued workflows"
fi

echo ""
echo "✅ Completed workflows:"
COMPLETED_COUNT=$(gh run list --repo $REPO --workflow=$WORKFLOW --status=completed --limit $LIMIT --json databaseId,number,status,createdAt,displayTitle,conclusion --jq '.[]' 2>/dev/null | jq -s 'length' || echo "0")
if [ "$COMPLETED_COUNT" -gt 0 ]; then
    gh run list --repo $REPO --workflow=$WORKFLOW --status=completed --limit $LIMIT --json number,status,createdAt,displayTitle,conclusion --jq '.[] | "  - Run #\(.number): \(.displayTitle) (Completed: \(.createdAt), Conclusion: \(.conclusion))"'
else
    echo "  No completed workflows"
fi

echo ""
echo "❌ Failed workflows:"
FAILED_COUNT=$(gh run list --repo $REPO --workflow=$WORKFLOW --status=failure --limit $LIMIT --json databaseId,number,status,createdAt,displayTitle,conclusion --jq '.[]' 2>/dev/null | jq -s 'length' || echo "0")
if [ "$FAILED_COUNT" -gt 0 ]; then
    gh run list --repo $REPO --workflow=$WORKFLOW --status=failure --limit $LIMIT --json number,status,createdAt,displayTitle,conclusion --jq '.[] | "  - Run #\(.number): \(.displayTitle) (Failed: \(.createdAt), Conclusion: \(.conclusion))"'
else
    echo "  No failed workflows"
fi

echo ""
echo "🚫 Cancelled workflows:"
CANCELLED_COUNT=$(gh run list --repo $REPO --workflow=$WORKFLOW --status=cancelled --limit $LIMIT --json databaseId,number,status,createdAt,displayTitle,conclusion --jq '.[]' 2>/dev/null | jq -s 'length' || echo "0")
if [ "$CANCELLED_COUNT" -gt 0 ]; then
    gh run list --repo $REPO --workflow=$WORKFLOW --status=cancelled --limit $LIMIT --json number,status,createdAt,displayTitle,conclusion --jq '.[] | "  - Run #\(.number): \(.displayTitle) (Cancelled: \(.createdAt), Conclusion: \(.conclusion))"'
else
    echo "  No cancelled workflows"
fi

# Calculate totals and percentages
TOTAL_WORKFLOWS=$((RUNNING_COUNT + QUEUED_COUNT + COMPLETED_COUNT + FAILED_COUNT + CANCELLED_COUNT))

echo ""
echo "📈 Summary:"
echo "==========="
echo "Total workflows: $TOTAL_WORKFLOWS"
echo "  - Running: $RUNNING_COUNT"
echo "  - Queued: $QUEUED_COUNT"
echo "  - Completed: $COMPLETED_COUNT"
echo "  - Failed: $FAILED_COUNT"
echo "  - Cancelled: $CANCELLED_COUNT"

if [ $TOTAL_WORKFLOWS -gt 0 ]; then
    PROGRESS_PCT=$((COMPLETED_COUNT * 100 / TOTAL_WORKFLOWS))
    echo ""
    echo "Progress: $COMPLETED_COUNT / $TOTAL_WORKFLOWS workflows completed ($PROGRESS_PCT%)"
    
    # Progress bar
    BAR_LENGTH=20
    FILLED_LENGTH=$((PROGRESS_PCT * BAR_LENGTH / 100))
    BAR=""
    for i in $(seq 1 $BAR_LENGTH); do
        if [ $i -le $FILLED_LENGTH ]; then
            BAR="${BAR}█"
        else
            BAR="${BAR}░"
        fi
    done
    echo "Progress: [$BAR] $PROGRESS_PCT%"
fi

echo ""
echo "🔗 Quick Links:"
echo "  - View all workflows: https://github.com/$REPO/actions/workflows/$WORKFLOW"
echo "  - View results branch: https://github.com/$REPO/tree/scan-results"
echo "  - Run monitor workflow: https://github.com/$REPO/actions/workflows/nuclei-mass-monitor.yml"

echo ""
echo "🔧 Useful Commands:"
echo "  # Cancel all running workflows:"
echo "  gh run list --repo $REPO --workflow=$WORKFLOW --status=in_progress --json databaseId --jq '.[].databaseId' | xargs -I {} gh run cancel {} --repo $REPO"
echo ""
echo "  # View detailed job status for a specific run:"
echo "  gh run view <RUN_ID> --repo $REPO"
echo ""
echo "  # View logs for a specific run:"
echo "  gh run view <RUN_ID> --repo $REPO --log"

echo ""
echo "✅ Monitor completed at: $(date)"
