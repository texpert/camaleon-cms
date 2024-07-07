# frozen_string_literal: true

RSpec.shared_examples 'sanitize attrs' do |model:, attrs_to_sanitize:|
  attrs_to_sanitize.each do |attr|
    it "sanitizes name attribute" do
      attrs_for_creation = { attr => '"><script>alert(1)</script>' }
      attrs_for_creation.merge!(site: @site) if defined?(@site)
      model_instance = model.create(attrs_for_creation)

      expect(model_instance.__send__(attr)).to eql('"&gt;alert(1)')
    end
  end
end
