class MigrateBeforeForceDeleteStatusesJob < ApplicationJob
  def perform
    domains = Domain.where.not(statuses_before_force_delete: nil)
    domains.find_in_batches do |domain_batches|
      domain_batches.each do |domain|
        domain.force_delete_domain_statuses_history = domain.statuses_before_force_delete
        domain.save
      end
    end
  end
end
