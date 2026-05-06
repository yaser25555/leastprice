import http.client
import json

conn = http.client.HTTPSConnection("google.serper.dev")
payload = json.dumps({
  "q": "عسل",
  "gl": "sa",
  "hl": "ar"
})
headers = {
  'X-API-KEY': 'd0a501df54a101b0f588c801d00c3b88df678ef4',
  'Content-Type': 'application/json'
}
conn.request("POST", "/shopping", payload, headers)
res = conn.getresponse()
data = res.read()
print(data.decode("utf-8"))
