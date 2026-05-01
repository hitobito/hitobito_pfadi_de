#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe FeeRatesController do
  render_views
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let(:person) { Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group:).person }

  let(:group) do
    Fabricate(Group::Stamm.sti_name, name: "Falken", parent: groups(:baden_wuerttemberg))
  end

  let(:fee_kind) do
    Fabricate(:fee_kind, layer: group, parent: fee_kinds(:baden_wuerttemberg_kind))
  end

  let!(:fee_rate) do
    Fabricate(:fee_rate, fee_kind: fee_kind)
  end

  before do
    sign_in(person)
  end

  it "GET#index does list fee rates" do
    get :index, params: {group_id: group.id, fee_kind_id: fee_kind.id}
    expect(assigns(:fee_rates)).to include(fee_rate)
  end

  it "GET#index shows max_age and max_member_months" do
    get :index, params: {group_id: group.id, fee_kind_id: fee_kind.id}
    expect(dom).to have_text "maximales Alter des Mitglieds"
    expect(dom).to have_text "max. Mitgliedsdauer in Monaten"
  end

  it "GET#show shows max_age and max_member_months" do
    get :show, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
    expect(dom).to have_text "maximales Alter des Mitglieds"
    expect(dom).to have_text "max. Mitgliedsdauer in Monaten"
  end

  it "GET#new shows max_age and max_member_months" do
    get :new, params: {group_id: group.id, fee_kind_id: fee_kind.id}
    expect(dom).to have_text "maximales Alter des Mitglieds"
    expect(dom).to have_text "max. Mitgliedsdauer in Monaten"
  end

  it "POST#create sets max_age and max_member_months" do
    expect do
      post :create, params: {
        group_id: group.id,
        fee_kind_id: fee_kind.id,
        fee_rate: {
          name: "Test",
          amount: 10,
          valid_from: Time.zone.today,
          max_age: 10,
          max_member_months: 6
        }
      }

      expect(assigns(:fee_rate)).to be_valid
      expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich erstellt."
    end.to change { FeeRate.count }.by(1)
    expect(FeeRate.last.max_age).to eq 10
    expect(FeeRate.last.max_member_months).to eq 6
  end

  it "GET#edit shows max_age and max_member_months" do
    get :edit, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
    expect(dom).to have_text "maximales Alter des Mitglieds"
    expect(dom).to have_text "max. Mitgliedsdauer in Monaten"
  end

  it "PUT#update sets max_age and max_member_months" do
    post :update, params: {
      group_id: group.id,
      fee_kind_id: fee_kind.id,
      id: fee_rate.id,
      fee_rate: {
        name: "Test",
        amount: 10,
        valid_from: Time.zone.today,
        max_age: 10,
        max_member_months: 6
      }
    }

    expect(assigns(:fee_rate)).to be_valid
    expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich aktualisiert."
    expect(assigns(:fee_rate).max_age).to eq 10
    expect(assigns(:fee_rate).max_member_months).to eq 6
  end

  context "with relative fee rates enabled (DPSG)" do
    before do
      allow_any_instance_of(FeatureGate).to receive(:enabled?).and_call_original
      allow_any_instance_of(FeatureGate).to receive(:enabled?)
        .with("membership_fees.relative_fee_rates").and_return(true)
    end

    it "GET#index does not show max_member_months" do
      get :index, params: {group_id: group.id, fee_kind_id: fee_kind.id}
      expect(dom).to have_text "maximales Alter des Mitglieds"
      expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
    end

    it "GET#show does not show max_member_months" do
      get :show, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
      expect(dom).to have_text "maximales Alter des Mitglieds"
      expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
    end

    it "GET#new does not show max_member_months" do
      get :new, params: {group_id: group.id, fee_kind_id: fee_kind.id}
      expect(dom).to have_text "maximales Alter des Mitglieds"
      expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
    end

    it "POST#create does not set max_member_months" do
      expect do
        post :create, params: {
          group_id: group.id,
          fee_kind_id: fee_kind.id,
          fee_rate: {
            name: "Test",
            amount: 10,
            valid_from: Time.zone.today,
            max_age: 10,
            max_member_months: 6
          }
        }

        expect(assigns(:fee_rate)).to be_valid
        expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich erstellt."
      end.to change { FeeRate.count }.by(1)
      expect(FeeRate.last.max_age).to eq 10
      expect(FeeRate.last.max_member_months).to be_nil
    end

    it "GET#edit does not show max_member_months" do
      get :edit, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
      expect(dom).to have_text "maximales Alter des Mitglieds"
      expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
    end

    it "PUT#update does not set max_member_months" do
      post :update, params: {
        group_id: group.id,
        fee_kind_id: fee_kind.id,
        id: fee_rate.id,
        fee_rate: {
          name: "Test",
          amount: 10,
          valid_from: Time.zone.today,
          max_age: 10,
          max_member_months: 6
        }
      }

      expect(assigns(:fee_rate)).to be_valid
      expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich aktualisiert."
      expect(assigns(:fee_rate).max_age).to eq 10
      expect(assigns(:fee_rate).max_member_months).to be_nil
    end

    context "on Landesverband" do
      let(:group) { groups(:baden_wuerttemberg) }
      let(:fee_kind) { fee_kinds(:baden_wuerttemberg_kind) }
      let(:person) {
        Fabricate(Group::Landesvorstand::Landesschatzmeister.sti_name,
          group: groups(:landesvorstand_bw)).person
      }

      it "GET#index does not show max_age and max_member_months" do
        get :index, params: {group_id: group.id, fee_kind_id: fee_kind.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "GET#show does not show max_age and max_member_months" do
        get :show, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "GET#new does not show max_age and max_member_months" do
        get :new, params: {group_id: group.id, fee_kind_id: fee_kind.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "POST#create does not set max_age nor max_member_months" do
        expect do
          post :create, params: {
            group_id: group.id,
            fee_kind_id: fee_kind.id,
            fee_rate: {
              name: "Test",
              amount: 10,
              valid_from: Time.zone.today,
              max_age: 10,
              max_member_months: 6
            }
          }

          expect(assigns(:fee_rate)).to be_valid
          expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich erstellt."
        end.to change { FeeRate.count }.by(1)
        expect(FeeRate.last.max_age).to be_nil
        expect(FeeRate.last.max_member_months).to be_nil
      end

      it "GET#edit does not show max_age and max_member_months" do
        get :edit, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "PUT#update does not set max_age nor max_member_months" do
        post :update, params: {
          group_id: group.id,
          fee_kind_id: fee_kind.id,
          id: fee_rate.id,
          fee_rate: {
            name: "Test",
            amount: 10,
            valid_from: Time.zone.today,
            max_age: 10,
            max_member_months: 6
          }
        }

        expect(assigns(:fee_rate)).to be_valid
        expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich aktualisiert."
        expect(assigns(:fee_rate).max_age).to be_nil
        expect(assigns(:fee_rate).max_member_months).to be_nil
      end
    end

    context "on Bundesebene" do
      let(:group) { groups(:root) }
      let(:fee_kind) { fee_kinds(:top_fee_kind) }
      let(:person) {
        Fabricate(Group::Bundesvorstand::Bundesschatzmeister.sti_name,
          group: groups(:bundesvorstand)).person
      }

      it "GET#index does not show max_age and max_member_months" do
        get :index, params: {group_id: group.id, fee_kind_id: fee_kind.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "GET#show does not show max_age and max_member_months" do
        get :show, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "GET#new does not show max_age and max_member_months" do
        get :new, params: {group_id: group.id, fee_kind_id: fee_kind.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "POST#create does not set max_age nor max_member_months" do
        expect do
          post :create, params: {
            group_id: group.id,
            fee_kind_id: fee_kind.id,
            fee_rate: {
              name: "Test",
              amount: 10,
              valid_from: Time.zone.today,
              max_age: 10,
              max_member_months: 6
            }
          }

          expect(assigns(:fee_rate)).to be_valid
          expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich erstellt."
        end.to change { FeeRate.count }.by(1)
        expect(FeeRate.last.max_age).to be_nil
        expect(FeeRate.last.max_member_months).to be_nil
      end

      it "GET#edit does not show max_age and max_member_months" do
        get :edit, params: {group_id: group.id, fee_kind_id: fee_kind.id, id: fee_rate.id}
        expect(dom).not_to have_text "maximales Alter des Mitglieds"
        expect(dom).not_to have_text "max. Mitgliedsdauer in Monaten"
      end

      it "PUT#update does not set max_age nor max_member_months" do
        post :update, params: {
          group_id: group.id,
          fee_kind_id: fee_kind.id,
          id: fee_rate.id,
          fee_rate: {
            name: "Test",
            amount: 10,
            valid_from: Time.zone.today,
            max_age: 10,
            max_member_months: 6
          }
        }

        expect(assigns(:fee_rate)).to be_valid
        expect(flash[:notice]).to eq "Beitragssatz <i>Test</i> wurde erfolgreich aktualisiert."
        expect(assigns(:fee_rate).max_age).to be_nil
        expect(assigns(:fee_rate).max_member_months).to be_nil
      end
    end
  end
end
