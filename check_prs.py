import json
import urllib.request

repo = "unicomproject/Nytroz-POS-App"
url = f"https://api.github.com/repos/{repo}/pulls?state=open"

req = urllib.request.Request(url, headers={'Accept': 'application/vnd.github.v3+json'})
with urllib.request.urlopen(req) as response:
    prs = json.loads(response.read().decode())

if not prs:
    print("No open PRs found.")
else:
    for pr in prs:
        num = pr['number']
        title = pr['title']
        # Fetch detailed PR info to get mergeable status
        pr_url = f"https://api.github.com/repos/{repo}/pulls/{num}"
        pr_req = urllib.request.Request(pr_url, headers={'Accept': 'application/vnd.github.v3+json'})
        with urllib.request.urlopen(pr_req) as pr_resp:
            detail = json.loads(pr_resp.read().decode())
            
        mergeable = detail.get('mergeable')
        mergeable_state = detail.get('mergeable_state')
        
        # We can also check statuses (GitHub Actions)
        status_url = pr['statuses_url']
        status_req = urllib.request.Request(status_url, headers={'Accept': 'application/vnd.github.v3+json'})
        with urllib.request.urlopen(status_req) as status_resp:
            statuses = json.loads(status_resp.read().decode())
            
        ci_state = "No CI"
        if statuses:
            ci_state = statuses[0]['state'] # success, pending, failure, error
            
        print(f"PR #{num}: {title}")
        print(f"  Head: {detail['head']['ref']} -> Base: {detail['base']['ref']}")
        print(f"  Mergeable: {mergeable}")
        print(f"  Mergeable State: {mergeable_state}")
        print(f"  Latest CI Status: {ci_state}")
        print("-" * 40)
