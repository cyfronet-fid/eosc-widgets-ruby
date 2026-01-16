class RenameServicesToEndpoints < ActiveRecord::Migration[7.2]
  def change
    rename_table :services, :endpoints
  end
end
