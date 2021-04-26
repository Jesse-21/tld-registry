class RemoveUnusedColumnsFromLogDomains < ActiveRecord::Migration[6.0]
  def change
    remove_column :log_domains, :nameserver_ids
    remove_column :log_domains, :admin_contact_ids
    remove_column :log_domains, :tech_contact_ids
  end
end