class AddAuctionsUuidUniqConstraint < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      ALTER TABLE auctions ADD CONSTRAINT uniq_uuid UNIQUE (uuid)
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE auctions DROP CONSTRAINT uniq_uuid
    SQL
  end
end
