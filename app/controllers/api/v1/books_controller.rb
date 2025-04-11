module Api
  module V1
    class BooksController < ApplicationController
      def index
        books = Book.all
        render json: BooksRepresenter.new(books).as_json
      end

      def create
        book = Book.new(book_params.merge(author_id: params[:book][:author_id]))
        if book.save
          render json: book, status: :created
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
    end
  end
end
