# frozen_string_literal: true

RSpec.describe 'the Themes', :js do
  init_site

  it 'Themes list' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/appearances/themes"
    expect(page).to have_css('#themes_page')
    within '#themes_page' do
      first('.preview_link').click
    end
    # wait_for_ajax
    # page.within_frame '#ow_inline_modal_iframe' do
    #   page.should have_selector 'body'
    # end
  end
end
