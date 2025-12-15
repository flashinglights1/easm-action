#!/bin/bash

# Force Cancel All Workflows (No Confirmation)
# Emergency stop for all running/queued workflows

# Don't exit on error - we want to continue even if some fail
set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${RED}======================================${NC}"
echo -e "${RED}  FORCE CANCEL ALL WORKFLOWS          ${NC}"
echo -e "${RED}======================================${NC}"
echo ""

# Get all running and queued workflows
echo -e "${YELLOW}⚡ Getting all workflows...${NC}"

RUNNING_RUNS=$(gh run list --status in_progress --limit 1000 --json databaseId,name 2>/dev/null || echo "[]")
QUEUED_RUNS=$(gh run list --status queued --limit 1000 --json databaseId,name 2>/dev/null || echo "[]")

RUNNING_COUNT=$(echo "$RUNNING_RUNS" | jq 'length')
QUEUED_COUNT=$(echo "$QUEUED_RUNS" | jq 'length')
TOTAL_COUNT=$((RUNNING_COUNT + QUEUED_COUNT))

echo -e "   🔄 Running: ${RUNNING_COUNT}"
echo -e "   ⏳ Queued: ${QUEUED_COUNT}"
echo -e "   📝 Total: ${TOTAL_COUNT}"
echo ""

if [ "$TOTAL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ No workflows to cancel.${NC}"
    echo ""
    exit 0
fi

echo -e "${YELLOW}🛑 Cancelling ${TOTAL_COUNT} workflows in parallel...${NC}"
echo ""

# Combine all run IDs
ALL_RUN_IDS=$(echo "$RUNNING_RUNS $QUEUED_RUNS" | jq -s 'add | .[].databaseId')

# Create temp file for results
TEMP_RESULTS=$(mktemp)

# Cancel in parallel (20 at a time for speed)
echo "$ALL_RUN_IDS" | xargs -P 20 -I {} bash -c '
    if gh run cancel {} >/dev/null 2>&1; then
        echo "OK:{}"
    else
        echo "FAIL:{}"
    fi
' > "$TEMP_RESULTS" 2>&1

# Count results
CANCELLED_COUNT=$(grep -c "^OK:" "$TEMP_RESULTS" || echo 0)
FAILED_COUNT=$(grep -c "^FAIL:" "$TEMP_RESULTS" || echo 0)

# Show sample of cancelled
echo -e "${GREEN}✅ Cancelled workflows (showing first 10):${NC}"
grep "^OK:" "$TEMP_RESULTS" | head -10 | sed 's/OK:/   /'

if [ "$FAILED_COUNT" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⏭️  Skipped workflows (already completed/cancelled):${NC}"
    grep "^FAIL:" "$TEMP_RESULTS" | head -5 | sed 's/FAIL:/   /'
    if [ "$FAILED_COUNT" -gt 5 ]; then
        echo "   ... and $((FAILED_COUNT - 5)) more"
    fi
fi

# Cleanup
rm -f "$TEMP_RESULTS"

echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}  Summary                             ${NC}"
echo -e "${CYAN}======================================${NC}"
echo -e "${GREEN}✅ Successfully cancelled: ${CANCELLED_COUNT}${NC}"
echo -e "${RED}❌ Failed to cancel: ${FAILED_COUNT}${NC}"
echo -e "${YELLOW}📊 Total processed: ${TOTAL_COUNT}${NC}"
echo ""

if [ "$CANCELLED_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Cancellation complete!${NC}"
else
    echo -e "${YELLOW}⚠️  No workflows were cancelled (they may already be completed/cancelled)${NC}"
fi

echo ""
