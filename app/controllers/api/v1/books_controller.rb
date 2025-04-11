module Api
  module V1
    class BooksController < ApplicationController
      MAX_PER_PAGE = 10

      def index
        if params[:limit].present? || params[:offset].present?
          # Apply pagination with to_i for type conversion
          books = Book.limit(limit).offset(offset)
        else
          # No pagination params, return all books
          books = Book.all
        end

        render json: BooksRepresenter.new(books).as_json
      end

      def create
        book = Book.new(book_params.merge(author_id: params[:book][:author_id]))
        if book.save
          render json: BookRepresenter.new(book).as_json, status: :created
        else
          render json: { errors: book.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        Book.find(params[:id]).destroy!
        head :no_content
      end

      private

      def book_params
        params.require(:book).permit(:title)
      end

      def limit
        [params.fetch(:limit, MAX_PER_PAGE).to_i, MAX_PER_PAGE].min
      end

      def offset
        params.fetch(:offset, 0).to_i
      end
    end
  end
end
