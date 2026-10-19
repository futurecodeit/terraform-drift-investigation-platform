from github import Github

class GithubCommentBot:

    def post_comment(
            self,
            token,
            repo_name,
            pr_number,
            report):

        g = Github(token)

        repo = g.get_repo(repo_name)

        pr = repo.get_pull(pr_number)

        pr.create_issue_comment(report)