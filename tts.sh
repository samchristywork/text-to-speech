#!/bin/bash

source .env

OUTPUT_FILE="output.mp3"
LANGUAGE_CODE="en-US"
SPEAKING_RATE="1.0"
PITCH="0.0"

usage() {
  echo "Usage: $0 [-o output_file] [-l language_code] [-r speaking_rate] [-p pitch]"
  echo "  -o output_file    Specify the output file name (default: output.mp3)"
  echo "  -l language_code  Specify the language code (e.g., en-US, es-ES, fr-FR, default: en-US)"
  echo "  -r speaking_rate  Specify the speaking rate (default: 1.0)"
  echo "  -p pitch          Specify the pitch (default: 0.0)"
  echo "  -h                Display this help message"
  exit 1
}

while getopts "o:l:r:p:h" opt; do
  case "$opt" in
    o)
      OUTPUT_FILE="$OPTARG"
      ;;
    l)
      LANGUAGE_CODE="$OPTARG"
      ;;
    r)
      SPEAKING_RATE="$OPTARG"
      ;;
    p)
      PITCH="$OPTARG"
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$TTS_API_KEY" ]; then
  echo "Error: TTS_API_KEY environment variable not set." >&2
  exit 1
fi

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
    "languageCode":"$LANGUAGE_CODE"
  },
  "audioConfig":{
    "audioEncoding":"MP3",
    "speakingRate": $SPEAKING_RATE,
    "pitch": $PITCH
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
