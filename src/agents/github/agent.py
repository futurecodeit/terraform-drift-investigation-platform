import json
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

class GithubCommentBot:

    def post_comment(
            self,
            token,
            repo_name,
            pr_number,
            report):
        owner, separator, repository = repo_name.partition("/")
        if not token or not separator or not owner or not repository or int(pr_number) < 1:
            raise ValueError("A token, owner/repository, and positive pull request number are required.")

        url = (
            "https://api.github.com/repos/"
            f"{quote(owner, safe='')}/{quote(repository, safe='')}/issues/{int(pr_number)}/comments"
        )
        request = Request(
            url,
            data=json.dumps({"body": report}).encode("utf-8"),
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {token}",
                "X-GitHub-Api-Version": "2022-11-28",
                "Content-Type": "application/json",
                "User-Agent": "terraform-drift-investigation-platform",
            },
            method="POST",
        )
        try:
            with urlopen(request, timeout=15) as response:
                return json.loads(response.read())
        except HTTPError as error:
            raise RuntimeError(f"GitHub comment request failed with HTTP {error.code}.") from error