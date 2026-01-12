# frozen_string_literal: true

class CreateServices < ActiveRecord::Migration[7.0]
  def change
    create_table :services do |t|
      t.string :name
      t.string :abbreviation
      t.string :pid
      t.string :url
      t.references :identity_provider, foreign_key: true

      t.timestamps
    end
  end
end
