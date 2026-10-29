import json
from urllib.error import HTTPError
from urllib.parse import urlparse
from urllib.request import Request, urlopen

class TeamsBot:

    def send(self, webhook_url, report):
      if urlparse(webhook_url).scheme != "https":
          raise ValueError("The Teams workflow webhook must use HTTPS.")

        payload = {

            "type":"message",

            "attachments":[
              {
                "contentType":
                    "application/vnd.microsoft.card.adaptive",

                "content":{
                  "type":"AdaptiveCard",
                  "version":"1.5",
                  "body":[
                     {
                       "type":"TextBlock",
                       "text":report
                     }
                  ]
                }
              }
            ]
        }

        request = Request(
          webhook_url,
          data=json.dumps(payload).encode("utf-8"),
          headers={"Content-Type": "application/json"},
          method="POST",
        )
        try:
          with urlopen(request, timeout=15) as response:
            return response.status
        except HTTPError as error:
          raise RuntimeError(f"Teams workflow request failed with HTTP {error.code}.") from error