class AddUserStampsToContact < ActiveRecord::Migration[6.0]
  def change
    add_column :contacts, :created_by_id, :integer
    add_column :contacts, :updated_by_id, :integer
  end
end
