import requests

class TeamsBot:

    def send(self, webhook_url, report):

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

        requests.post(
            webhook_url,
            json=payload
        )