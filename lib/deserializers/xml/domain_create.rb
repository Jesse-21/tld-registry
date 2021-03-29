require 'deserializers/xml/legal_document'
require 'deserializers/xml/domain'
require 'deserializers/xml/nameserver'
require 'deserializers/xml/dnssec'
module Deserializers
  module Xml
    class DomainCreate
      attr_reader :frame
      attr_reader :registrar

      def initialize(frame, registrar)
        @frame = frame
        @registrar = registrar
      end

      def call
        obj = domain
        obj[:admin_contacts] = admin_contacts
        obj[:tech_contacts] = tech_contacts
        obj[:nameservers_attributes] = nameservers
        obj[:dnskeys_attributes] = dns_keys
        obj[:legal_document] = legal_document

        obj
      end

      def domain
        @domain ||= ::Deserializers::Xml::Domain.new(frame, registrar).call
      end

      def nameservers
        @nameservers ||= ::Deserializers::Xml::Nameservers.new(frame).call
      end

      def admin_contacts
        frame.css('contact').select { |c| c['type'] == 'admin' }.map(&:text)
      end

      def tech_contacts
        frame.css('contact').select { |c| c['type'] == 'tech' }.map(&:text)
      end

      def dns_keys
        @dns_keys ||= ::Deserializers::Xml::DnssecKeys.new(frame).key_data
      end

      def legal_document
        @legal_document ||= ::Deserializers::Xml::LegalDocument.new(frame).call
      end
    end
  end
end
