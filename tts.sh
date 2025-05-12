#!/bin/bash

source .env

if [ -z "$TTS_API_KEY" ]; then
  echo "Error: TTS_API_KEY environment variable not set." >&2
  exit 1
fi

OUTPUT_FILE="output.mp3"

TEXT=$(cat)

if [ -z "$TEXT" ]; then
  echo "Error: No text provided via stdin." >&2
  exit 1
fi

PAYLOAD=$(cat <<EOF
{
  "input":{
    "text":"$TEXT"
  },
  "voice":{
    "languageCode":"en-US"
  },
  "audioConfig":{
    "audioEncoding":"MP3",
    "speakingRate": 1.0,
    "pitch": 0.0
  }
}
EOF
)

CONTENT=$(curl -s -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  -H "X-Goog-Api-Key: $TTS_API_KEY" \
  -d "$PAYLOAD" \
  "https://texttospeech.googleapis.com/v1/text:synthesize")

AUDIO_CONTENT=$(echo "$CONTENT" | jq -r '.audioContent')

if [[ "$AUDIO_CONTENT" == *"error"* ]]; then
  echo "Error: Google Text-to-Speech API returned an error:" >&2
  echo "$AUDIO_CONTENT" >&2
  exit 1
fi

if [ -n "$AUDIO_CONTENT" ]; then
  echo "$AUDIO_CONTENT" | base64 -d > "$OUTPUT_FILE"
  echo "Audio saved to: $OUTPUT_FILE"
else
  echo "Error: No audio content received from the API." >&2
  exit 1
fi
