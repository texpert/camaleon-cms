# frozen_string_literal: true

require 'rails_helper'
require 'shared_specs/sanitize_attrs'

RSpec.describe CamaleonCms::NavMenuItem, type: :model do
  before { allow_any_instance_of(CamaleonCms::NavMenuItem).to receive(:update_count) }

  it_behaves_like "sanitize attrs", model: CamaleonCms::NavMenuItem, attrs_to_sanitize: %i[name description]
end
