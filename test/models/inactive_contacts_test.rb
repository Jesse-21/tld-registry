require 'test_helper'

class InactiveContactsTest < ActiveSupport::TestCase
  def test_archives_inactive_contacts
    contact_mock = Minitest::Mock.new
    # contact_mock.expect(:archive, nil, [{verified: false}])
    def contact_mock.archive(verified: false); nil; end
    contact_mock.expect(:id, 'id')
    contact_mock.expect(:code, 'code')

    inactive_contacts = InactiveContacts.new([contact_mock])
    inactive_contacts.archive

    assert_mock contact_mock
  end
end
