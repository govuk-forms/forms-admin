class Reports::TotalSubmissionsCloudWatchService
  REGION = "eu-west-2".freeze

  def submissions_data
    return nil unless Settings.cloudwatch_metrics_enabled
    return nil if Settings.total_submissions_baseline_cutoff_date.blank?

    datapoints = fetch_daily_datapoints
    cloudwatch_total = datapoints.values.sum
    baseline = Settings.total_submissions_baseline.to_i

    {
      all_time: { total: baseline + cloudwatch_total },
      year: {
        in_progress: year_in_progress_bucket(datapoints),
      },
      month: month_buckets(datapoints),
      week: week_buckets(datapoints),
      day: day_buckets(datapoints),
      weekly_breakdown: weekly_breakdown(datapoints),
      monthly_breakdown: monthly_breakdown(datapoints),
    }
  rescue Aws::CloudWatch::Errors::ServiceError,
         Aws::Errors::MissingCredentialsError,
         ArgumentError => e
    Sentry.capture_exception(e)
    nil
  end

private

  def fetch_daily_datapoints
    env = Settings.forms_env.downcase
    expression = "SUM(SEARCH('{Forms,Environment,FormId} MetricName=\"Submitted\" Environment=\"#{env}\"', 'Sum', 86400))"

    start_time = Date.iso8601(Settings.total_submissions_baseline_cutoff_date).beginning_of_day.utc

    response = Aws::CloudWatch::Client.new(region: REGION).get_metric_data({
      metric_data_queries: [
        {
          id: "total_submissions",
          expression:,
          label: "Total Submissions",
        },
      ],
      start_time: start_time,
      end_time: Time.zone.now.utc,
    })

    result = response.metric_data_results.find { |r| r.id == "total_submissions" }
    return {} unless result

    result.timestamps.zip(result.values).each_with_object({}) do |(timestamp, value), hash|
      hash[timestamp.to_date.iso8601] = value.to_i
    end
  end

  def sum_dates(datapoints, start_date, end_date)
    (start_date..end_date).sum { |date| datapoints[date.iso8601] || 0 }
  end

  def today
    Time.zone.today
  end

  def day_buckets(datapoints)
    yesterday = today - 1.day
    {
      completed: { label: yesterday.strftime("%-d %b %Y"), total: datapoints[yesterday.iso8601] || 0 },
      in_progress: { label: today.strftime("%-d %b %Y"), total: datapoints[today.iso8601] || 0 },
    }
  end

  def week_buckets(datapoints)
    this_week_start = today.beginning_of_week(:monday)
    last_week_end   = this_week_start - 1.day
    last_week_start = last_week_end.beginning_of_week(:monday)

    {
      completed: { label: week_label(last_week_start, last_week_end), total: sum_dates(datapoints, last_week_start, last_week_end) },
      in_progress: { label: week_label(this_week_start, today), total: sum_dates(datapoints, this_week_start, today) },
    }
  end

  def month_buckets(datapoints)
    this_month_start = today.beginning_of_month
    last_month_end   = this_month_start - 1.day
    last_month_start = last_month_end.beginning_of_month

    {
      completed: { label: last_month_start.strftime("%B %Y"), total: sum_dates(datapoints, last_month_start, last_month_end) },
      in_progress: { label: this_month_start.strftime("%B %Y"), total: sum_dates(datapoints, this_month_start, today) },
    }
  end

  def year_in_progress_bucket(datapoints)
    this_year_start = Date.new(today.year, 1, 1)

    {
      label: this_year_start.year.to_s,
      total: sum_dates(datapoints, this_year_start, today),
    }
  end

  def weekly_breakdown(datapoints)
    this_week_start = today.beginning_of_week(:monday)
    last_week_end   = this_week_start - 1.day

    (0...52).map do |i|
      week_end   = last_week_end - (i * 7)
      week_start = week_end - 6.days
      { label: week_label(week_start, week_end), total: sum_dates(datapoints, week_start, week_end) }
    end
  end

  def monthly_breakdown(datapoints)
    this_month_start = today.beginning_of_month
    (1..12).map do |i|
      month_start = this_month_start - i.months
      month_end   = month_start.end_of_month
      { label: month_start.strftime("%B %Y"), total: sum_dates(datapoints, month_start, month_end) }
    end
  end

  def week_label(start_date, end_date)
    if start_date.year != end_date.year
      "#{start_date.strftime('%-d %b %Y')}–#{end_date.strftime('%-d %b %Y')}"
    elsif start_date.month != end_date.month
      "#{start_date.strftime('%-d %b')}–#{end_date.strftime('%-d %b %Y')}"
    else
      "#{start_date.day}–#{end_date.strftime('%-d %b %Y')}"
    end
  end
end
