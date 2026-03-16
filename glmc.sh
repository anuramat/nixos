curl \
	--header 'Content-Type: application/json' \
	--header "Authorization: Bearer $(cat /run/agenix/cerebras)" \
	--location 'https://api.cerebras.ai/v1/chat/completions' \
	--header 'Content-Type: application/json' \
	--data '{
    "model": "zai-glm-4.7",
    "messages": [
        {
            "role": "user",
            "content": "Just say hi"
        }
    ],
"stream": true
}'
