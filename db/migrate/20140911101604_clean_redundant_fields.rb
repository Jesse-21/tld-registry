class CleanRedundantFields < ActiveRecord::Migration[6.0]
  def change
    drop_table :domain_nameservers
    remove_column :domains, :admin_contact_id
    remove_column :domains, :technical_contact_id
    remove_column :domains, :ns_set_id
  end
end
