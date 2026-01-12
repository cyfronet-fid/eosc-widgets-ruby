# frozen_string_literal: true

class CreateUids < ActiveRecord::Migration[7.0]
  def change
    create_table :uids do |t|
      t.string :value, null: false
      t.references :user, null: false, foreign_key: true, index: true
      t.references :identity_provider, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :uids, %i[identity_provider_id value], unique: true
  end
end
