class VerifyEmailsJob < ApplicationJob
  discard_on StandardError

  def perform(email:, check_level: 'mx')
    contact = Contact.find_by(email: email)

    return Rails.logger.info "No found #{email} contact" if contact.nil?

    return unless filter_check_level(contact)

    validate_check_level(check_level)
    action = Actions::EmailCheck.new(email: contact.email,
                                     validation_eventable: contact,
                                     check_level: check_level)
    action.call
  rescue StandardError => e
    logger.error e.message
    raise e
  end

  private

  def validate_check_level(check_level)
    return if valid_check_levels.include? check_level

    raise StandardError, "Check level #{check_level} is invalid"
  end

  def logger
    @logger ||= Rails.logger
  end

  def valid_check_levels
    ValidationEvent::VALID_CHECK_LEVELS
  end

  def filter_check_level(contact)
    return true unless contact.validation_events.exists?

    data = contact.validation_events.order(created_at: :asc).last
    return true if data.successful? && data.created_at < (Time.zone.now - ValidationEvent::VALIDATION_PERIOD)

    !(data.failed? && data.event_data['check_level'] == 'regex')
  end
end
