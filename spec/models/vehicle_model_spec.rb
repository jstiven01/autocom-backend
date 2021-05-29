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
end
