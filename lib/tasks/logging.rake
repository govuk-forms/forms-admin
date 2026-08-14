# frozen_string_literal: true

require "English"

Rake::Task.define_task(:environment).enhance do
  task_finished_normally = false

  at_exit do
    unless task_finished_normally
      exit_cause = $ERROR_INFO ? $ERROR_INFO.class.name : "Signal or exit"

      Rails.logger.error "Task terminated early", {
        task: Rake.application.top_level_tasks.first,
        exit_cause:,
      }
    end
  end

  Rake.application.top_level_tasks.each do |task_name|
    task_name_clean = task_name.gsub(/\[.*\]$/, "")
    next unless Rake::Task.task_defined?(task_name_clean)

    task = Rake::Task[task_name_clean]
    original_actions = task.actions.dup
    task.actions.clear

    task.enhance do |t, args|
      CurrentTaskLoggingAttributes.task_name = task_name_clean
      Rails.logger.info "Task started", { args: args.to_a }

      begin
        original_actions.each { |action| action.call(t, args) }
        Rails.logger.info "Task finished"
      rescue SystemExit => e
        Rails.logger.error "Task aborted", { exit_message: e.message }
        raise e
      rescue StandardError => e
        Rails.logger.error "Task failed", { exception: [e.class.name, e.message] }
        raise e
      ensure
        task_finished_normally = true
      end
    end
  end
end
