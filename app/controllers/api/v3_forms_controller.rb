class Api::V3FormsController < ApplicationController
  def index
    return head(:bad_request) unless schedule.in?(DeliveryConfiguration.delivery_schedules.keys)

    render json: Form.form_ids_and_states_with_delivery_schedule(schedule)
  end

private

  def schedule
    params.expect(:delivery_schedule)
  end
end
