#!/bin/bash
BUCKET="cowrie-logs-156168428597"
DATE=$(date +%Y/%m/%d/%H-%M)
TMPFILE="/tmp/cowrie-$(date +%s).json"

docker logs cowrie --since 5m 2>/dev/null | grep -v "^$" > "$TMPFILE"

if [ -s "$TMPFILE" ]; then
  aws s3 cp "$TMPFILE" "s3://$BUCKET/cowrie/$DATE/cowrie.log" --region eu-central-1
fi

rm -f "$TMPFILE"
