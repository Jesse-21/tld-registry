class RegistrantChange
  def initialize(domain:, old_registrant:)
    @domain = domain
    @old_registrant = old_registrant
  end

  def confirm
    Dispute.close_by_domain(@domain.name) if @domain.disputed?
    notify_registrant
  end

  private

  def notify_registrant
    RegistrantChangeMailer.accepted(domain: domain, old_registrant: old_registrant).deliver_now
  end

  attr_reader :domain
  attr_reader :old_registrant
end
