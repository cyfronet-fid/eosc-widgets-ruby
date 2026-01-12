# frozen_string_literal: true

class CreateIdentityProviders < ActiveRecord::Migration[7.0]
  def change
    create_table :identity_providers do |t|
      t.string :name
      t.string :abbreviation
      t.string :pid
      t.string :url
      t.jsonb :config

      t.timestamps
    end
  end
end
