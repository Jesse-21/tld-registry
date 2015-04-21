require 'rails_helper'

feature 'Invoice', type: :feature do
  background { create_settings }

  before :all do
    @user = Fabricate(:admin_user, username: 'user1', identity_code: '37810013087')
    Fabricate(:invoice)
  end

  it 'should show index of invoices' do
    sign_in @user
    visit admin_invoices_url
    i = Invoice.first
    page.should have_link("Invoice no. #{i.id}")
  end

  it 'should show invoice' do
    sign_in @user
    visit admin_invoices_url
    i = Invoice.first

    click_link("Invoice no. #{i.id}")
    page.should have_content("Seller")
    page.should have_content("Details")
    page.should have_content("Paldiski mnt. 123")
  end
end