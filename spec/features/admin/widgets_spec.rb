# frozen_string_literal: true

RSpec.describe 'the Widgets', :js do
  init_site

  # create a widget
  def create_widget
    within '#view_widget_list' do
      first('#new_widget_link').click
      wait_for_ajax
    end
    within '#widget_form' do
      fill_in 'widget_main_name', with: 'test widget'
      fill_in 'widget_main_slug', with: 'test-widget'
      fill_in 'widget_main_description', with: 'lorem ipsum'
      click_button 'Submit'
    end
  end

  it 'Widgets list' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/appearances/widgets/main"
    expect(page).to have_css('#view_widget_list')
    create_widget
    expect(page).to have_css('.alert-success')
    expect(page).to have_content('test-widget')
  end

  it 'Widgets Edit' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/appearances/widgets/main"
    create_widget
    within '#view_widget_list' do
      first('.edit_link').click
      wait_for_ajax
    end
    within '#widget_form' do
      fill_in 'widget_main_name', with: 'test widget updated'
      fill_in 'widget_main_slug', with: 'test-widget-updated'
      fill_in 'widget_main_description', with: 'lorem ipsum updated'
      click_button 'Submit'
    end
    expect(page).to have_css('.alert-success')
    expect(page).to have_content('test-widget-updated')
  end

  it 'Widgets destroy' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/appearances/widgets/main"
    create_widget
    within '#view_widget_list' do
      first('.del_link').click
    end
    screenshot_and_save_page
    confirm_dialog
    expect(page).to have_css('.alert-success')
  end
end
