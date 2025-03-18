require 'spec_helper'

class Fish
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  attr_accessor :name, :type
  def errors
    @errors ||= ActiveModel::Errors.new(self)
  end

  def read_attribute_for_validation(attr)
    send(attr)
  end
end

describe NanoService::ErrorSerializer do
  subject { described_class }

  let(:model) { Fish.new }

  before do
    model.errors.add(:name, message: 'is required')
    model.errors.add(:type, message: 'is invalid')
    model.errors.add(:type, message: 'must be one of (fighting,freshwater)')
  end

  describe '::serialize' do
    it 'serializes model errors for public consumption' do
      expect(subject.serialize(model.errors)).to eq(
        name: ['is required'],
        type: ['is invalid', 'must be one of (fighting,freshwater)'],
        full_messages: [
          'Name is required',
          'Type is invalid',
          'Type must be one of (fighting,freshwater)'
        ]
      )
    end
  end
end
