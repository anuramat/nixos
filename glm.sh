curl --location 'https://api.z.ai/api/coding/paas/v4/chat/completions' \
	--header "Authorization: Bearer $(cat /run/agenix/zai)" \
	--header 'Content-Type: application/json' \
	--data '{
    "model": "glm-5",
    "messages": [
        {
            "role": "user",
            "content": "Just say hi"
        }
    ],
    "stream": true
}'
