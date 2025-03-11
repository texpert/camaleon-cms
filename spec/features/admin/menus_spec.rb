# frozen_string_literal: true

RSpec.describe 'the Menus', :js do
  init_site

  it 'Menus list' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/appearances/nav_menus"
    expect(page).to have_css('#menu_content')
    within '#menu_items' do
      # post menus
      check('Sample Post')
      page.execute_script('$("#acc-post input").prop("checked", true)')
      page.execute_script('$("#acc-post").prev().find("input").prop("checked", true)')
      page.execute_script('$("#acc-post .add_links_to_menu").click()')
      wait_for_ajax

      # custom links
      wait(2)
      # screenshot_and_save_page
      page.execute_script('$("#menu_items .panel-collapse:last").click()')
      page.execute_script('$("#menu_items").css({background: "red"});')
      wait(2)
      screenshot_and_save_page
      within '.form-custom-link' do
        fill_in 'external_label', with: 'name link'
        fill_in 'external_url', with: 'https://mytest.com'
        find('#add_external_link').click
        wait_for_ajax
      end
    end

    within '#menus_list' do
      all('.delete_menu_item').each do |btn|
        btn.click
        confirm_dialog
        wait_for_ajax
      end
    end
  end

  it 'creates and selects menus' do # rubocop:disable RSpec/NoExpectationExample
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/appearances/nav_menus"

    page.execute_script('jQuery("#switch_nav_menu_form .new_menu_link").click()')

    wait_for_ajax
    within '#ow_inline_modal' do
      fill_in 'nav_menu_name', with: 'Second menu'
      fill_in 'nav_menu_slug', with: 'second-menu'
      click_button 'Create Menu'
      wait_for_ajax
    end

    within '#menu_items' do
      select('Second menu', from: 'menu')

      check('Sample Post')
      page.execute_script('$("#acc-post input").prop("checked", true)')
      page.execute_script('$("#acc-post").prev().find("input").prop("checked", true)')
      page.execute_script('$("#acc-post .add_links_to_menu").click()')
      wait_for_ajax

      select('Main Menu', from: 'menu')
      wait_for_ajax
    end

    within '#menus_list' do
      find('.dd-item', text: 'Welcome')
    end

    within '#menu_items' do
      select('Second menu', from: 'menu')
      wait_for_ajax
    end

    within '#menus_list' do
      find('.dd-item', text: 'Uncategorized')
    end
  end

  it 'deletes menus' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/appearances/nav_menus"
    page.execute_script('jQuery("#switch_nav_menu_form .btn-danger").click()')
    confirm_dialog
    expect(page).to have_css('.alert-success')
  end
end
