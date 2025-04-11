require "rails_helper"

RSpec.describe Api::V1::BooksController, type: :controller do
  describe "GET #index" do
    it "has a max limit of 10" do
      expect(Book).to receive(:limit).with(10).and_return(Book.all)
      get :index, params: { limit: 999 }
      expect(response).to be_successful
    end
  end
end
