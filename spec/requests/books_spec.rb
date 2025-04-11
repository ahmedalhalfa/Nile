require "rails_helper"

describe "Books API", type: :request do
  let!(:author) { FactoryBot.create(:author, first_name: "F. Scott", last_name: "Fitzgerald", age: 44) } # Assuming you have an Author factory

  describe "GET /api/v1/books" do
    before do
      FactoryBot.create(:book, title: "The Great Gatsby", author: author)
      FactoryBot.create(:book, title: "To Kill a Mockingbird", author: FactoryBot.create(:author, first_name: "Harper", last_name: "Lee", age: 89))
    end
    it "returns all books" do
      get "/api/v1/books"
      expect(response).to have_http_status(:success)
      expect(response_body.size).to eq(2)
      expect(response_body).to eq(BooksRepresenter.new(Book.all).as_json)
    end
  end

  describe "POST /api/v1/books" do
    it "creates a book" do
      expect {
        post "/api/v1/books", params: { book: { title: "Tender Is the Night", author_id: author.id } }
      }.to change(Book, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(response_body).to eq(BookRepresenter.new(Book.last).as_json)
    end
  end

  describe "DELETE /api/v1/books/:id" do
    let!(:book) { FactoryBot.create(:book, title: "The Great Gatsby", author: author) }

    it "deletes a book" do
      expect {
        delete "/api/v1/books/#{book.id}"
      }.to change(Book, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
