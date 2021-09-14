module Domains
  module ClientHold
    class Base < ActiveInteraction::Base
      def to_stdout(message)
        time = Time.zone.now.utc
        $stdout << "#{time} - #{message}\n" unless Rails.env.test?
      end
    end
  end
end
