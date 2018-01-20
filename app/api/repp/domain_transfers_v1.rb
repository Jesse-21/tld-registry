module Repp
  class DomainTransfersV1 < Grape::API
    version 'v1', using: :path

    resource :domain_transfers do
      post '/' do
        params['domainTransfers'].each do |domain_transfer|
          domain_name = domain_transfer['domainName']
          auth_info = domain_transfer['authInfo']
          new_registrar = current_user.registrar

          domain = Domain.find_by(name: domain_name)
          domain.transfer(registrar: new_registrar, auth_info: auth_info)
        end
      end
    end
  end
end
