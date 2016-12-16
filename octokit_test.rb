# Thanks to Matt Greensmith! http://mattgreensmith.net/2013/08/08/commit-directly-to-github-via-api-with-octokit/
require 'octokit'
require 'base64'
require 'dotenv'

# Setup
Dotenv.load
octokit = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
repo = "#{ENV['GITHUB_USERNAME']}/octokit-testing"
master_ref = 'heads/master'
latest_commit_sha = octokit.ref(repo, master_ref).object.sha
base_tree_sha = octokit.commit(repo, latest_commit_sha).commit.tree.sha

# Get base text file and edit
file = octokit.content(repo, path: 'test.txt')
content = Base64.decode64(file.content)
edit_count = content.scan(/\d/)[0].to_i + 1
new_content = content.gsub(/\d/, edit_count.to_s)
base_blob_sha = octokit.create_blob(repo, Base64.encode64(new_content), 'base64')

# Get text file in dir and edit
file = octokit.content(repo, path: 'dir/original-test.txt')
content = Base64.decode64(file.content)
edit_count = content.scan(/\d/)[0].to_i + 1
new_content = content.gsub(/\d/, edit_count.to_s)
dir_blob_sha = octokit.create_blob(repo, Base64.encode64(new_content), 'base64')

# Create new file in dir
content = "I am new file ##{edit_count}!"
new_file_path = "dir/test-#{edit_count}.txt"
new_blob_sha = octokit.create_blob(repo, Base64.encode64(content), 'base64')

# Create tree objects
new_tree_sha = octokit.create_tree(
  repo,
  [
    {
      path: 'test.txt',
      mode: '100644',
      type: 'blob',
      sha: base_blob_sha
    },
    {
      path: 'dir/original-test.txt',
      mode: '100644',
      type: 'blob',
      sha: dir_blob_sha
    },
    {
      path: new_file_path,
      mode: '100644',
      type: 'blob',
      sha: new_blob_sha
    }
  ],
  base_tree: base_tree_sha
).sha

# Commit to new branch on GitHub
commit_message = "Commit via Octokit! (Edit ##{edit_count})"
new_commit_sha = octokit.create_commit(
  repo,
  commit_message,
  new_tree_sha,
  latest_commit_sha
).sha
new_branch_ref = "heads/edit-#{edit_count}"
octokit.create_ref(repo, new_branch_ref, new_commit_sha)

# Submit a pull request
octokit.create_pull_request(
  repo,
  'master',
  "edit-#{edit_count}",
  "Edit ##{edit_count}",
  "Edit ##{edit_count}, submitted by running octokit.rb"
)
