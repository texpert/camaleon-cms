# frozen_string_literal: true

RSpec.describe 'CamaleonCms::HtmlMailer' do
  before do
    @site = create(:site).decorate
  end

  describe 'empty content' do
    let(:mail) { CamaleonCms::HtmlMailer.sender('test@gmail.com', 'test') }

    it 'renders the subject' do
      expect(mail.subject).to eql('test')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql(['test@gmail.com'])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['owenperedo@gmail.com'])
    end

    it 'html layout text' do
      expect(mail.body.encoded).to match('Visit Site')
    end
  end

  describe 'custom content' do
    let(:mail) do
      CamaleonCms::HtmlMailer.sender('test@gmail.com', 'test', content: 'custom content',
                                                               cc_to: ['a@gmail.com', 'b@gmail.com'])
    end

    it 'renders the sender email' do
      expect(mail.cc).to eql(['a@gmail.com', 'b@gmail.com'])
    end

    it 'custom content' do
      expect(mail.body.encoded).to match('custom content')
    end
  end
end
