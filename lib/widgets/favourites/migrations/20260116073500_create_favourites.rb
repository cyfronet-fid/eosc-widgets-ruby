class CreateFavourites < ActiveRecord::Migration[7.2]
  def change
    create_table :favourites do |t|
      t.string :pid, null: false
      t.string :type, null: false
      t.string :title
      t.string :authors, array: true, default: []
      t.string :links, array: true, default: []
      t.string :best_access_right

      t.timestamps
    end

    add_index :favourites, [:pid, :type], unique: true

    create_table :users_favourites, id: false do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :favourite, null: false, foreign_key: true
    end

    add_index :users_favourites, [:user_id, :favourite_id], unique: true
  end
end
