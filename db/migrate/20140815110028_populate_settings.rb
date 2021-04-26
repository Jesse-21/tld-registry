class PopulateSettings < ActiveRecord::Migration[6.0]
  def change
    SettingGroup.create(
      code: 'domain_validation',
      settings: [
        Setting.create(code: 'ns_min_count', value: 1),
        Setting.create(code: 'ns_max_count', value: 13)
      ]
    )
  end
end
