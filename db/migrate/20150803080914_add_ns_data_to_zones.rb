class AddNsDataToZones < ActiveRecord::Migration[6.0]
  def change
    add_column :zonefile_settings, :ns_records, :text
    add_column :zonefile_settings, :a_records, :text
    add_column :zonefile_settings, :a4_records, :text
  end
end
