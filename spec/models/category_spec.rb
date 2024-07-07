# frozen_string_literal: true

require 'rails_helper'
require 'shared_specs/sanitize_attrs'

RSpec.describe CamaleonCms::Category, type: :model do
  before { allow_any_instance_of(CamaleonCms::Category).to receive(:set_site) }

  it_behaves_like "sanitize attrs", model: CamaleonCms::Category, attrs_to_sanitize: %i[name description]
end
