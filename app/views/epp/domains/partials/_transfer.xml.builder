builder.tag!('domain:trnData', 'xmlns:domain' =>
  Xsd::Schema.filename(for_prefix: 'domain-ee', for_version: @schema_version)) do
  builder.tag!('domain:name', dt.domain_name)
  builder.tag!('domain:trStatus', dt.status)
  builder.tag!('domain:reID', dt.new_registrar.code)
  builder.tag!('domain:reDate', dt.transfer_requested_at.try(:iso8601))
  builder.tag!('domain:acID', dt.old_registrar.code)
  builder.tag!('domain:acDate', dt.transferred_at.try(:iso8601) || dt.wait_until.try(:iso8601))
  builder.tag!('domain:exDate', dt.domain_valid_to.iso8601)
end
