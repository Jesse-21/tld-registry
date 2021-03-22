module Domain::Discardable
  extend ActiveSupport::Concern

  def keep
    statuses.delete(DomainStatus::DELETE_CANDIDATE)
    transaction do
      save(validate: false)
      do_not_delete_later
    end
  end

  def discarded?
    statuses.include?(DomainStatus::DELETE_CANDIDATE)
  end

  private

  def discard
    statuses << DomainStatus::DELETE_CANDIDATE
    transaction do
      save(validate: false)
      delete_later
    end
  end
end
