require "rails_helper"

describe Reports::TotalSubmissionsCloudWatchService do
  subject(:service) { described_class.new }

  # Travel to a known Thursday so all date calculations are deterministic.
  # today      = 2026-04-23 (Thu)
  # yesterday  = 2026-04-22 (Wed)  — completed day
  # this week  = Mon 2026-04-20 … Thu 2026-04-23
  # last week  = Mon 2026-04-13 … Sun 2026-04-19  — completed week
  # this month = Apr 2026
  # last month = Mar 2026  — completed month
  # this year  = 2026
  # last year  = 2025  — completed year
  around do |example|
    travel_to(Time.zone.local(2026, 4, 23, 10, 0, 0)) { example.run }
  end

  let(:cloud_watch_client) { Aws::CloudWatch::Client.new(stub_responses: true) }

  # The cutoff date for the baseline. All CloudWatch queries will start from this date.
  let(:baseline_cutoff_date) { "2025-02-01" } # Chosen to be within the 14/15-month CloudWatch retention period from our test date.

  # Fixture datapoints.  The hash below is what get_metric_data returns.
  # These datapoints are now all *after* the baseline_cutoff_date.
  # dates and their counts:
  #   2026-04-23 => 5    (today)
  #   2026-04-22 => 10   (yesterday / completed day)
  #   2026-04-19 => 7    (Sun, last week end)
  #   2026-04-13 => 7    (Mon, last week start)
  #   2026-03-15 => 30   (in March / completed month)
  # cloudwatch_total = 5+10+7+7+30 = 59
  # all_time = 100 (baseline) + 59 = 159

  let(:fixture_timestamps) do
    [
      Time.utc(2026, 4, 23),
      Time.utc(2026, 4, 22),
      Time.utc(2026, 4, 19),
      Time.utc(2026, 4, 13),
      Time.utc(2026, 3, 15),
    ]
  end

  let(:fixture_values) { [5.0, 10.0, 7.0, 7.0, 30.0] }

  before do
    allow(Settings).to receive_messages(
      cloudwatch_metrics_enabled: true,
      forms_env: "test",
      total_submissions_baseline_cutoff_date: baseline_cutoff_date,
      total_submissions_baseline: 100,
    )

    allow(Aws::CloudWatch::Client).to receive(:new).with(region: "eu-west-2").and_return(cloud_watch_client)
    allow(cloud_watch_client).to receive(:get_metric_data)
  end

  def stub_cloudwatch(timestamps: fixture_timestamps, values: fixture_values)
    response = cloud_watch_client.stub_data(:get_metric_data, metric_data_results: [
      {
        id: "total_submissions",
        label: "Total Submissions",
        timestamps:,
        values:,
        status_code: "Complete",
      },
    ])
    allow(cloud_watch_client).to receive(:get_metric_data).and_return(response)
  end

  describe "#submissions_data" do
    context "when cloudwatch_metrics_enabled is false" do
      before { allow(Settings).to receive(:cloudwatch_metrics_enabled).and_return(false) }

      it "returns nil without calling CloudWatch" do
        expect(service.submissions_data).to be_nil
        expect(cloud_watch_client).not_to have_received(:get_metric_data)
      end
    end

    context "when the baseline cutoff date setting is missing" do
      before { allow(Settings).to receive(:total_submissions_baseline_cutoff_date).and_return(nil) }

      it "returns nil" do
        expect(service.submissions_data).to be_nil
        expect(cloud_watch_client).not_to have_received(:get_metric_data)
      end
    end

    context "when CloudWatch raises a ServiceError" do
      before do
        allow(cloud_watch_client).to receive(:get_metric_data)
          .and_raise(Aws::CloudWatch::Errors::ServiceError.new(nil, "CloudWatch error"))
      end

      it "captures the exception to Sentry and returns nil" do
        expect(Sentry).to receive(:capture_exception)
        expect(service.submissions_data).to be_nil
      end
    end

    context "when CloudWatch raises MissingCredentialsError" do
      before do
        allow(cloud_watch_client).to receive(:get_metric_data)
          .and_raise(Aws::Errors::MissingCredentialsError)
      end

      it "captures the exception to Sentry and returns nil" do
        expect(Sentry).to receive(:capture_exception)
        expect(service.submissions_data).to be_nil
      end
    end

    context "with fixture datapoints" do
      before { stub_cloudwatch }

      it "uses the correct SEARCH expression with a fixed start_time from settings" do
        service.submissions_data

        expected_start_time = Date.iso8601(baseline_cutoff_date).beginning_of_day.utc
        expect(cloud_watch_client).to have_received(:get_metric_data).with(
          hash_including(
            metric_data_queries: [
              hash_including(
                id: "total_submissions",
                expression: satisfy do |e|
                  e.include?("Forms") &&
                    e.include?('"Submitted"') &&
                    e.include?('Environment="test"')
                end,
              ),
            ],
            start_time: expected_start_time,
          ),
        )
      end

      it "returns the all_time total as baseline plus CloudWatch sum" do
        result = service.submissions_data
        expect(result[:all_time][:total]).to eq 159 # 100 baseline + 59 cloudwatch
      end

      describe "day buckets" do
        it "returns yesterday as the completed day" do
          result = service.submissions_data
          expect(result[:day][:completed]).to eq({ label: "22 Apr 2026", total: 10 })
        end

        it "returns today as the in-progress day" do
          result = service.submissions_data
          expect(result[:day][:in_progress]).to eq({ label: "23 Apr 2026", total: 5 })
        end
      end

      describe "week buckets" do
        it "returns last Mon–Sun as the completed week" do
          result = service.submissions_data
          expect(result[:week][:completed]).to eq({ label: "13–19 Apr 2026", total: 14 })
        end

        it "returns this Mon–today as the in-progress week" do
          result = service.submissions_data
          # Apr 20 and Apr 21 have no data (0), Apr 22=10, Apr 23=5
          expect(result[:week][:in_progress]).to eq({ label: "20–23 Apr 2026", total: 15 })
        end
      end

      describe "month buckets" do
        it "returns last calendar month as completed" do
          result = service.submissions_data
          expect(result[:month][:completed]).to eq({ label: "March 2026", total: 30 })
        end

        it "returns this calendar month as in-progress" do
          result = service.submissions_data
          # Apr 13=7, Apr 19=7, Apr 22=10, Apr 23=5  (Apr 1-12, 14-18, 20-21 have no data)
          expect(result[:month][:in_progress]).to eq({ label: "April 2026", total: 29 })
        end
      end

      describe "year buckets" do
        it "returns this calendar year as in-progress" do
          result = service.submissions_data
          # Mar 15=30, Apr 13=7, Apr 19=7, Apr 22=10, Apr 23=5
          expect(result[:year][:in_progress]).to eq({ label: "2026", total: 59 })
        end
      end

      describe "weekly_breakdown" do
        it "returns 52 entries" do
          result = service.submissions_data
          expect(result[:weekly_breakdown].length).to eq 52
        end

        it "puts the most recent completed week first" do
          result = service.submissions_data
          expect(result[:weekly_breakdown].first).to eq({ label: "13–19 Apr 2026", total: 14 })
        end

        it "puts the oldest completed week last" do
          result = service.submissions_data
          # 52nd week end = Apr 19 - 51*7 days = Apr 19 - 357 days = Apr 27, 2025
          expect(result[:weekly_breakdown].last[:label]).to eq "21–27 Apr 2025"
        end
      end

      describe "monthly_breakdown" do
        it "returns 12 entries" do
          result = service.submissions_data
          expect(result[:monthly_breakdown].length).to eq 12
        end

        it "puts the most recent completed month first" do
          result = service.submissions_data
          expect(result[:monthly_breakdown].first).to eq({ label: "March 2026", total: 30 })
        end

        it "puts the oldest completed month last" do
          result = service.submissions_data
          expect(result[:monthly_breakdown].last[:label]).to eq "April 2025"
        end
      end

      context "when no datapoints are returned" do
        before { stub_cloudwatch(timestamps: [], values: []) }

        it "returns zeros for all totals" do
          result = service.submissions_data
          expect(result[:all_time][:total]).to eq 100 # baseline only
          expect(result[:day][:completed][:total]).to eq 0
          expect(result[:week][:completed][:total]).to eq 0
        end
      end
    end
  end
end
