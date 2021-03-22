class Action < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version::ActionVersion' }

  belongs_to :user
  belongs_to :contact

  validates :operation, inclusion: { in: proc { |action| action.class.valid_operations } }

  class << self
    def valid_operations
      %w[update]
    end
  end

  def notification_key
    raise 'Action object is missing' unless contact
    "contact_#{operation}".to_sym
  end
end
