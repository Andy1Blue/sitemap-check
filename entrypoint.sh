#!/bin/bash

SITEMAP_URL="${INPUT_SITEMAP_URL}"
EXCLUDE="${INPUT_EXCLUDE}"
SLACK_CHANNEL="${INPUT_SLACK_CHANNEL}"
SLACK_TOKEN="${INPUT_SLACK_TOKEN}"

if [[ -n "${GITHUB_MATRIX_LOCALE}" ]]; then
  SITEMAP_URL="${SITEMAP_URL//\{locale\}/${GITHUB_MATRIX_LOCALE}}"
fi

echo "Sitemap URL: $SITEMAP_URL"

urls=$(curl -s "$SITEMAP_URL" | awk -F '[<>]' '/<loc>/{print $3}' | tr -d '\r')

if [[ -z "$urls" ]]; then
    echo "ERROR: No URLs found in the sitemap!"
    exit 1
fi

total=0
success=0
fail=0
errors=""

EXCLUDE_LIST=$(echo "${EXCLUDE}" | tr ',' '|')

for url in $urls; do
    ((total++))
    if [[ "$url" =~ $EXCLUDE_LIST ]]; then
        echo "Excluding: $url"
        continue
    fi
    echo "Checking: $url"
    http_status=$(curl --max-time 30 -o /dev/null -s -w "%{http_code}" "$url" || echo "error")

    if [[ "$http_status" =~ ^[0-9]{3}$ ]]; then
        if [ "$http_status" -eq 200 ]; then
            ((success++))
        else
            ((fail++))
            errors+="❌ $url (HTTP $http_status)\n"
        fi
    else
        ((fail++))
        errors+="❌ $url (Failed to fetch)\n"
    fi
done

summary="🌐 $SITEMAP_URL\n🔍 Total Pages: $total\n✅ Success: $success\n❌ Errors: $fail\n\n$errors"
echo -e "$summary" > result.txt

echo "Summary: $summary"

curl -X POST "https://slack.com/api/chat.postMessage" \
  -H "Content-type: application/json" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  --data "{
    \"channel\": \"$SLACK_CHANNEL\",
    \"text\": \":world_map: Sitemap Check Results:\n\n$summary\n\nFull logs: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"
  }"

exit 0
