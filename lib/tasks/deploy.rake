# frozen_string_literal: true

require "English"
require "json"
require "net/http"
require "shellwords"

namespace :pipeline do
  namespace :dev do
    desc "Push the commit at the tip of the current branch to the dev environment"
    task push_to_dev: :environment do
      puts "Getting Git commit..."
      git_hash = `git rev-parse HEAD`.chomp
      $CHILD_STATUS.success? or raise

      puts "Will use Git commit: #{git_hash}"
      puts "Checking commit has been pushed..."

      resp = Net::HTTP.get_response URI("https://api.github.com/repos/govuk-forms/forms-admin/commits/#{git_hash}")
      if resp.code != "200"
        puts "Commit has not been pushed. The pipelines will not be able to find it."
        puts "Push the commit and run the command again."
        raise
      end
      puts "The commit is present in the remote"

      push_commit_to_dev(git_hash)
    end

    desc "Push the commit at the tip of origin/main to the dev environment"
    task reset_dev_to_main: :environment do
      puts "Updating Git remotes"
      sh "git", "fetch", verbose: false

      git_hash = `git rev-parse origin/main`.chomp
      $CHILD_STATUS.success? or raise

      puts "Will use Git commit from tip of origin/main: #{git_hash}"

      push_commit_to_dev(git_hash)
    end
  end
end

def push_commit_to_dev(git_hash)
  json_input = {
    name: "forms-admin-image-builder",
    sourceRevisions: [
      {
        actionName: "get-forms-admin",
        revisionType: "COMMIT_ID",
        revisionValue: git_hash,
      },
    ],
    variables: [
      {
        name: "tag_prefix",
        value: "dev-",
      },
    ],
  }

  puts ""
  puts "Starting pipeline 'forms-admin-image-builder' in the 'deploy' account"
  pp json_input

  cli_input = JSON.dump(json_input)
  command_args = [
    "aws",
    "codepipeline",
    "start-pipeline-execution",
    "--name",
    "forms-admin-image-builder",
    "--cli-input-json",
    cli_input,
  ]
  sh_aws(*command_args)
end

def sh_aws(*cmd)
  all_args = ["gds", "aws", "forms-deploy-support", "--", *cmd]
  system({ **ENV, "AWS_VAULT" => nil }, *all_args, exception: true)
end
