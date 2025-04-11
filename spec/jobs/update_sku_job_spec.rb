require "rails_helper"

RSpec.describe UpdateSkuJob, type: :job do
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
end
