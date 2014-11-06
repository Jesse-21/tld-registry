xml.epp_head do
  xml.response do
    xml.result('code' => '1000') do
      xml.msg 'Command completed successfully'
    end

    xml.resData do
      xml << render('epp/domains/partials/transfer', builder: xml, dt: @domain_transfer)
    end
  end

  xml << render('/epp/shared/trID')
end
