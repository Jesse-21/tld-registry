module Api
  module V1
    module Registrant
      class RegistryLocksController < BaseController
        before_action :set_domain

        def create
          if @domain.apply_registry_lock
            render json: @domain
          else
            render json: { errors: [{ base: 'Domain cannot be locked' }] },
                   status: :unprocessable_entity
          end
        end

        def delete
          if @domain.remove_registry_lock
            render json: @domain
          else
            render json: { errors: [{ base: 'Domain cannot be unlocked' }] },
                   status: :unprocessable_entity
          end
        end

        private

        def set_domain
          @domain = Domain.find_by(uuid: params[:domain_uuid])

          return if @domain
          render json: { errors: [{ base: ['Domain not found'] }] },
                 status: :not_found and return
        end
      end
    end
  end
end
