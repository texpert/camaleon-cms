# frozen_string_literal: true

require 'rails_helper'
require 'shared_specs/sanitize_attrs'

RSpec.describe CamaleonCms::PostType, type: :model do
  init_site

  it_behaves_like 'sanitize attrs', model: described_class, attrs_to_sanitize: %i[name description]
end
