# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::VehicleModelsController, 'Routes', type: :routing do
  it 'should route to' do
    is_expected.to route(:post, '/api/v1/vehicle_models').to(action: 'create')
  end
end

=begin 
describe Api::V1::ApplicationsController, type: :controller, vcr: true do
  let(:parsed_response) { JSON.parse(response.body) }

  let!(:dealer) { create(:dealer) }
  let!(:another_dealer) { create(:dealer) }
  let!(:dealer_network_overseer) { create(:dealer) }
  let!(:dealer_network) { create(:dealer_network, :approved, overseer_dealers: [dealer_network_overseer], member_dealers: [dealer, another_dealer]) }

  let!(:homeowner) { create(:homeowner, email:'testcoap@coapplicant.com') }

  let!(:homeowner_active_dealer) { create(:homeowner, dealer_code: dealer_network.dealer_code) }
  let!(:address) { create(:address) }
  let!(:loan) { create(:loan) }
  let!(:financial_detail) { [build(:financial_detail)] }

  let!(:soft_pull) { create(:soft_pull) }

  describe 'POST #create' do
    subject do
      post :create, params: params
    end

    describe 'for dealer' do
      let(:params) do
        {
          homeowner: attributes_for(:homeowner, email:'TestCoap@coapplicant.com'),
          dealer: {
            dealer_code: dealer_network.dealer_code
          },
          application: {
            years_current_address: 1,
            address_attributes: attributes_for(:address)
          }
        }
      end

      context 'with NO authentication header' do
        it { expect(subject).to have_http_status(:unauthorized) }
      end

      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(dealer))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_created_response
            expect(parsed_response['data']['id'].to_i).to be > 0
            expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer.id
            expect(parsed_response['data']['attributes']['pp_id']).to eq Application.last.soft_pull.id.to_s
            expect(Application.last.application_logs.last.initiate_app?).to be_truthy
          end
        end
      end

      context 'with an authentication header organization' do
        before do
          request.headers.merge!(authenticated_header(dealer_network_overseer))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_created_response
            expect(parsed_response['data']['id'].to_i).to be > 0
            expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer_network_overseer.id
          end
        end
      end

      context 'with an authentication header with anothers dealership code' do
        let!(:second_dealer_network_overseer) { create(:dealer) }
        let!(:dealer_second) { create(:dealer) }
        let!(:second_dealer_network) { create(:dealer_network, :approved, member_dealers: [dealer_second], overseer_dealers: [second_dealer_network_overseer]) }

        let(:params) do
          {
            homeowner: attributes_for(:homeowner),
            dealer: {
              dealer_code: second_dealer_network.dealer_code
            },
            application: {
              years_current_address: 1,
              address_attributes: attributes_for(:address)
            }
          }
        end

        before do
          request.headers.merge!(authenticated_header(dealer))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_created_response
            expect(parsed_response['data']['id'].to_i).to be > 0
            expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer.id
          end
        end
      end
    end

    describe 'for homeowner' do
      let(:params) do
        {
          dealer: {
            dealer_code: dealer_network.dealer_code
          },
          application: {
            years_current_address: 1,
            driver_license: Rack::Test::UploadedFile.new('spec/files/driver_license.jpeg', 'image/jpeg'),
            address_attributes: attributes_for(:address)
          },
          financial_details: {
            '0': attributes_for(:financial_detail, :homeowner)
          }
        }
      end

      context 'with NO authentication header' do
        it { expect(subject).to have_http_status(:unauthorized) }
      end

      context 'with an authentication header and inactive dealer' do
        context 'valid request' do
          let!(:app) do
            create(:application, :submitted, :with_coapplicant_email, homeowner: homeowner, dealer: dealer, credit_limit: 100_000)
          end
          before do
            request.headers.merge!(authenticated_header(homeowner))
            subject
          end

          context 'without coapplicant' do
            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['meta']['has_coapplicant']).to be_falsey
              expect(parsed_response['data']['attributes']['pp_id']).to eq Application.last.soft_pull.id.to_s
              expect(parsed_response['data']['attributes']['submitted_at']).to be_nil
              expect(parsed_response['data']['relationships']['financial_details']['data'].size).to eq 1
              expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer_network_overseer.id
            end
          end

          context 'with coapplicant' do
            let(:homeowner_attrs) { attributes_for(:homeowner) }
            let(:coapplicant_attrs) { attributes_for(:homeowner) }
            let(:address_attrs) { attributes_for(:address) }
            let(:params) do
              {
                dealer: {
                  dealer_code: dealer_network.dealer_code
                },
                homeowner: homeowner_attrs,
                has_coapplicant: true,
                coapplicant: coapplicant_attrs,
                application: {
                  years_current_address: 1,
                  address_attributes: address_attrs,
                  last_step: 4,
                  driver_license_uid: '123123qdsad'
                },
                financial_details: {
                  '0': attributes_for(:financial_detail, :homeowner),
                  '1': attributes_for(:financial_detail, :coapplicant)
                }
              }
            end

            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['relationships']['financial_details']['data'].size).to eq 2
              expect(parsed_response['data']['attributes']['draft_status']).to eq 'drafted'

              expect(Date.parse(parsed_response['data']['attributes']['birthday'])).to eq homeowner_attrs[:birthday]
              expect(parsed_response['data']['attributes']['phone_number']).to eq homeowner_attrs[:phone_number]
              expect(parsed_response['data']['attributes']['active_military']).to eq homeowner_attrs[:active_military]
              expect(parsed_response['data']['attributes']['us_citizen']).to eq homeowner_attrs[:us_citizen]

              expect(parsed_response['data']['attributes']['coapplicant_name']).to eq coapplicant_attrs[:name]
              expect(parsed_response['data']['attributes']['coapplicant_last_name']).to eq coapplicant_attrs[:last_name]
              expect(Date.parse(parsed_response['data']['attributes']['coapplicant_birthday'])).to eq coapplicant_attrs[:birthday]
              expect(parsed_response['data']['attributes']['coapplicant_phone_number']).to eq coapplicant_attrs[:phone_number]
              expect(parsed_response['data']['attributes']['coapplicant_email']).to eq coapplicant_attrs[:email]
              expect(parsed_response['data']['attributes']['coapplicant_active_military']).to eq coapplicant_attrs[:active_military]
              expect(parsed_response['data']['attributes']['coapplicant_us_citizen']).to eq coapplicant_attrs[:us_citizen]

              expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer_network_overseer.id
              expect(parsed_response['data']['attributes']['dealer_code']).to eq dealer_network.dealer_code.to_s
              expect(parsed_response['data']['attributes']['last_step']).to eq 4
              expect(parsed_response['data']['attributes']['driver_license_uid']).to eq '123123qdsad'

              expect(parsed_response['included'].find { |i| i['type'] == 'address' }['attributes']['street_address']).to eq address_attrs[:street_address]
              expect(parsed_response['included'].find { |i| i['type'] == 'address' }['attributes']['address_line_2']).to eq address_attrs[:address_line_2]
              expect(parsed_response['included'].find { |i| i['type'] == 'address' }['attributes']['state']).to eq address_attrs[:state]
              expect(parsed_response['included'].find { |i| i['type'] == 'address' }['attributes']['city']).to eq address_attrs[:city]
              expect(parsed_response['included'].find { |i| i['type'] == 'address' }['attributes']['zip_code']).to eq address_attrs[:zip_code]

              expect(parsed_response['data']['meta']['has_coapplicant']).to be_truthy
            end
          end

          context 'with coapplicant email that is in other application' do
            let(:homeowner_attrs) { attributes_for(:homeowner, email:'testcoap@coapplicant.com') }
            let(:coapplicant_attrs) { attributes_for(:homeowner, email:'testcoap@coapplicant.com' ) }
            let(:address_attrs) { attributes_for(:address) }
            let(:params) do
              {
                dealer: {
                  dealer_code: dealer_network.dealer_code
                },
                homeowner: homeowner_attrs,
                has_coapplicant: true,
                coapplicant: coapplicant_attrs,
                application: {
                  years_current_address: 1,
                  address_attributes: address_attrs,
                  last_step: 4,
                  driver_license_uid: '123123qdsad'
                },
                financial_details: {
                  '0': attributes_for(:financial_detail, :homeowner),
                  '1': attributes_for(:financial_detail, :coapplicant)
                }
              }
            end

            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['relationships']['financial_details']['data'].size).to eq 2
              expect(parsed_response['data']['attributes']['draft_status']).to eq 'drafted'
              expect(parsed_response['data']['attributes']['coapplicant_name']).to eq coapplicant_attrs[:name]
              expect(parsed_response['data']['attributes']['coapplicant_last_name']).to eq coapplicant_attrs[:last_name]
              expect(Date.parse(parsed_response['data']['attributes']['coapplicant_birthday'])).to eq coapplicant_attrs[:birthday]
              expect(parsed_response['data']['attributes']['coapplicant_phone_number']).to eq coapplicant_attrs[:phone_number]
              expect(parsed_response['data']['attributes']['coapplicant_email']).to eq 'testcoap@coapplicant.com'
            end
          end

          context 'without dealer code' do
            let(:params) do
              {
                application: {
                  years_current_address: 1,
                  address_attributes: attributes_for(:address)
                },
                dealer: {
                  filler: 1
                },
                financial_details: {
                  '0': attributes_for(:financial_detail, :homeowner)
                }
              }
            end

            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['relationships']['dealer']['data']).to be_nil
            end
          end

          context 'without dealer param' do
            let(:params) do
              {
                application: {
                  years_current_address: 1,
                  address_attributes: attributes_for(:address)
                },
                financial_details: {
                  '0': attributes_for(:financial_detail, :homeowner)
                }
              }
            end

            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['relationships']['dealer']['data']).to be_nil
            end
          end

          context 'with a different dealer' do
            let!(:second_dealer_network_overseer) { create(:dealer) }
            let!(:dealer_second) { create(:dealer) }
            let!(:second_dealer_network) { create(:dealer_network, :approved, member_dealers: [dealer_second], overseer_dealers: [second_dealer_network_overseer]) }

            let(:params) do
              {
                dealer: {
                  dealer_code: second_dealer_network.dealer_code
                }
              }
            end

            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq second_dealer_network_overseer.id
            end
          end

          context "with a homeowner's Inactive Dealer" do
            let(:params) do
              {
                application: {
                },
                dealer: {
                }
              }
            end
            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['relationships']['dealer']['data']).to be_nil
              expect(parsed_response['data']['attributes']['dealer_code']).to be_nil
            end
          end

          context 'with a phone number' do
            let(:phone_number) { Faker::PhoneNumber.cell_phone }
            let(:other_phone_number) { Faker::PhoneNumber.cell_phone }
            let(:homeowner_attrs) { attributes_for(:homeowner).merge({ phone_number: phone_number }) }

            context 'valid request' do
              let(:params) do
                {
                  homeowner: homeowner_attrs,
                  application: {}
                }
              end

              it 'should respond with' do
                a_created_response
                expect(parsed_response['data']['attributes']['phone_number']).to eq phone_number
              end
            end

            context 'with coapplicant' do
              let(:coapplicant_attrs) { attributes_for(:homeowner).merge({ phone_number: other_phone_number }) }
              let(:params) do
                {
                  homeowner: homeowner_attrs,
                  has_coapplicant: true,
                  coapplicant: coapplicant_attrs,
                  application: {}
                }
              end

              it 'should respond with' do
                a_created_response
                expect(parsed_response['data']['attributes']['coapplicant_phone_number']).to eq other_phone_number
              end
            end
          end

          context 'with no draft application' do
            let!(:app_submitted) do
              create(:application, :submitted, homeowner: homeowner, dealer: dealer, address: address,
                                               financial_details: financial_detail, name: homeowner.name, last_name: homeowner.last_name)
            end
            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['attributes']['name']).to eq app_submitted.name
            end
          end

          context 'with a soft_pull' do
            let(:params) do
              {
                dealer: {
                  dealer_code: dealer_network.dealer_code
                },
                application: {
                  years_current_address: 1,
                  driver_license: Rack::Test::UploadedFile.new('spec/files/driver_license.jpeg', 'image/jpeg'),
                  soft_pull_id: soft_pull.id,
                  address_attributes: attributes_for(:address)
                },
                financial_details: {
                  '0': attributes_for(:financial_detail, :homeowner)
                }
              }
            end

            it 'should respond with' do
              a_created_response
              expect(Application.find(parsed_response['data']['id'].to_i).soft_pull).not_to be_nil
            end
          end
        end
        # TODO: Check failed case
        #         context 'with 3 approved applications created' do
        #           before do
        #             request.headers.merge!(authenticated_header(approved_homeowner))
        #             subject
        #           end
        #
        #           it_behaves_like 'a failure response'
        #         end
        context 'with 1 drafted application' do
          let!(:drafted_apps_homeowner) { create(:homeowner) }
          let!(:app_drafted) do
            create(:application, homeowner: drafted_apps_homeowner, dealer: dealer, name: drafted_apps_homeowner.name, last_name: drafted_apps_homeowner.last_name)
          end

          let(:params) do
            {
              dealer: {
              },
              application: {
              }
            }
          end

          before do
            request.headers.merge!(authenticated_header(drafted_apps_homeowner))
            subject
          end

          it 'should respond with' do
            a_created_response
            expect(parsed_response['data']['attributes']['name']).to eq drafted_apps_homeowner.name
            expect(parsed_response['data']['attributes']['last_name']).to eq drafted_apps_homeowner.last_name
          end
        end
      end

      context 'with an authentication header and active dealer' do
        context 'valid request' do
          before do
            request.headers.merge!(authenticated_header(homeowner_active_dealer))
            @app_with_ho_active_dealer = create(:application, :submitted, years_current_address: 10, homeowner: homeowner_active_dealer, dealer: another_dealer, address: address,
                                                                          financial_details: financial_detail, name: homeowner_active_dealer.name, last_name: homeowner_active_dealer.last_name)
            subject
          end
          context "with a homeowner's Active Dealer" do
            let(:params) do
              {
                application: {
                },
                dealer: {
                }
              }
            end

            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer_network_overseer.id
              expect(parsed_response['data']['attributes']['dealer_code']).to eq dealer_network.dealer_code.to_s
            end
          end

          context 'with no draft application' do
            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['attributes']['name']).to eq @app_with_ho_active_dealer.name
            end
          end
        end
      end

      context 'with an authentication header with new homeowner' do
        context 'valid request' do
          before do
            @another_homeowner = create(:homeowner)
            request.headers.merge!(authenticated_header(@another_homeowner))
            subject
          end

          context 'with first time application creation' do
            it 'should respond with' do
              a_created_response
              expect(parsed_response['data']['id'].to_i).to be > 0
              expect(parsed_response['data']['attributes']['name']).to eq @another_homeowner.name
              expect(parsed_response['data']['attributes']['draft_status']).to eq 'drafted'
            end
          end
        end
      end
    end

    describe 'for organization' do
      let!(:org_user) { create(:dealer) }
      let!(:organization) { create(:organization, overseers: [org_user]) }
      let!(:dealer_user) { create(:dealer) }
      let!(:dealer_network) { create(:dealer_network, overseer_dealers: [dealer_user]) }
      let!(:soft_pull) { create(:soft_pull, :approved, dealer: dealer_user) }

      let(:params) do
        {
          homeowner: attributes_for(:homeowner),
          application: {
            address_attributes: attributes_for(:address),
            soft_pull_id: soft_pull.id
          }
        }
      end

      before do
        organization.dealer_networks << dealer_network
        request.headers.merge!(authenticated_header(org_user))
        subject
      end

      describe 'with a valid dealer associated to the soft pull' do
        it 'should respond with' do
          a_created_response
          expect(Application.find(parsed_response['data']['id']).dealer).to eq dealer_user
          expect(Application.find(parsed_response['data']['id']).dealer.dealer_network).to eq dealer_network
        end
      end
    end
  end

  describe 'GET #index' do
    let(:params) do
      {

      }
    end

    let!(:approved_homeowner) { create(:homeowner) }
    let!(:apps) do
      create_list(:application, 3, :approved, homeowner: approved_homeowner, dealer: dealer, address: create(:address),
                                              financial_details: financial_detail)
    end
    let!(:applications_list) do
      create_list(:application, 20, homeowner: homeowner, dealer: dealer, address: create(:address),
                                    financial_details: financial_detail)
    end

    subject do
      get :index, params: params
    end

    context 'with NO authentication header' do
      it { expect(subject).to have_http_status(:unauthorized) }
    end

    context 'homeowners' do
      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(homeowner))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_success_response
            expect(parsed_response['data'].size).to be > 0
          end
        end

        context 'paginate response' do
          context 'default to 20' do
            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 20
            end
          end

          context 'get 15' do
            let(:params) do
              {
                'per_page': 15
              }
            end

            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 15
            end
          end
        end
      end
    end

    describe 'for dealers' do
      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(dealer))
          create(:application, :submitted, homeowner: homeowner, dealer: dealer, address: address,
                                           financial_details: financial_detail, name: homeowner.name, last_name: homeowner.last_name)
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_success_response
            expect(parsed_response['data'].size).to be > 0
          end
        end

        context 'paginate response' do
          context 'default to 20' do
            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 20
            end
          end

          context 'get 15' do
            let(:params) do
              {
                'per_page': 15
              }
            end

            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 15
            end
          end
        end

        context 'filter response submitted' do
          let(:params) do
            {
              status: 'submitted'
            }
          end

          context 'display filtered submitted draft status' do
            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 1
            end
          end
        end

        context 'filter response submitted sort pp_id asc' do
          let(:params) do
            {
              status: 'submitted',
              'order': 'pp_id',
              'sort': 'asc'
            }
          end

          context 'display filtered submitted draft status' do
            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 1
              expect(parsed_response['data'][0]['attributes']['pp_id']).to eq Application.submitted.order('pp_id::integer asc').last.pp_id
            end
          end
        end

        context 'filter response drafted' do
          let(:params) do
            {
              status: 'drafted'
            }
          end

          context 'display filtered drafted draft status' do
            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 20
            end
          end
        end

        context 'filter response cancelled' do
          let(:params) do
            {
              status: 'cancelled'
            }
          end

          context 'display filtered cancelled draft status' do
            it 'should respond with' do
              a_success_response
              expect(parsed_response['data'].size).to eq 20
            end
          end
        end

        context 'filter search text submitted apps' do
          let!(:app_email_pp) do
            create(:application, :submitted, homeowner: homeowner, dealer: dealer, address: address, email: 'user_powerpay@example.com',
                                             financial_details: financial_detail, name: homeowner.name, last_name: homeowner.last_name)
          end
          let(:params) do
            {
              status: 'submitted',
              search_text: app_email_pp.pp_id
            }
          end

          it 'should respond with' do
            a_success_response
            expect(parsed_response['data'].size).to eq 1
            expect(parsed_response['data'][0]['attributes']['pp_id']).to eq app_email_pp.pp_id
          end
        end
      end
    end
  end

  describe 'GET #show' do
    let!(:app) do
      create(:application, years_current_address: 10, homeowner: homeowner, dealer: dealer, address: address,
                           financial_details: financial_detail)
    end

    let(:params) do
      {
        id: app.id
      }
    end

    subject do
      get :show, params: params
    end

    context 'with NO authentication header' do
      it { expect(subject).to have_http_status(:unauthorized) }
    end

    describe 'for homeowners' do
      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(homeowner))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['id'].to_i).to eq app.id
            expect(parsed_response['data']['attributes']['pp_id']).to eq app.soft_pull.id.to_s
          end
        end
      end
    end

    describe 'for dealers' do
      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(dealer))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['id'].to_i).to eq app.id
            expect(parsed_response['data']['attributes']['pp_id']).to eq app.soft_pull.id.to_s
          end
        end

        context 'with loan' do
          let(:app_with_loan) do
            create(:application, years_current_address: 10, homeowner: homeowner, dealer: dealer, address: address,
                                 financial_details: financial_detail, loan: loan)
          end

          let(:params) do
            {
              id: app_with_loan.id
            }
          end

          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['id'].to_i).to eq app_with_loan.id
            expect(parsed_response['data']['relationships']['loan']['data']).not_to be_nil
          end
        end

        context 'with documents' do
          let(:params) do
            {
              id: create(:application, :submitted, homeowner: homeowner, dealer: dealer, documents: [create(:document)]).id
            }
          end

          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['attributes']['required_docs']).to include('install_contract', 'driver_license')
          end
        end
      end
    end

    describe 'for a dealer network overseer' do
      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(dealer_network_overseer))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['id'].to_i).to eq app.id
          end
        end
      end
    end
  end

  describe 'PATCH #update' do
    let!(:app) do
      create(:application, years_current_address: 10, homeowner: homeowner, dealer: dealer, address: address,
                           financial_details: financial_detail)
    end
    let(:params) do
      {
        id: app.id
      }
    end

    subject do
      patch :update, params: params
    end

    describe 'with NO authentication header' do
      it { expect(subject).to have_http_status(:unauthorized) }
    end

    describe 'for member dealer' do
      let(:params) do
        {
          id: app.id,
          homeowner: attributes_for(:homeowner).merge(name: 'John'),
          application: {
            years_current_address: 10,
            address_attributes: attributes_for(:address)
          }
        }
      end

      before do
        request.headers.merge!(authenticated_header(dealer))
        subject
      end

      it 'should respond with' do
        a_success_response
        expect(parsed_response['data']['id'].to_i).to eq app.id
        expect(parsed_response['data']['attributes']['pp_id']).to eq app.soft_pull.id.to_s
        expect(parsed_response['data']['attributes']['years_current_address'].to_i).to eq 10
        expect(parsed_response['included'].find { |i| i['type'] == 'homeowner' }['attributes']['name']).to eq 'John'
        expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer.id
      end
    end

    describe 'sets driver license uuid' do
      let(:uuid) { 'd5db69f7-e470-4d7a-b5d7-3657f1249211' }

      let(:params) do
        {
          id: app.id,
          homeowner: attributes_for(:homeowner).merge(name: 'John'),
          application: {
            years_current_address: 10,
            address_attributes: attributes_for(:address)
          },
          driver_license: {
            uuid: uuid
          }
        }
      end

      before do
        request.headers.merge!(authenticated_header(dealer))
      end

      it 'sets soft pull driver license uid and retrieves driver license' do
        expect { subject }
          .to change { app.reload.soft_pull.driver_license_uid }
          .from(nil)
          .to(uuid)
      end
    end

    describe 'for overseer dealer' do
      let(:params) do
        {
          id: app.id,
          homeowner: attributes_for(:homeowner).merge(name: 'John'),
          application: {
            years_current_address: 10,
            address_attributes: attributes_for(:address)
          }
        }
      end

      before do
        request.headers.merge!(authenticated_header(dealer_network_overseer))
        subject
      end

      it 'should respond with' do
        a_success_response
        expect(parsed_response['data']['id'].to_i).to eq app.id
        expect(parsed_response['data']['attributes']['years_current_address'].to_i).to eq 10
        expect(parsed_response['included'].find { |i| i['type'] == 'homeowner' }['attributes']['name']).to eq 'John'
        expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq dealer.id
      end
    end

    describe 'for homeowner' do
      let(:coapplicant_attrs) { attributes_for(:homeowner) }
      let(:params) do
        {
          id: app.id,
          coapplicant: coapplicant_attrs,
          has_coapplicant: false,
          application: {
            driver_license: Rack::Test::UploadedFile.new('spec/files/driver_license.jpeg', 'image/jpeg'),
            address_attributes: attributes_for(:address).merge(
              street_address: '123 Street address'
            )
          },
          financial_details: {
            '0': attributes_for(:financial_detail, :homeowner).merge(
              employer_name: 'John Doe Inc'
            ),
            '1': attributes_for(:financial_detail, :coapplicant, anual_income: nil)
          }
        }
      end

      context 'with NO authentication header' do
        it { expect(subject).to have_http_status(:unauthorized) }
      end

      context 'with an authentication header' do
        context 'valid request' do
          before do
            request.headers.merge!(authenticated_header(homeowner))
            subject
          end

          context 'without coapplicant' do
            it 'should respond with' do
              a_success_response
              expect(parsed_response['data']['id'].to_i).to eq app.id
              expect(parsed_response['included'].find { |i| i['type'] == 'address' }['attributes']['street_address']).to eq '123 Street address'
              expect(parsed_response['included'].find { |i| i['type'] == 'financial_detail' && i['attributes']['employer_name'] }).not_to be_nil
            end
          end

          context 'with empty application' do
            let(:homeowner_attrs) { attributes_for(:homeowner) }
            let(:address_attrs) { attributes_for(:address) }
            let(:empty_app) { create(:application, homeowner: homeowner) }

            let(:params) do
              {
                id: empty_app.id,
                homeowner: homeowner_attrs,
                has_coapplicant: true,
                coapplicant: coapplicant_attrs,
                application: {
                  years_current_address: 1,
                  address_attributes: address_attrs
                },
                financial_details: {
                  '0': attributes_for(:financial_detail, :homeowner).merge(
                    employer_name: 'John Doe Inc'
                  ),
                  '1': attributes_for(:financial_detail, :coapplicant)
                }
              }
            end

            it 'should respond with' do
              a_success_response
              expect(parsed_response['data']['id'].to_i).to eq empty_app.id

              expect(parsed_response['data']['attributes']['name']).to eq homeowner_attrs[:name]
              expect(parsed_response['data']['attributes']['last_name']).to eq homeowner_attrs[:last_name]
              expect(Date.parse(parsed_response['data']['attributes']['birthday'])).to eq homeowner_attrs[:birthday]
              expect(parsed_response['data']['attributes']['phone_number']).to eq homeowner_attrs[:phone_number]
              expect(parsed_response['data']['attributes']['email']).to eq homeowner_attrs[:email]
              expect(parsed_response['data']['attributes']['active_military']).to eq homeowner_attrs[:active_military]
              expect(parsed_response['data']['attributes']['us_citizen']).to eq homeowner_attrs[:us_citizen]

              expect(parsed_response['data']['attributes']['coapplicant_name']).to eq coapplicant_attrs[:name]
              expect(parsed_response['data']['attributes']['coapplicant_last_name']).to eq coapplicant_attrs[:last_name]
              expect(Date.parse(parsed_response['data']['attributes']['coapplicant_birthday'])).to eq coapplicant_attrs[:birthday]
              expect(parsed_response['data']['attributes']['coapplicant_phone_number']).to eq coapplicant_attrs[:phone_number]
              expect(parsed_response['data']['attributes']['coapplicant_email']).to eq coapplicant_attrs[:email]
              expect(parsed_response['data']['attributes']['coapplicant_active_military']).to eq coapplicant_attrs[:active_military]
              expect(parsed_response['data']['attributes']['coapplicant_us_citizen']).to eq coapplicant_attrs[:us_citizen]

              expect(parsed_response['included'].find { |i| i['type'] == 'financial_detail' && i['attributes']['employer_name'] == 'John Doe Inc' }).not_to be_nil
            end

            context 'with coapplicant activated without params' do
              let(:params) do
                {
                  id: empty_app.id,
                  homeowner: homeowner_attrs,
                  has_coapplicant: true,
                  application: {
                    years_current_address: 1,
                    address_attributes: address_attrs
                  },
                  financial_details: {
                    '0': attributes_for(:financial_detail, :homeowner).merge(
                      employer_name: 'John Doe Inc'
                    ),
                    '1': attributes_for(:financial_detail, :coapplicant)
                  }
                }
              end

              it 'should respond with' do
                a_success_response
              end
            end
          end

          context "changing homeowner's default dealer" do
            let!(:app_default_dealer) do
              create(:application, homeowner: homeowner, dealer: another_dealer, draft_status: 'drafted')
            end

            let!(:second_dealer_network_overseer) { create(:dealer) }
            let!(:dealer_second) { create(:dealer) }
            let!(:second_dealer_network) { create(:dealer_network, :approved, member_dealers: [dealer_second], overseer_dealers: [second_dealer_network_overseer]) }

            let(:params) do
              {
                id: app_default_dealer.id,
                dealer: {
                  dealer_code: second_dealer_network.dealer_code
                },
                application: {
                },
                financial_details: {
                }
              }
            end

            it 'should respond with' do
              a_success_response
              expect(parsed_response['data']['id'].to_i).to eq app_default_dealer.id
              expect(parsed_response['data']['attributes']['dealer_code']).to eq second_dealer_network.dealer_code.to_s
              expect(parsed_response['data']['relationships']['dealer']['data']['id'].to_i).to eq second_dealer_network_overseer.id
            end
          end
        end
      end
    end
  end

  describe 'PATCH #cancel' do
    subject do
      post :cancel, params: params
    end

    describe 'for homeowner' do
      let(:params) do
        {
          id: create(:application, years_current_address: 10, homeowner: homeowner, dealer: dealer, address: address,
                                   financial_details: financial_detail).id
        }
      end

      context 'with NO authentication header' do
        it { expect(subject).to have_http_status(:unauthorized) }
      end

      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(homeowner))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['attributes']['draft_status']).to eq 'canceled'
          end
        end

        context 'application not found' do
          let(:params) do
            {
              id: 0
            }
          end

          it_behaves_like 'a not found response'
        end
      end
    end
  end

  describe 'PATCH #submit' do
    subject do
      patch :submit, params: params
    end

    let(:app) do
      create(:application, years_current_address: 10, homeowner: homeowner, dealer: dealer, address: address,
                           financial_details: financial_detail)
    end

    let(:params) do
      {
        id: app.id,
        application: {
          years_current_address: 20
        }
      }
    end

    context 'with NO authentication header' do
      it { expect(subject).to have_http_status(:unauthorized) }
    end

    context 'with an authentication header' do
      before do
        request.headers.merge!(authenticated_header(homeowner))
        subject
      end

      context 'valid request' do
        it 'should respond with' do
          a_success_response
          expect(parsed_response['data']['attributes']['draft_status']).to eq 'submitted'
          expect(parsed_response['data']['attributes']['years_current_address']).to eq 20
          expect(parsed_response['data']['attributes']['submitted_at']).not_to be_nil
        end
      end

      context 'application not found' do
        let(:params) do
          {
            id: 0
          }
        end

        it_behaves_like 'a not found response'
      end

      context 'application already submitted' do
        let(:params) do
          {
            id: create(:application, :submitted, homeowner: homeowner, dealer: dealer, address: address,
                                                 financial_details: financial_detail, name: homeowner.name, last_name: homeowner.last_name).id
          }
        end

        it_behaves_like 'a not found response'
      end

      context 'with wrong financial details' do
        let(:params) do
          {
            "application": {
              "address_attributes": {
                "street_address": '26723 Huntwood Ave, Hayward',
                "address_line2": '1',
                "zip_code": '94102',
                "city": 'san francisco',
                "state": 'California'
              },
              "years_current_address": '7'
            },
            "financial_details": {
              "0": { "employment_type": 'retired', "request_amount": '50000', "term": '5', "user_type": 'homeowner' },
              "1": { "employment_type": 'employed', "request_amount": '50000', "term": '5' }

            },
            "homeowner": {
              "name": 'Test',
              "last_name": 'user',
              "birthday": 'Mon Dec 12 1994 00:00:00 GMT-0500 (Colombia Standard Time)',
              "email": 'santiago.llanos+test11231231@koombea.com',
              "ssn": '123421',
              "active_military": 'true',
              "owner": 'true'

            },
            "id": app.id
          }
        end

        it 'should respond with' do
          a_success_response
          expect(parsed_response['data']['attributes']['draft_status']).to eq 'submitted'
        end
      end

      context 'with a phone number' do
        let(:phone_number) { Faker::PhoneNumber.cell_phone }
        let(:other_phone_number) { Faker::PhoneNumber.cell_phone }
        let(:homeowner_attrs) { attributes_for(:homeowner).merge({ phone_number: phone_number }) }

        context 'valid request' do
          let(:params) do
            {
              id: app.id,
              homeowner: homeowner_attrs,
              application: {}
            }
          end

          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['attributes']['phone_number']).to eq phone_number
          end
        end

        context 'with coapplicant' do
          let(:coapplicant_attrs) { attributes_for(:homeowner).merge({ phone_number: other_phone_number }) }
          let(:params) do
            {
              id: app.id,
              homeowner: homeowner_attrs,
              has_coapplicant: true,
              coapplicant: coapplicant_attrs,
              application: {}
            }
          end

          it 'should respond with' do
            a_success_response
            expect(parsed_response['data']['attributes']['coapplicant_phone_number']).to eq other_phone_number
          end
        end
      end
    end

    context 'for dealer' do
      let(:created_homeowner) { create(:homeowner) }
      let(:empty_app_for_dealer) { create(:application, dealer: dealer) }

      before do
        request.headers.merge!(authenticated_header(dealer))
        subject
      end

      context 'for created homeowner' do
        let(:params) do
          {
            "has_dealer": 'true',
            "dealer": {
              "dealer_code": '3393'
            },
            "loaded_dealer": {
              "id": '150', "name": 'Ferdinand', "last_name": 'Von Aegir', "email": 'santiago.llanos+d4t3@koombea.com', "dealer_code": '3393',
              "business": {
                "name": 'Danielle Reese'
              },
              "address": {
                "city": 'Chicago', "state": 'Illinois'
              }
            },
            "application": {
              "address_attributes": {
                "street_address": '26723 Huntwood Ave, Hayward',
                "address_line2": '2',
                "zip_code": '94102',
                "city": 'san francisco',
                "state": 'California'
              },
              "years_current_address": '26723 Huntwood Ave, Hayward'
            },
            "financial_details": {
              "0": {
                "occupation": 'President', "employer_name": 'demo 31', "employer_zip": '94602', "employer_time": '5', "employment_type": 'self_employed', "request_amount": '90000', "term": '10', "user_type": 'homeowner'
              },
              "1": {
                "employment_type": 'employed', "request_amount": '50000', "term": '5', "user_type": 'coapplicant'
              }
            },
            "homeowner": {
              "name": 'santiago',
              "last_name": 'Llanos',
              "birthday": 'Mon Dec 12 1994 00:00:00 GMT-0500 (Colombia Standard Time)',
              "email": created_homeowner.email,
              "ssn": '123421',
              "active_military": 'true',
              "owner": 'true'
            },
            "id": empty_app_for_dealer.id
          }
        end

        it 'should respond with' do
          a_success_response
          expect(parsed_response['data']['attributes']['draft_status']).to eq 'submitted'
          expect(parsed_response['data']['relationships']['homeowner']['data']).not_to be_nil
        end
      end

      context 'for a new homeowner' do
        let(:params) do
          {
            "has_dealer": 'true',
            "dealer": {
              "dealer_code": '3393'
            },
            "loaded_dealer": {
              "id": '150', "name": 'Ferdinand', "last_name": 'Von Aegir', "email": 'santiago.llanos+d4t3@koombea.com', "dealer_code": '3393',
              "business": {
                "name": 'Danielle Reese'
              },
              "address": {
                "city": 'Chicago', "state": 'Illinois'
              }
            },
            "application": {
              "address_attributes": {
                "street_address": '26723 Huntwood Ave, Hayward',
                "address_line2": '2',
                "zip_code": '94102',
                "city": 'san francisco',
                "state": 'California'
              },
              "years_current_address": '26723 Huntwood Ave, Hayward'
            },
            "financial_details": {
              "0": {
                "occupation": 'President', "employer_name": 'demo 31', "employer_zip": '94602', "employer_time": '5', "employment_type": 'self_employed', "request_amount": '90000', "term": '10', "user_type": 'homeowner'
              },
              "1": {
                "employment_type": 'employed', "request_amount": '50000', "term": '5', "user_type": 'coapplicant'
              }
            },
            "homeowner": {
              "name": 'santiago',
              "last_name": 'Llanos',
              "birthday": 'Mon Dec 12 1994 00:00:00 GMT-0500 (Colombia Standard Time)',
              "email": 'santiago.llanos@koombea.com',
              "ssn": '123421',
              "active_military": 'true',
              "owner": 'true'
            },
            "id": empty_app_for_dealer.id
          }
        end

        it 'should respond with' do
          a_success_response
          expect(parsed_response['data']['attributes']['draft_status']).to eq 'submitted'
          expect(parsed_response['data']['relationships']['homeowner']['data']).not_to be_nil
        end
      end

       context 'with a capital letter in homeowner email' do
        let(:app) do
          create(:application, years_current_address: 10, dealer: dealer, address: address,
                                financial_details: financial_detail)
        end
        let(:homeowner_attrs) { attributes_for(:homeowner).merge({ email: 'johN@powerpay.com' }) }
        let(:params) do
          {
            id: app.id,
            homeowner: homeowner_attrs,
            application: {}
          }
        end
         it 'should respond with' do
          a_success_response
          expect(app.reload.homeowner).not_to be_nil
          expect(app.reload.homeowner.email).to eq 'john@powerpay.com'
        end
      end
    end
  end

  describe 'PATCH #assign' do
    subject do
      patch :assign, params: params
    end

    let!(:app_sample) do
      create(:application, years_current_address: 10, homeowner: homeowner, address: address,
                           financial_details: financial_detail, dealer: another_dealer)
    end

    # let!(:app_sample_1) do
    #   create(:application, years_current_address: 10, homeowner: homeowner, address: address,
    #                        financial_details: financial_detail, dealer: another_dealer)
    # end
    # let!(:app_sample_2) do
    #   create(:application, years_current_address: 10, homeowner: homeowner, address: address,
    #                        financial_details: financial_detail, dealer: another_dealer)
    # end
    # let!(:app_sample_3) do
    #   create(:application, years_current_address: 10, homeowner: homeowner, address: address,
    #                        financial_details: financial_detail, dealer: another_dealer)
    # end

    let(:params) do
      {
        id: app_sample.id,
        dealer_id: dealer.dealer_network.dealer_code
      }
    end
  end

  describe 'PATCH #stip_pay' do
    subject do
      patch :stip_pay, params: params
    end

    describe 'for dealer' do
      let(:params) do
        {
          id: create(:application, years_current_address: 10, homeowner: homeowner, dealer: dealer, address: address,
                                   financial_details: financial_detail, status: 'conditional_approval').id
        }
      end

      context 'with NO authentication header' do
        it { expect(subject).to have_http_status(:unauthorized) }
      end

      context 'with an authentication header' do
        before do
          request.headers.merge!(authenticated_header(homeowner))
          subject
        end

        context 'valid request' do
          it 'should respond with' do
            a_created_response
            expect(Application.last.no_stip_pay?).to be_truthy
          end
        end

        context 'application not found' do
          let(:params) do
            {
              id: 0
            }
          end

          it_behaves_like 'a not found response'
        end
      end
    end
  end

  describe 'PATCH #coapp_driver_license_uuid' do
    let!(:app) do
      create(:application, years_current_address: 10, homeowner: homeowner, dealer: dealer, address: address,
                           financial_details: financial_detail)
    end
    let(:params) do
      {
        id: app.id,
        coapplicant_driver_license_uuid: 'someuuid'
      }
    end

    subject do
      patch :coapp_driver_license_uuid, params: params
    end

    describe 'for member dealer' do
      before do
        request.headers.merge!(authenticated_header(dealer))
        allow(GetDriverLicenseJob).to receive(:perform_later).with(app, coapplicant: true)
        subject
      end

      it 'should respond with' do
        a_created_response
        app.reload
        expect(GetDriverLicenseJob).to have_received(:perform_later).with(app, coapplicant: true)
        expect(app.coapplicant_driver_license_uuid).to be_present
      end
    end
  end
end
=end
