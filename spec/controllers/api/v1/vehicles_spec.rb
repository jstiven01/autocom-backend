# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::VehiclesController, 'Routes', type: :routing do
  it 'should route to' do
    is_expected.to route(:post, '/api/v1/vehicles').to(action: 'create')
    is_expected.to route(:get, '/api/v1/vehicles/search').to(action: 'search')
  end
end

describe Api::V1::VehiclesController, type: :controller do
  let(:parsed_response) { JSON.parse(response.body) }
  let!(:first_vehicle_brand) { create(:vehicle_brand, name: 'Chevrolet') }
  let!(:first_vehicle_model) { create(:vehicle_model, name: 'sedan', vehicle_brand: first_vehicle_brand) }
  let!(:vehicle_by_model) { create_list(:vehicle, 3, vehicle_model: first_vehicle_model) }
  let!(:second_vehicle_brand) { create(:vehicle_brand, name: 'Mazda') }
  let!(:second_vehicle_model) { create(:vehicle_model, name: 'cx', vehicle_brand: second_vehicle_brand) }
  let!(:vehicles) { create_list(:vehicle, 13, vehicle_model: second_vehicle_model) }

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

  describe 'GET #search' do
    let(:params) do
      {
        model_name: 'sed'
      }
    end
    subject do
      get :search, params: params
    end

    context 'search by model' do
      before do
        subject
      end
      it 'should respond with' do
        expect(response).to have_http_status(:ok)
        expect(parsed_response[0]['model_name']).to eq 'sedan'
        expect(parsed_response.size).to eq 3
      end
    end

    context 'search by brand' do
      let(:params) do
        {
          brand_name: 'cheVr'
        }
      end
      before do
        subject
      end
      it 'should respond with' do
        expect(response).to have_http_status(:ok)
        expect(parsed_response[0]['brand_name']).to eq 'Chevrolet'
        expect(parsed_response.size).to eq 3
      end
    end
  end
end
