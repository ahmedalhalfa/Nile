require "rails_helper"

RSpec.describe UpdateSkuJob, type: :job do
  include ActiveJob::TestHelper

  let (:book_name) { "abc" }
  let (:sku) { "1234567890" }
  let (:uri) { URI("http://localhost:4567/update_sku") }
  let (:req) { Net::HTTP::Post.new(uri, "Content-Type" => "application/json") }

  before do
    allow(Net::HTTP).to receive(:start).and_return(true)
  end

  it "Calls the update_sku method with correct arguments" do
    expect_any_instance_of(Net::HTTP::Post).to receive(:body=).with({ sku: sku, name: book_name }.to_json)
    described_class.perform_now(book_name)
  end

  it "queues the job" do
    expect {
      described_class.perform_later(book_name)
    }.to have_enqueued_job(described_class).with(book_name)
  end

  it "executes perform" do
    # Clear any previously enqueued jobs
    clear_enqueued_jobs

    # Stub the external service call or whatever the job actually does
    # For example, if it logs something:
    expect(Rails.logger).to receive(:info).with("Updating SKU for book: #{book_name}")

    perform_enqueued_jobs { described_class.perform_later(book_name) }
  end

  # Add more tests here to cover specific logic within the job's perform method
  # For example, testing interactions with external APIs, database updates, etc.
end
