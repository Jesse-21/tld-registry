class PopulateGeneralDomainSettings < ActiveRecord::Migration[6.0]
  def change
    SettingGroup.create(
      code: 'domain_general',
      settings: [
        Setting.create(code: 'transfer_wait_time', value: 0)
      ]
    )
  end
end
