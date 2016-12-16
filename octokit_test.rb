require 'octokit'
require 'base64'

# Setup
octokit = Octokit::Client.new(access_token: ENV['GITHUB_API_TOKEN'])
repo = 'ClydeDroid/octokit-testing'
