# frozen_string_literal: true

require 'resolv'

class NameserverRecordValidationJob < ApplicationJob
  include Dnsruby

  def perform(domain_name: nil)
    if domain_name.nil?
      domains = Domain.all.select { |domain| domain.created_at < Time.zone.now - NameserverValidator::VALIDATION_DOMAIN_PERIOD }
                      .select { |domain| domain.nameservers.exists? }

      domains.each do |domain|
        domain.nameservers.each do |nameserver|
          next if nameserver.nameserver_failed_validation? || nameserver.validated?

          result = NameserverValidator.run(domain_name: domain.name, hostname: nameserver.hostname)

          if result[:result]
            add_nameserver_to_succesfully(nameserver)

            true
          else
            parse_result(result, nameserver)
            false
          end
        end
      end
    else
      domain = Domain.find_by(name: domain_name)

      return logger.info 'Domain not found' if domain.nil?

      if domain.created_at > Time.zone.now - NameserverValidator::VALIDATION_DOMAIN_PERIOD
        return logger.info "It should take #{NameserverValidator::VALIDATION_DOMAIN_PERIOD} hours after the domain was created"
      end

      return logger.info 'Domain not has nameservers' if domain.nameservers.empty?

      domain.nameservers.each do |nameserver|
        next if nameserver.nameserver_failed_validation?

        result = NameserverValidator.run(domain_name: domain.name, hostname: nameserver.hostname)

        if result[:result]
          add_nameserver_to_succesfully(nameserver)

          true
        else
          parse_result(result, nameserver)
          false
        end
      end
    end
  end

  private

  def add_nameserver_to_succesfully(nameserver)
    nameserver.validation_counter = nil
    nameserver.failed_validation_reason = nil
    nameserver.validation_datetime = Time.zone.now

    nameserver.save
  end

  def add_nameserver_to_failed(nameserver:, reason:)
    if nameserver.validation_counter.nil?
      nameserver.validation_counter = 1
    else
      nameserver.validation_counter = nameserver.validation_counter + 1
    end

    nameserver.failed_validation_reason = reason
    nameserver.save
  end

  def parse_result(result, nameserver)
    domain = Domain.find(nameserver.domain_id)

    text = ""
    case result[:reason]
    when 'answer'
      text = "No any answer comes from **#{nameserver.hostname}**. Nameserver not exist"
    when 'serial'
      text = "Serial number for nameserver hostname **#{nameserver.hostname}** doesn't present. SOA validation failed."
    when 'not found'
      text = "Seems nameserver hostname **#{nameserver.hostname}** doesn't exist"
    when 'exception'
      text = "Something goes wrong, exception reason: **#{result[:error_info]}**"
    when 'domain'
      text = "#{domain} not found in zone"
    end

    logger.info text
    failed_log(text: text, nameserver: nameserver)
    add_nameserver_to_failed(nameserver: nameserver, reason: text)

    false
  end

  def failed_log(text:, nameserver:)
    inform_to_tech_contact(text)
    inform_to_registrar(text: text, nameserver: nameserver)

    false
  end

  def inform_to_tech_contact(text)
    "NEED TO DO!"
    text
  end

  def inform_to_registrar(text:, nameserver:)
    # nameserver.domain.registrar.notifications.create!(text: text)
    "NEED TO DO!"
  end

  def logger
    @logger ||= Rails.logger
  end
end
