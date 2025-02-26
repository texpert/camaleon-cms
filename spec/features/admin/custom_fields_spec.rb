# frozen_string_literal: true

RSpec.describe 'the Custom Fields', :js do
  init_site

  it 'Custom fields list' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/settings/custom_fields"
    within '#admin_content' do
      click_link 'Add Field Group'
    end

    # new custom field
    within '#cama_custom_field_form' do
      fill_in 'custom_field_group_name', with: 'Test name'
      fill_in 'custom_field_group_description', with: 'Test name description'
      post_type_id = @site.post_types.where(slug: :post).pick(:id)
      script_string = "$(\"#select_assign_group\").val(\"PostType_Post,#{post_type_id}\")"
      page.execute_script(script_string)

      wait 2
      all('#content-items-default a').each(&:click)
      wait_for_ajax
      first('button[type="submit"]').click
    end
    expect(page).to have_css('.alert-success')

    # update
    within '#edit_custom_field_group' do
      fill_in 'custom_field_group_name', with: 'Test updated'
      first('button[type="submit"]').click
    end
    within '#sortable-fields' do
      expect(page).to have_content('Untitled Text Box')
    end
    expect(page).to have_css('.alert-success')
    expect(page).to have_content('Test updated')
  end

  it 'delete custom field' do
    admin_sign_in
    visit "#{cama_root_relative_path}/admin/settings/custom_fields"
    within '#admin_content' do
      all('table .btn-danger').last.click
    end
    confirm_dialog
    expect(page).to have_css('.alert-success')
  end
end
