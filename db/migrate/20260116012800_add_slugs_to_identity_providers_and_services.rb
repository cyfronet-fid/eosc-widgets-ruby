# frozen_string_literal: true

class AddSlugsToIdentityProvidersAndServices < ActiveRecord::Migration[7.2]
  def change
    add_column :identity_providers, :slug, :string
    add_index :identity_providers, :slug, unique: true
    add_column :services, :slug, :string
    add_index :services, :slug, unique: true
  end
end
