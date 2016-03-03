class DomainCron

  def self.clean_expired_pendings
    STDOUT << "#{Time.zone.now.utc} - Clean expired domain pendings\n" unless Rails.env.test?

    expire_at = Setting.expire_pending_confirmation.hours.ago
    count = 0
    expired_pending_domains = Domain.where('registrant_verification_asked_at <= ?', expire_at)
    expired_pending_domains.each do |domain|
      unless domain.pending_update? || domain.pending_delete? || domain.pending_delete_confirmation?
        msg = "#{Time.zone.now.utc} - ISSUE: DOMAIN #{domain.id}: #{domain.name} IS IN EXPIRED PENDING LIST, " \
                "but no pendingDelete/pendingUpdate state present!\n"
        STDOUT << msg unless Rails.env.test?
        next
      end
      count += 1
      if domain.pending_update?
        DomainMailer.pending_update_expired_notification_for_new_registrant(domain.id).deliver
      end
      if domain.pending_delete? || domain.pending_delete_confirmation?
        DomainMailer.pending_delete_expired_notification(domain.id, deliver_emails).deliver
      end
      domain.clean_pendings_lowlevel
      unless Rails.env.test?
        STDOUT << "#{Time.zone.now.utc} DomainCron.clean_expired_pendings: ##{domain.id} (#{domain.name})\n"
      end
    end
    STDOUT << "#{Time.zone.now.utc} - Successfully cancelled #{count} domain pendings\n" unless Rails.env.test?
    count
  end

  def self.start_expire_period
    STDOUT << "#{Time.zone.now.utc} - Expiring domains\n" unless Rails.env.test?

    domains = Domain.where('valid_to <= ?', Time.zone.now)
    marked = 0
    real = 0
    domains.each do |domain|
      next unless domain.expirable?
      real += 1
      domain.set_graceful_expired
      STDOUT << "#{Time.zone.now.utc} DomainCron.start_expire_period: ##{domain.id} (#{domain.name}) #{domain.changes}\n" unless Rails.env.test?
      domain.save(validate: false) and marked += 1
    end

    STDOUT << "#{Time.zone.now.utc} - Successfully expired #{marked} of #{real} domains\n" unless Rails.env.test?
  end

  def self.start_redemption_grace_period
    STDOUT << "#{Time.zone.now.utc} - Setting server_hold to domains\n" unless Rails.env.test?

    d = Domain.where('outzone_at <= ?', Time.zone.now)
    marked = 0
    real = 0
    d.each do |domain|
      next unless domain.server_holdable?
      real += 1
      domain.statuses << DomainStatus::SERVER_HOLD
      STDOUT << "#{Time.zone.now.utc} DomainCron.start_redemption_grace_period: ##{domain.id} (#{domain.name}) #{domain.changes}\n" unless Rails.env.test?
      domain.save(validate: false) and marked += 1
    end

    STDOUT << "#{Time.zone.now.utc} - Successfully set server_hold to #{marked} of #{real} domains\n" unless Rails.env.test?
    marked
  end

  def self.start_delete_period
    begin
      STDOUT << "#{Time.zone.now.utc} - Setting delete_candidate to domains\n" unless Rails.env.test?

      d = Domain.where('delete_at <= ?', Time.zone.now)
      marked = 0
      real = 0
      d.each do |domain|
        next unless domain.delete_candidateable?
        real += 1
        STDOUT << "#{Time.zone.now.utc} DomainCron.start_delete_period: ##{domain.id} (#{domain.name})\n" unless Rails.env.test?
        DomainSetDeleteCandidateJob.enqueue(domain.id, run_at: rand(((24*60) - (DateTime.now.hour * 60))).minutes.from_now) and marked += 1
      end
    ensure # the operator should see what was accomplished
      STDOUT << "#{Time.zone.now.utc} - Finished setting schedule for delete_candidate -  #{marked} out of #{real} successfully added to Que schedule\n" unless Rails.env.test?
    end
    marked
  end

  def self.destroy_delete_candidates
    STDOUT << "#{Time.zone.now.utc} - Destroying domains\n" unless Rails.env.test?

    c = 0
    Domain.where('force_delete_at <= ?', Time.zone.now).each do |x|
      DomainDeleteJob.enqueue(x.id, run_at: rand(((24*60) - (DateTime.now.hour * 60))).minutes.from_now)
      STDOUT << "#{Time.zone.now.utc} DomainCron.destroy_delete_candidates: job added by force delete time ##{x.id} (#{x.name})\n" unless Rails.env.test?
      c += 1
    end

    STDOUT << "#{Time.zone.now.utc} - Job destroy added for #{c} domains\n" unless Rails.env.test?
  end

  # rubocop: enable Metrics/AbcSize
  # rubocop:enable Rails/FindEach
  # rubocop: enable Metrics/LineLength
  def self.destroy_with_message(domain)
    domain.destroy
    bye_bye = domain.versions.last
    domain.registrar.messages.create!(
        body: "#{I18n.t(:domain_deleted)}: #{domain.name}",
        attached_obj_id: bye_bye.id,
        attached_obj_type: bye_bye.class.to_s # DomainVersion
    )
  end

end
