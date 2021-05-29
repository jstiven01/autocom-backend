require 'rails_helper'

RSpec.describe Vehicle, type: :model do
  context 'associations' do
    it 'should respond with' do
      is_expected.to belong_to(:vehicle_model)
    end
  end

  it { is_expected.to validate_presence_of(:mileage) }
  it { is_expected.to validate_presence_of(:year) }
  it { is_expected.to validate_presence_of(:price) }
end
