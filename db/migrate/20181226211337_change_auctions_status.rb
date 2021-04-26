class ChangeAuctionsStatus < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    execute <<-SQL
      ALTER TYPE auction_status ADD VALUE 'domain_registered' AFTER 'payment_received';
    SQL
  end
end
