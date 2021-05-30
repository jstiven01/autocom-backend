# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VehicleBrand, type: :model do
  context 'associations' do
    it 'should respond with' do
      is_expected.to have_many(:vehicle_models)
    end
  end

  it { is_expected.to validate_presence_of(:name) }
  describe 'validations' do
    subject { VehicleBrand.create(name: 'Here is the content') }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
