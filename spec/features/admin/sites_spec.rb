# frozen_string_literal: true

RSpec.describe 'the Sites', :js do
  init_site

  def create_site
    visit "#{cama_root_relative_path}/admin/settings/sites"
    expect(page).to have_content('List Sites')

    # create user role
    within '#admin_content' do
      click_link 'Add Site'
    end
    expect(page).to have_css('#new_site')
    within '#new_site' do
      fill_in 'site_slug', with: 'owen'
      fill_in 'site_name', with: 'Owen sub site'
      click_button 'Submit'
    end
  end

  it 'Sites list' do
    admin_sign_in
    create_site
    expect(page).to have_css('.alert-success')
  end

  it 'Site Edit' do
    admin_sign_in
    create_site
    visit "#{cama_root_relative_path}/admin/settings/sites"
    within '#admin_content' do
      all('.btn-default').last.click
    end
    within '#edit_site' do
      fill_in 'site_name', with: 'Owen Site Title changed'
      click_button 'Submit'
    end
    expect(page).to have_css('.alert-success')
  end

  it 'Site destroy' do
    admin_sign_in
    create_site
    visit "#{cama_root_relative_path}/admin/settings/sites"
    within '#admin_content' do
      all('.btn-danger').last.click
    end
    confirm_dialog
    expect(page).to have_css('.alert-success')
  end
end
