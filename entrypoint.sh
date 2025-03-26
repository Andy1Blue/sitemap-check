#!/bin/bash

# Pobieramy wartości z inputs
SITEMAP_URL="${INPUT_SITEMAP_URL}"
EXCLUDE="${INPUT_EXCLUDE}"
SLACK_CHANNEL="${INPUT_SLACK_CHANNEL}"
SLACK_TOKEN="${INPUT_SLACK_TOKEN}"

# Przekłada {locale} na wartość z matrix.locale
if [[ -n "${matrix_locale}" ]]; then
  SITEMAP_URL="${SITEMAP_URL//\{locale\}/${matrix_locale}}"
fi

# Debugowanie URL-a
echo "Sitemap URL: $SITEMAP_URL"

# Pobieramy URL-e z sitemap
urls=$(curl -s "$SITEMAP_URL" | awk -F '[<>]' '/<loc>/{print $3}' | tr -d '\r')

if [[ -z "$urls" ]]; then
    echo "ERROR: No URLs found in the sitemap!"
    exit 1
fi

# Sprawdzamy URL-e
total=0
success=0
fail=0
errors=""

EXCLUDE_LIST=$(echo "${EXCLUDE}" | tr ',' '|')

for url in $urls; do
    ((total++))
    # Sprawdzamy, czy URL jest na liście do wykluczenia
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

# Wysyłanie wyników na Slacka
curl -X POST -H 'Content-type: application/json' --data "{
  \"channel\": \"$SLACK_CHANNEL\",
  \"text\": \":flag-${matrix_locale}: Sitemap Check Results:\n\n$summary\n\nFull logs: $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"
}" -H "Authorization: Bearer $SLACK_TOKEN"

exit 0