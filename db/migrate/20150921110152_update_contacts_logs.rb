class UpdateContactsLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :log_contacts, :legacy_ident_updated_at, :datetime
  end
end
