xml.epp_head do
  xml.response do
    xml.result('code' => '1000') do
      xml.msg 'Command completed successfully'
    end

    xml.resData do
      xml.tag!('domain:chkData', 'xmlns:domain' => Xsd::Schema.filename(for_prefix: 'domain-eis')) do
        @domains.each do |x|
          xml.tag!('domain:cd') do
            xml.tag!('domain:name', x[:name], 'avail' => x[:avail])
            xml.tag!('domain:reason', x[:reason]) if x[:reason].present?
          end
        end
      end
    end

    render('epp/shared/trID', builder: xml)
  end
end
