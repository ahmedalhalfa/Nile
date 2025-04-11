require "rails_helper"

describe "Books API", type: :request do
    describe "GET /api/v1/books" do
        before do
            FactoryBot.create(:book, title: "The Great Gatsby", author: "F. Scott Fitzgerald")
            FactoryBot.create(:book, title: "To Kill a Mockingbird", author: "Harper Lee")
        end
        it "returns all books" do
            get "/api/v1/books"
            expect(response).to have_http_status(:success)
            expect(JSON.parse(response.body).size).to eq(2)
        end
    end

    describe "POST /api/v1/books" do
        it "creates a book" do
            expect {
                post "/api/v1/books", params: { book: { title: "The Great Gatsby", author: "F. Scott Fitzgerald" } }
            }.to change(Book, :count).by(1)
            expect {
                post "/api/v1/books", params: { book: { title: "The Great Gatsby", author: "F. Scott Fitzgerald" } }
            }.to change{Book.count}.from(1).to(2)
            expect(response).to have_http_status(:created)
        end
    end

    describe "DELETE /api/v1/books/:id" do
        let!(:book) { FactoryBot.create(:book, title: "The Great Gatsby", author: "F. Scott Fitzgerald") }

        it "deletes a book" do
            expect {
                delete "/api/v1/books/#{book.id}"
            }.to change(Book, :count).by(-1)
            expect(response).to have_http_status(:no_content)
        end
    end
end