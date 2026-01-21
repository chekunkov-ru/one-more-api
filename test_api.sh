#!/bin/bash

# Simple script to check if the Telegram Bot API server is responding
SERVER_URL=${1:-"http://localhost:8081"}

echo "Checking Telegram Bot API server at $SERVER_URL..."

# Attempt to get some response from the server
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVER_URL")

if [ "$RESPONSE" == "404" ] || [ "$RESPONSE" == "200" ]; then
    echo "✅ Server is responding (HTTP $RESPONSE)."
else
    echo "❌ Server is not responding correctly (HTTP $RESPONSE)."
    exit 1
fi
