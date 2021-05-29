# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VehicleModel, type: :model do
  context 'associations' do
    it 'should respond with' do
      is_expected.to have_many(:vehicles)
      is_expected.to belong_to(:vehicle_brand)
    end
  end

  it { is_expected.to validate_presence_of(:name) }
  describe 'validations' do
    subject { VehicleModel.create(name: 'Here is the content', vehicle_brand: VehicleBrand.create(name: 'brand')) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
