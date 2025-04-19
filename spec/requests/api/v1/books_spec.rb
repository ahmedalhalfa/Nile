require "swagger_helper"

describe "Books API" do
  path "/api/v1/books" do
    get "Retrieves a list of books" do
      tags "Books"
      produces "application/json"
      security [bearerAuth: []]
      parameter name: :limit, in: :query, type: :integer, description: "Maximum number of books to return", required: false
      parameter name: :offset, in: :query, type: :integer, description: "Number of books to skip", required: false

      response "200", "list of books" do
        schema type: :object,
               properties: {
                 books: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/book" },
                 },
               },
               required: ["books"]

        let(:limit) { 10 }
        let(:offset) { 0 }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        before { create_list(:book, 5) } # Assumes you have FactoryBot setup
        run_test!
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
      security [bearerAuth: []]
      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              title: { type: :string },
              author_id: { type: :integer },
            },
            required: ["title", "author_id"],
          },
        },
        required: ["book"],
      }

      response "201", "book created" do
        schema "$ref" => "#/components/schemas/book"
        let(:author) { create(:author) } # Assumes you have FactoryBot setup
        let(:book) { { book: { title: "New Book Title", author_id: author.id } } }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/errors_object"
        let(:author) { create(:author) } # Assumes you have FactoryBot setup
        let(:book) { { book: { title: "B", author_id: author.id } } } # Invalid title
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:author) { create(:author) }
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
      security [bearerAuth: []]

      response "200", "book found" do
        schema "$ref" => "#/components/schemas/book"
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "404", "book not found" do
        let(:id) { "invalid" }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
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
      security [bearerAuth: []]
      parameter name: :book, in: :body, schema: {
        type: :object,
        properties: {
          book: {
            type: :object,
            properties: {
              title: { type: :string },
              author_id: { type: :integer },
            },
            required: ["title", "author_id"],
          },
        },
        required: ["book"],
      }

      response "200", "book updated" do
        schema "$ref" => "#/components/schemas/book"
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:author) { create(:author) }
        let(:book) { { book: { title: "Updated Title", author_id: author.id } } }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "422", "invalid request" do
        schema "$ref" => "#/components/schemas/errors_object"
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:author) { create(:author) }
        let(:book) { { book: { title: "", author_id: author.id } } } # Invalid title
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "404", "book not found" do
        let(:id) { "invalid" }
        let(:author) { create(:author) }
        let(:book) { { book: { title: "Updated Title", author_id: author.id } } }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:author) { create(:author) }
        let(:book) { { book: { title: "Updated Title", author_id: author.id } } }
        run_test!
      end
    end

    delete "Deletes a book" do
      tags "Books"
      produces "application/json"
      security [bearerAuth: []]

      response "204", "book deleted" do
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "404", "book not found" do
        let(:id) { "invalid" }
        let(:Authorization) { "Bearer #{JwtService.encode(user_id: User.first.id)}" } # Assuming a user exists
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer invalid" }
        let(:existing_book) { create(:book) }
        let(:id) { existing_book.id }
        run_test!
      end
    end
  end
end
