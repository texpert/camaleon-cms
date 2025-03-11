# frozen_string_literal: true

RSpec.describe 'the Menus', :js do
  init_site

  it 'Plugins list' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/plugins"
    expect(page).to have_css('#table-plugins-list')
    expect(page).to have_content('Attack')
    expect(page).to have_content('Contact Form')
    expect(page).to have_content('Front Cache')
    expect(page).to have_content('Active')

    # uninstall plugin
    within '#tab_plugins_active' do
      all('.btn-danger')[0].click
    end
    confirm_dialog
    expect(page).to have_css('.alert-success')

    # install plugin
    page.execute_script('$("#table-plugins-list .nav-tabs li").eq(1).find("a").click()')
    within '#tab_plugins_disabled' do
      all('.btn-primary')[0].click
    end
    confirm_dialog
    expect(page).to have_css('.alert-success')
  end
end
