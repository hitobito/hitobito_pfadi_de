# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Roles::FeeKindChangesController do
  let(:leader) { people(:admin) }
  let(:group) { groups(:root) }
  let(:person) { role.person }
  let(:role) { roles(:paying_member) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  let!(:youth_kind) {
    Fabricate(:fee_kind, name: "BaWü Jugend", layer: groups(:baden_wuerttemberg),
      parent: fee_kinds(:top_fee_kind))
  }

  before { sign_in(people(:admin)) }

  describe "GET#new" do
    it "raises if not authorized" do
      sign_in(Fabricate(:person))
      expect do
        get :new, params: {role_id: role.id}
      end.to raise_error(CanCan::AccessDenied)
    end

    it "redirects if not applicable" do
      get :new, params: {role_id: roles(:member).id}
      expect(response).to redirect_to(person_path(role.person))
      expect(flash[:alert]).to eq "Rolle hat keine Beitragsart."
    end

    context "with view" do
      render_views

      it "renders role info and form" do
        get :new, params: {role_id: role.id}
        expect(response).to be_successful
        expect(dom).to have_css "h1", text: "Beitragsart ändern"
        expect(dom).to have_css "dd", text: "My Member"
        expect(dom).to have_css "dd", text: "Group::Mitglieder::OrdentlicheMitgliedschaft"
        expect(dom).to have_css "dd", text: "BaWü Kind"
        expect(dom).to have_css "dd", text: "01.01.2026"
        expect(dom).to have_select "Beitragsart", options: ["", "BaWü Kind", "BaWü Jugend"]
        expect(dom).to have_field "Ab"
      end
    end
  end

  describe "POST#create" do
    let(:model_params) do
      {
        fee_kind_id: youth_kind.id,
        start_on: Time.zone.today
      }
    end

    it "changes fee kind and redirects" do
      expect do
        post :create, params: {role_id: role.id, role_fee_kind_change: model_params}
        expect(response).to redirect_to(person_path(role.person, format: :html))
        expect(flash[:notice]).to eq "Die Beitragsart der Rolle wurde auf BaWü Kind geändert."
      end.to change { role.reload.end_on }.to(Time.zone.yesterday)
    end

    it "has information about future fee kind change" do
      model_params[:start_on] = "2026-06-30"
      post :create, params: {role_id: role.id, role_fee_kind_change: model_params}
      expect(flash[:notice]).to eq "Die Beitragsart der Rolle wird am 30.06.2026 auf BaWü Kind geändert."
    end

    it "raises if not authorized" do
      sign_in(Fabricate(:person))
      expect do
        post :create, params: {role_id: role.id, role_fee_kind_change: model_params}
      end.to raise_error(CanCan::AccessDenied)
    end

    context "with view" do
      render_views
      it "re-renders form if model is invalid" do
        post :create,
          params: {role_id: role.id, role_fee_kind_change: model_params.except(:start_on)}
        expect(dom).to have_css ".alert-danger", text: "Ab muss ausgefüllt werden"
        expect(dom).to have_field "Ab"
        expect(dom).to have_select "Beitragsart", options: ["", "BaWü Kind", "BaWü Jugend"]
      end
    end
  end
end
