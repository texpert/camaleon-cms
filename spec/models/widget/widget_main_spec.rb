# frozen_string_literal: true

require 'rails_helper'
require 'shared_specs/sanitize_attrs'

RSpec.describe CamaleonCms::Widget::Main, type: :model do
  it_behaves_like "sanitize attrs", model: CamaleonCms::Widget::Main, attrs_to_sanitize: %i[name description]
end
