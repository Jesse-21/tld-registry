module Contact::Archivable
  extend ActiveSupport::Concern

  class_methods do
    def archivable
      unlinked.find_each.select(&:archivable?)
    end
  end

  def archivable?(post: false)
    inactive = inactive?

    log("Found archivable contact id(#{id}), code (#{code})") if inactive && !post

    inactive
  end

  def archive(verified: false, notify: true, extra_log: false)
    unless verified
      raise 'Contact cannot be archived' unless archivable?(post: true)
    end

    notify_registrar_about_archivation if notify
    write_to_registrar_log if extra_log
    destroy!
  end

  private

  def notify_registrar_about_archivation
    registrar.notifications.create!(
      text: I18n.t('contact_has_been_archived',
                   contact_code: code, orphan_months: Setting.orphans_contacts_in_months)
    )
  end

  def inactive?
    if Version::DomainVersion.contact_unlinked_more_than?(contact_id: id, period: inactivity_period)
      return true
    end

    Version::DomainVersion.was_contact_linked?(id) ? false : created_at <= inactivity_period.ago
  end

  def inactivity_period
    Setting.orphans_contacts_in_months.months
  end

  def log(msg)
    @log ||= Logger.new($stdout)
    @log.info(msg)
  end

  def write_to_registrar_log
    registrar_name = registrar.accounting_customer_code
    archive_path = ENV['contact_archivation_log_file_dir']
    registrar_log_path = "#{archive_path}/#{registrar_name}.txt"
    FileUtils.mkdir_p(archive_path) unless Dir.exist?(archive_path)

    f = File.new(registrar_log_path, 'a+')
    f.write("#{code}\n")
    f.close
  end
end
