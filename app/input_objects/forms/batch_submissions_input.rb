class Forms::BatchSubmissionsInput < BaseInput
  attr_accessor :form, :batch_frequencies

  def submit
    selected_frequencies = Array(batch_frequencies)

    form.send_daily_submission_batch = selected_frequencies.include?("daily")
    form.send_weekly_submission_batch = selected_frequencies.include?("weekly")

    %w[daily weekly].each do |frequency|
      if selected_frequencies.include?(frequency)
        form.delivery_configurations.find_or_create_by!(delivery_method: "email", delivery_schedule: frequency, formats: %w[csv])
      else
        form.delivery_configurations.where(delivery_method: "email", delivery_schedule: frequency).destroy_all
      end
    end

    form.delivery_configurations.reload
    form.save_draft!
  end

  def assign_form_values
    self.batch_frequencies ||= []
    self.batch_frequencies << "daily" if form.send_daily_submission_batch
    self.batch_frequencies << "weekly" if form.send_weekly_submission_batch
    self
  end
end
