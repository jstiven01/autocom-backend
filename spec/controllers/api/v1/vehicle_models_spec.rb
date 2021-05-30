# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::VehicleModelsController, 'Routes', type: :routing do
  it 'should route to' do
    is_expected.to route(:post, '/api/v1/vehicle_models').to(action: 'create')
  end
end

describe Api::V1::VehicleModelsController, type: :controller do
  let(:parsed_response) { JSON.parse(response.body) }
  let!(:first_vehicle_brand) { create(:vehicle_brand, name: 'Chevrolet') }
  let!(:first_vehicle_model) { create(:vehicle_model, name: 'sedan', vehicle_brand: first_vehicle_brand) }


  describe 'POST #create' do
    let(:params) do
      {
        vehicle_model: {
          name: 'Golf',
          brand: 'VW'
        }
      }
    end
    subject do
      post :create, params: params
    end

    context 'valid request' do
      before do
        subject
      end
      it 'should respond with' do
        expect(response).to have_http_status(:created)

        expect(parsed_response['data']['id'].to_i).to be > 0
        expect(parsed_response['data']['relationships']['vehicle_brand']['data']['id'].to_i).to eq VehicleBrand.last.id
        expect(parsed_response['data']['attributes']['name']).to eq 'Golf'
      end
    end

    context 'invalid request brand nil' do
      let(:params) do
        {
          vehicle_model: {
            name: 'Golf'
          }
        }
      end
      before do
        subject
      end
      it 'should respond with' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    context 'invalid request with duplicate name' do
      let(:params) do
        {
          vehicle_model: {
            name: 'SeDan',
            brand: 'Chevrolet'
          }
        }
      end
      before do
        subject
      end
      it 'should respond with' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
