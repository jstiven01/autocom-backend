# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VehicleModelManager::VehicleModelCreator do
  let!(:first_vehicle_brand) { create(:vehicle_brand, name: 'Chevrolet') }

  context 'call' do
    context 'Creating VehicleModel with a new VehicleBrand' do
      let(:params) do
        {
          'name' => 'Golf',
          'brand' => 'VW'
        }
      end
      before do
        described_class.new(params).call
      end

      it 'should respond with' do
        expect(VehicleModel.last.name).to eq 'Golf'
        expect(VehicleBrand.last.name).to eq 'VW'
        expect(VehicleBrand.all.count).to eq 2
      end
    end

    context 'Creating VehicleModel with an existing VehicleBrand' do
      let(:params) do
        {
          'name' => 'Golf',
          'brand' => 'Chevrolet'
        }
      end

      before do
        described_class.new(params).call
      end

      it 'should respond with' do
        expect(VehicleModel.last.name).to eq 'Golf'
        expect(VehicleBrand.all.count).to eq 1
      end
    end

    context 'Creating VehicleModel with an existing VehicleBrand and different case' do
      let(:params) do
        {
          'name' => 'Golf',
          'brand' => 'CHEVrolet'
        }
      end

      before do
        described_class.new(params).call
      end

      it 'should respond with' do
        expect(VehicleModel.last.name).to eq 'Golf'
        expect(VehicleBrand.all.count).to eq 1
      end
    end
  end
end
