# Thanks to Matt Greensmith! http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/
require 'octokit'
require 'base64'

# Setup
octokit = Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'])
repo = 'ClydeDroid/octokit-testing'
master_ref = 'heads/master'
latest_commit_sha = octokit.ref(repo, master_ref).object.sha
base_tree_sha = octokit.commit(repo, latest_commit_sha).commit.tree.sha

# Get base text file and edit
base_file = octokit.content(repo, path: 'test.txt')
base_content = Base64.decode64(base_file.content)
edit_count = base_content.scan(/\d/)[0].to_i + 1
new_base_content = base_content.gsub(/\d/, edit_count.to_s)

# Create git objects
blob_sha = octokit.create_blob(repo, Base64.encode64(new_base_content), 'base64')
new_tree_sha = octokit.create_tree(
  repo,
  [{
    path: 'test.txt',
    mode: '100644',
    type: 'blob',
    sha: blob_sha
  }],
  base_tree: base_tree_sha
).sha

# Commit to master on GitHub
commit_message = 'Edit test.txt and commit via Octokit!'
new_commit_sha = octokit.create_commit(
  repo,
  commit_message,
  new_tree_sha,
  latest_commit_sha
).sha
updated_master_ref = octokit.update_ref(repo, master_ref, new_commit_sha)
