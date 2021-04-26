class AddRegistrantChangedAtToDomain < ActiveRecord::Migration[6.0]
  def change
    add_column :domains, :registrant_verification_asked_at, :datetime
    add_index :domains, :registrant_verification_asked_at
  end
end
