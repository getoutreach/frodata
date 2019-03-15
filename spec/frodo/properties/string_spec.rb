require 'spec_helper'

describe Frodo::Properties::String do
  let(:subject) { Frodo::Properties::String.new('Stringy', 'This is an example') }

  it { expect(subject).to respond_to(:is_unicode?) }
  it { expect(subject).to respond_to(:has_default_value?) }
  it { expect(subject).to respond_to(:default_value) }

  it { expect(subject.type).to eq('Edm.String') }
  it { expect(subject.value).to eq('This is an example')}

  it { expect(lambda {
    subject.value = 'Another example'
    subject.value
  }.call).to eq('Another example') }

  it { expect(lambda {
    subject.value = nil
    subject.value
  }.call).to eq(nil) }

  describe '#is_unicode?' do
    let(:not_unicode) { Frodo::Properties::String.new('Stringy', 'This is an example', unicode: false) }

    it { expect(subject.is_unicode?).to eq(true) }
    it { expect(not_unicode.is_unicode?).to eq(false) }

    it { expect(subject.value.encoding).to eq(Encoding::UTF_8) }
    it { expect(not_unicode.value.encoding).to eq(Encoding::ASCII) }
  end

  describe 'when #allows_nil? is false' do
    let(:subject) { Frodo::Properties::String.new('Stringy', 'This is an example', allows_nil: false) }

    it { expect {subject.value = nil}.to raise_error(ArgumentError) }
    it { expect {subject.value = 'Test'}.not_to raise_error }
  end

  describe 'with default_value' do
    let(:subject) { Frodo::Properties::String.new('Stringy', nil, default_value: 'Sample Text') }

    it { expect(subject.has_default_value?).to eq(true) }
    it { expect(subject.default_value).to eq('Sample Text') }
  end
end