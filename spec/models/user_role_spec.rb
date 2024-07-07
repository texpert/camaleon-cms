# frozen_string_literal: true

require 'rails_helper'
require 'shared_specs/sanitize_attrs'

RSpec.describe CamaleonCms::UserRole, type: :model do
  it_behaves_like "sanitize attrs", model: CamaleonCms::UserRole, attrs_to_sanitize: %i[name description]
end
