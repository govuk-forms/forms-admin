# frozen_string_literal: true

require "aws-sdk-codepipeline"

namespace :pipeline do
  %w[dev prod staging user-research].each do |env_name|
    namespace env_name do
      desc "Pause the pipeline in #{env_name}"
      task pause: :environment do
        pipeline_name = pipeline_name env_name

        puts "Pausing pipeline #{pipeline_name}"

        codepipeline = Aws::CodePipeline::Client.new
        pipeline_definition = codepipeline.get_pipeline(name: pipeline_name)

        unless pipeline_definition.pipeline.stages.any?
          raise "Pipeline definition has no stages"
        end

        unless pipeline_definition.pipeline.stages.count > 1
          raise "Pipeline has only one stage. It cannot be paused in a way that can be unpaused from the console if necessary."
        end

        second_stage = pipeline_definition.pipeline.stages[1]

        default_reason = "Pipeline paused by #{ENV['USER']} using rake task"
        reason = get_pause_reason(default_reason)
        codepipeline.disable_stage_transition(
          pipeline_name:,
          stage_name: second_stage.name,
          transition_type: "Inbound",
          reason:,
        )

        puts "Pipeline paused at #{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S %Z')} with reason\n\n'#{reason}'"
      end

      desc "Unpause the pipeline in #{env_name}"
      task unpause: :environment do
        pipeline_name = pipeline_name env_name

        puts "Unpausing pipeline #{pipeline_name}"

        codepipeline = Aws::CodePipeline::Client.new
        pipeline_definition = codepipeline.get_pipeline(name: pipeline_name)

        unless pipeline_definition.pipeline.stages.any?
          raise "Pipeline definition has no stages"
        end

        unless pipeline_definition.pipeline.stages.count > 1
          raise "Pipeline has only one stage. It cannot be unpaused because there is no transition from the source stage to unpause."
        end

        second_stage = pipeline_definition.pipeline.stages[1]

        codepipeline.enable_stage_transition(
          pipeline_name:,
          stage_name: second_stage.name,
          transition_type: "Inbound",
        )

        puts "Pipeline unpaused at #{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      end

      desc "Find out about the status of the pipeline in #{env_name}"
      task status: :environment do
        pipeline_name = pipeline_name env_name

        codepipeline = Aws::CodePipeline::Client.new
        pipeline_definition = codepipeline.get_pipeline_state(name: pipeline_name)

        paused_transitions = pipeline_definition.stage_states.filter_map do |stage|
          unless stage.inbound_transition_state.enabled
            [stage.stage_name, "inbound", stage.inbound_transition_state.disabled_reason]
          end
        end

        if paused_transitions.any?
          puts "#{pipeline_name} is paused in at least 1 position"
          puts ""
          paused_transitions.each do |pause|
            puts "Stage: #{pause[0]}, Transition: #{pause[1]}"
            puts "Reason: #{pause[2]}"
            puts ""
          end
        else
          puts "#{pipeline_name} is not paused"
        end
      end
    end
  end
end

def pipeline_name(env)
  "deploy-forms-admin-container-#{env}"
end

def get_pause_reason(default)
  temp_file_content = <<~MSG
    #{default}
    # Write your reason for pausing the pipeline above.
    # Any lines beginning with the hash character will
    # be ignored.
  MSG

  temp_file = Tempfile.new("pausing-pipeline")
  File.write(temp_file, temp_file_content)
  temp_file.close(false) # Close so that other processes can write it

  editor = ENV.fetch("EDITOR", "vim")

  system(
    ENV,
    "#{editor} #{temp_file.path}",
    chdir: Dir.pwd,
    in: $stdin,
    out: $stdout,
    err: $stderr,
  )

  content =
    # Can't use temp_file.read because we closed the stream
    File.read(temp_file.path)
        .split("\n")
        .reject { |line| line.start_with? "#" }
        .join("\n")

  temp_file.delete
  content
end
