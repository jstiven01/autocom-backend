# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::VehiclesController, 'Routes', type: :routing do
  it 'should route to' do
    is_expected.to route(:post, '/api/v1/vehicles').to(action: 'create')
  end
end

describe Api::V1::VehiclesController, type: :controller do
  let(:parsed_response) { JSON.parse(response.body) }
  let!(:first_vehicle_brand) { create(:vehicle_brand, name: 'Chevrolet') }
  let!(:first_vehicle_model) { create(:vehicle_model, name: 'sedan', vehicle_brand: first_vehicle_brand) }

  describe 'POST #create' do
    let(:params) do
      {
        vehicle: {
          brand: 'VW',
          model: 'Golf',
          year: '2020',
          price: 100_000
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
        expect(parsed_response['data']['relationships']['vehicle_model']['data']['id'].to_i).to eq VehicleModel.last.id
        expect(parsed_response['data']['attributes']['year']).to eq '2020'
        expect(parsed_response['data']['attributes']['price'].to_i).to eq 100_000
      end
    end

    context 'invalid request fields nil' do
      let(:params) do
        {
          vehicle: {
            model: 'Golf'
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
