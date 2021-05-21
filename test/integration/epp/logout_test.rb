require 'test_helper'

class EppLogoutTest < EppTestCase
  def test_success_response
    post epp_logout_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    assert_epp_response :completed_successfully_ending_session
  end

  def test_ends_current_session
    post epp_logout_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    assert_nil EppSession.find_by(session_id: 'api_bestnames')
  end

  def test_keeps_other_sessions_intact
    post epp_logout_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=api_bestnames' }
    assert EppSession.find_by(session_id: 'api_goodnames')
  end

  def test_anonymous_user
    post epp_logout_path, params: { frame: request_xml },
         headers: { 'HTTP_COOKIE' => 'session=non-existent' }
    assert_epp_response :authorization_error
  end

  private

  def request_xml
    <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <epp xmlns="#{Xsd::Schema.filename(for_prefix: 'epp-ee')}">
        <command>
          <logout/>
        </command>
      </epp>
    XML
  end
end
