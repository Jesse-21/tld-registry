xml.epp_head do
  xml.response do
    xml.result('code' => '1000') do
      xml.msg 'Command completed successfully'
    end

    xml.resData do
      xml << render('epp/contacts/partials/check', builder: xml, results: @results)
    end

    render('epp/shared/trID', builder: xml)
  end
end
