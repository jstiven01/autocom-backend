# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VehicleManager::VehicleCreator do
  let!(:first_vehicle_brand) { create(:vehicle_brand, name: 'Chevrolet') }
  let!(:first_vehicle_model) { create(:vehicle_model, name: 'sedan', vehicle_brand: first_vehicle_brand) }

  context 'call' do
    context 'Creating Vehicle with a new VehicleBrand and Vehicle Model' do
      let(:params) do
        {
          'brand' => 'VW',
          'model' => 'Golf',
          'year' => '2020',
          'price' => 100_000
        }
      end
      before do
        described_class.new(params).call
      end

      it 'should respond with' do
        expect(Vehicle.last.price).to eq 100_000
        expect(Vehicle.last.year).to eq '2020'
        expect(VehicleModel.last.name).to eq 'Golf'
        expect(VehicleModel.all.count).to eq 2
        expect(VehicleBrand.last.name).to eq 'VW'
        expect(VehicleBrand.all.count).to eq 2
      end
    end

    context 'Creating Vehicle with an existing VehicleBrand and VehicleModel' do
      let(:params) do
        {
          'brand' => 'Chevrolet',
          'model' => 'sedan',
          'year' => '2010',
          'price' => 50_000
        }
      end

      before do
        described_class.new(params).call
      end

      it 'should respond with' do
        expect(Vehicle.last.price).to eq 50_000
        expect(Vehicle.last.year).to eq '2010'
        expect(VehicleModel.last.name).to eq 'sedan'
        expect(VehicleModel.all.count).to eq 1
        expect(VehicleBrand.last.name).to eq 'Chevrolet'
        expect(VehicleBrand.all.count).to eq 1
      end
    end

    context 'Creating Vehicle with an existing VehicleBrand and different case' do
      let(:params) do
        {
          'brand' => 'ChevroLET',
          'model' => 'SEDan',
          'year' => '2010',
          'price' => 50_000
        }
      end

      before do
        described_class.new(params).call
      end

      it 'should respond with' do
        expect(Vehicle.last.price).to eq 50_000
        expect(Vehicle.last.year).to eq '2010'
        expect(VehicleModel.last.name).to eq 'sedan'
        expect(VehicleModel.all.count).to eq 1
        expect(VehicleBrand.last.name).to eq 'Chevrolet'
        expect(VehicleBrand.all.count).to eq 1
      end
    end
  end
end
