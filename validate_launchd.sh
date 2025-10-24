#!/bin/bash

SERVICES=("com.nexus.node" "com.inference.node" "com.gensyn.node")
PLIST_DIR="$HOME/Library/LaunchAgents"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "\n🔍 ${YELLOW}Validating launchd services...${NC}"

for SERVICE in "${SERVICES[@]}"; do
    echo -e "\n➡️  Checking $SERVICE"
    PLIST="$PLIST_DIR/$SERVICE.plist"

    if [ ! -f "$PLIST" ]; then
        echo -e "${RED}❌ Plist file not found:${NC} $PLIST"
        continue
    else
        echo -e "${GREEN}✅ Found plist:${NC} $PLIST"
    fi

    echo -e "🔄 Unloading (if loaded)..."
    launchctl bootout gui/$(id -u) "$PLIST" 2>/dev/null

    echo -e "🚀 Re-loading..."
    launchctl bootstrap gui/$(id -u) "$PLIST"
    STATUS=$?

    if [ $STATUS -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully loaded $SERVICE${NC}"
    else
        echo -e "${RED}❌ Failed to load $SERVICE (code $STATUS)${NC}"
    fi

done

echo -e "\n🧪 ${YELLOW}Dumping launchctl list...${NC}"
launchctl list | grep com. || echo -e "${RED}No launchd services found matching com.*${NC}"

echo -e "\n🎉 ${GREEN}Validation complete.${NC}"
