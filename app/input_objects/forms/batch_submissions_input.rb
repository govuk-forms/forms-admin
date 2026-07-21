class Forms::BatchSubmissionsInput < BaseInput
  attr_accessor :form, :batch_frequencies

  def submit
    @delivery_configurations_before = batch_delivery_configuration_snapshot
    selected_frequencies = Array(batch_frequencies)

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

  def delivery_configurations_changed?
    @delivery_configurations_before != batch_delivery_configuration_snapshot
  end

  def assign_form_values
    self.batch_frequencies ||= []
    self.batch_frequencies << "daily" if form.delivery_configurations.daily.any?
    self.batch_frequencies << "weekly" if form.delivery_configurations.weekly.any?
    self
  end

private

  def batch_delivery_configuration_snapshot
    form.delivery_configurations
      .where(delivery_method: "email", delivery_schedule: %w[daily weekly])
      .pluck(:delivery_method, :delivery_schedule, :formats)
      .sort
  end
end
