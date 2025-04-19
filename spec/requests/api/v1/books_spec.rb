require "swagger_helper"
require "rails_helper"

describe "Books API" do
  let!(:user) { create(:user) }
  let!(:author) { create(:author) }
  let(:auth_headers) { { "Authorization" => "Bearer #{JwtService.encode(user_id: user.id)}" } }

  path "/api/v1/books" do
    get "Retrieves a list of books" do
      tags "Books"
      produces "application/json"
      security [ bearerAuth: [] ]
      parameter name: :limit, in: :query, type: :integer, description: "Maximum number of books to return", required: false
      parameter name: :offset, in: :query, type: :integer, description: "Number of books to skip", required: false

      response "200", "list of books" do
        schema type: :object,
               properties: {
                 books: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/book" }
                 }
               },
               required: [ "books" ]

        context "when records exist" do
          let!(:books) { create_list(:book, 3, author: author) }
          let(:limit) { 2 }
          let(:offset) { 1 }
          let(:Authorization) { auth_headers["Authorization"] }

          before { get "/api/v1/books", params: { limit: limit, offset: offset }, headers: auth_headers }

          it "returns http success" do
            expect(response).to have_http_status(:ok)
          end

          it "returns a paginated list of books" do
            expect(response_body[:books].size).to eq(limit)
            expect(response_body[:books].first[:id]).to eq(books[1].id)
          end

          it "matches the book schema" do
            # This test relies on rswag's schema validation integrated with run_test!
            # We can add more specific checks if needed
          end

          run_test!
        end

        context "when no books exist" do
          let(:limit) { 10 }
          let(:offset) { 0 }
          let(:Authorization) { auth_headers["Authorization"] }
          before { get "/api/v1/books", params: { limit: limit, offset: offset }, headers: auth_headers }

          it "returns http success" do
            expect(response).to have_http_status(:ok)
          end

          it "returns an empty list" do
            expect(response_body[:books]).to be_empty
          end

          run_test!
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:limit) { 10 }
        let(:offset) { 0 }
        run_test!
      end
    end

    post "Creates a book" do
      tags "Books"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]
      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              title: { type: :string },
              author_id: { type: :integer }
            },
            required: [ "title", "author_id" ]
          }
        },
        required: [ "book" ]
      }

      response "201", "book created" do
        schema "$ref" => "#/components/schemas/book"

        context "with valid parameters" do
          let(:book_params) { { book: { title: "New Book Title", author_id: author.id } } }
          let(:Authorization) { auth_headers["Authorization"] }

          it "creates a new Book" do
            expect {
              post "/api/v1/books", params: book_params.to_json, headers: auth_headers.merge("Content-Type" => "application/json")
            }.to change(Book, :count).by(1)
          end

          it "returns the created book" do
            post "/api/v1/books", params: book_params.to_json, headers: auth_headers.merge("Content-Type" => "application/json")
            expect(response).to have_http_status(:created)
            expect(response_body[:title]).to eq("New Book Title")
            expect(response_body[:author_name]).to eq("#{author.first_name} #{author.last_name}")
          end

          it "enqueues the UpdateSkuJob" do
            expect(UpdateSkuJob).to receive(:perform_later).with("New Book Title")
            post "/api/v1/books", params: book_params.to_json, headers: auth_headers.merge("Content-Type" => "application/json")
          end

          let(:book) { book_params }
          run_test!
        end
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/errors_object"

        context "with invalid parameters" do
          let(:invalid_book_params) { { book: { title: "B", author_id: author.id } } }
          let(:Authorization) { auth_headers["Authorization"] }

          before { post "/api/v1/books", params: invalid_book_params.to_json, headers: auth_headers.merge("Content-Type" => "application/json") }

          it "does not create a new Book" do
            expect(Book.count).to eq(0)
          end

          it "returns unprocessable entity status" do
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "returns validation errors" do
            expect(response_body[:errors]).to include("Title is too short (minimum is 2 characters)")
          end

          let(:book) { invalid_book_params }
          run_test!
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:book) { { book: { title: "New Book Title", author_id: author.id } } }
        run_test!
      end
    end
  end

  path "/api/v1/books/{id}" do
    parameter name: :id, in: :path, type: :string, description: "Book ID"

    get "Retrieves a book" do
      tags "Books"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "book found" do
        schema "$ref" => "#/components/schemas/book"

        context "when the book exists" do
          let!(:existing_book) { create(:book, author: author) }
          let(:id) { existing_book.id }
          let(:Authorization) { auth_headers["Authorization"] }

          before { get "/api/v1/books/#{id}", headers: auth_headers }

          it "returns http success" do
            expect(response).to have_http_status(:ok)
          end

          it "returns the correct book" do
            expect(response_body[:id]).to eq(existing_book.id)
            expect(response_body[:title]).to eq(existing_book.title)
          end

          run_test!
        end
      end

      response "404", "book not found" do
        context "when the book does not exist" do
          let(:id) { "invalid-id" }
          let(:Authorization) { auth_headers["Authorization"] }

          before { get "/api/v1/books/#{id}", headers: auth_headers }

          it "returns http not found" do
            expect(response).to have_http_status(:not_found)
          end

          it "returns an error message" do
            expect(response_body[:error]).to eq("Record not found")
          end

          run_test!
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        run_test!
      end
    end

    put "Updates a book" do
      tags "Books"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]
      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              title: { type: :string },
              author_id: { type: :integer }
            },
            required: [ "title", "author_id" ]
          }
        },
        required: [ "book" ]
      }

      response "200", "book updated" do
        schema "$ref" => "#/components/schemas/book"

        context "with valid parameters" do
          let!(:existing_book) { create(:book, author: author) }
          let(:id) { existing_book.id }
          let(:new_author) { create(:author) }
          let(:update_params) { { book: { title: "Updated Title", author_id: new_author.id } } }
          let(:Authorization) { auth_headers["Authorization"] }

          before { put "/api/v1/books/#{id}", params: update_params.to_json, headers: auth_headers.merge("Content-Type" => "application/json") }

          it "updates the book" do
            existing_book.reload
            expect(existing_book.title).to eq("Updated Title")
            expect(existing_book.author_id).to eq(new_author.id)
          end

          it "returns the updated book" do
            expect(response).to have_http_status(:ok)
            expect(response_body[:title]).to eq("Updated Title")
            expect(response_body[:author_name]).to eq("#{new_author.first_name} #{new_author.last_name}")
          end

          let(:book) { update_params }
          run_test!
        end
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/errors_object"

        context "with invalid parameters" do
          let!(:existing_book) { create(:book, author: author) }
          let(:id) { existing_book.id }
          let(:invalid_update_params) { { book: { title: "", author_id: author.id } } }
          let(:Authorization) { auth_headers["Authorization"] }

          before { put "/api/v1/books/#{id}", params: invalid_update_params.to_json, headers: auth_headers.merge("Content-Type" => "application/json") }

          it "does not update the book" do
            original_title = existing_book.title
            existing_book.reload
            expect(existing_book.title).to eq(original_title)
          end

          it "returns unprocessable entity status" do
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "returns validation errors" do
            expect(response_body[:errors]).to include("Title can't be blank", "Title is too short (minimum is 2 characters)")
          end

          let(:book) { invalid_update_params }
          run_test!
        end
      end

      response "404", "book not found" do
        context "when the book does not exist" do
          let(:id) { "invalid-id" }
          let(:update_params) { { book: { title: "Updated Title", author_id: author.id } } }
          let(:Authorization) { auth_headers["Authorization"] }

          before { put "/api/v1/books/#{id}", params: update_params.to_json, headers: auth_headers.merge("Content-Type" => "application/json") }

          it "returns http not found" do
            expect(response).to have_http_status(:not_found)
          end

          let(:book) { update_params }
          run_test!
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let!(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:book) { { book: { title: "Updated Title", author_id: author.id } } }
        run_test!
      end
    end

    delete "Deletes a book" do
      tags "Books"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "204", "book deleted" do
        context "when the book exists" do
          let!(:existing_book) { create(:book, author: author) }
          let(:id) { existing_book.id }
          let(:Authorization) { auth_headers["Authorization"] }

          it "deletes the book" do
            expect {
              delete "/api/v1/books/#{id}", headers: auth_headers
            }.to change(Book, :count).by(-1)
          end

          it "returns no content status" do
            delete "/api/v1/books/#{id}", headers: auth_headers
            expect(response).to have_http_status(:no_content)
          end

          run_test!
        end
      end

      response "404", "book not found" do
        context "when the book does not exist" do
          let(:id) { "invalid-id" }
          let(:Authorization) { auth_headers["Authorization"] }

          before { delete "/api/v1/books/#{id}", headers: auth_headers }

          it "returns http not found" do
            expect(response).to have_http_status(:not_found)
          end

          run_test!
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let!(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        run_test!
      end
    end
  end
end
