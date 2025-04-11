class AddAuthorToBooks < ActiveRecord::Migration[8.0]
  def change
    add_reference :books, :author
  end
end
