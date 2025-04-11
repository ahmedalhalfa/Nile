require "rails_helper"

RSpec.describe Api::V1::BooksController, type: :controller do
  describe "GET #index" do
    it "has a max limit of 10" do
      expect(Book).to receive(:limit).with(10).and_return(Book.all)
      get :index, params: { limit: 999 }
      expect(response).to be_successful
    end
  end
  describe "POST #create" do
    it "enqueues the update_sku job" do
      expect(UpdateSkuJob).to receive(:perform_later).with("test")
      post :create, params: { author: { first_name: "abc", last_name: "def", age: 10 }, book: { title: "test" } }
    end
  end
end
