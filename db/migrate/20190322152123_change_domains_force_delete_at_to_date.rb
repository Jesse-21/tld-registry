class ChangeDomainsForceDeleteAtToDate < ActiveRecord::Migration[6.0]
  def change
    change_column :domains, :force_delete_at, :date
  end
end
