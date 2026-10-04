# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Person::SepaMandatesController do
  render_views

  let(:dom) { Capybara::Node::Simple.new(response.body) }
  let(:member) { people(:member) }
  let(:group) { groups(:pfadfinder) }
  let(:creditor) { groups(:adler) }
  let(:treasurer) { Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group: creditor).person }
  let(:params) { {group_id: group.id, person_id: member.id} }

  before do
    creditor.update!(sepa_mandate_mode: "optional", sepa_glaeubiger_id: "DE98ZZZ09999999999")
    member.update!(iban: "DE02120300000000202051")
  end

  describe "GET #index" do
    let!(:mandate) { Fabricate(:sepa_mandate, person: member, group: creditor) }

    it "lists the mandates with add and revoke links for finance" do
      sign_in(treasurer)
      get :index, params: params

      expect(response).to be_successful
      expect(dom).to have_content(mandate.reference)
      expect(dom).to have_link("Erstellen")
      expect(dom).to have_link("Widerrufen")
      expect(dom).to have_css(".nav-sub a", text: "SEPA-Mandate")
      expect(dom).not_to have_content("Hitobito-Gruppierung")
    end

    it "shows the mandates to the payer without actions" do
      sign_in(member)
      get :index, params: params

      expect(dom).to have_content(mandate.reference)
      expect(dom).not_to have_link("Erstellen")
      expect(dom).not_to have_link("Widerrufen")
    end

    it "shows evidence and delete link to admins" do
      sign_in(people(:admin))
      get :index, params: params

      expect(dom).to have_content("Hitobito-Gruppierung")
      expect(dom).to have_css("a[data-method=delete]")
    end

    it "shows a hint when mandates are disabled for the layer" do
      creditor.update!(sepa_mandate_mode: "inactive")
      sign_in(treasurer)
      get :index, params: params

      expect(dom).to have_css(".alert-info", text: "nicht aktiviert")
      expect(dom).not_to have_link("Erstellen")
    end

    it "is denied without permission" do
      other = Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group: groups(:silberreiher))
      sign_in(other.person)

      expect { get :index, params: params }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "GET #new" do
    it "renders the form with the creditor" do
      sign_in(treasurer)
      get :new, params: params

      expect(dom).to have_content(creditor.to_s)
      expect(dom).to have_content("DE98ZZZ09999999999")
      expect(dom).to have_field("sepa_mandate_confirmation")
    end
  end

  describe "POST #create" do
    let(:mandate_params) do
      {issued_at: "01.09.2026", valid_from: "01.10.2026", confirmation: "1"}
    end

    it "creates the mandate for the layer of the group" do
      sign_in(treasurer)

      expect {
        post :create, params: params.merge(sepa_mandate: mandate_params)
      }.to change { member.sepa_mandates.count }.by(1)

      mandate = member.sepa_mandates.last
      expect(mandate.group).to eq creditor
      expect(mandate.creator).to eq treasurer
      expect(mandate.evidence).to eq "Hitobito-Gruppierung"
      expect(mandate.issued_at.to_date).to eq Date.new(2026, 9, 1)
      expect(response).to redirect_to(group_person_sepa_mandates_path(group, member))
    end

    it "ignores a manual reference" do
      sign_in(treasurer)
      post :create, params: params.merge(sepa_mandate: mandate_params.merge(reference: "MANUAL"))

      expect(member.sepa_mandates.last.reference).not_to eq "MANUAL"
    end

    it "requires the confirmation" do
      sign_in(treasurer)

      expect {
        post :create, params: params.merge(sepa_mandate: mandate_params.merge(confirmation: "0"))
      }.not_to change { SepaMandate.count }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "is denied for layer_and_below_full" do
      sign_in(people(:stammesverwaltung))

      expect {
        post :create, params: params.merge(sepa_mandate: mandate_params)
      }.to raise_error(CanCan::AccessDenied)
    end
  end

  describe "PATCH #revoke" do
    let!(:mandate) { Fabricate(:sepa_mandate, person: member, group: creditor) }

    it "revokes the mandate" do
      sign_in(people(:stammesverwaltung))
      patch :revoke, params: params.merge(id: mandate.id)

      expect(mandate.reload).not_to be_active
      expect(mandate.revoker).to eq people(:stammesverwaltung)
      expect(response).to redirect_to(group_person_sepa_mandates_path(group, member))
    end

    it "is denied for the payer" do
      sign_in(member)

      expect { patch :revoke, params: params.merge(id: mandate.id) }
        .to raise_error(CanCan::AccessDenied)
    end
  end

  describe "DELETE #destroy" do
    let!(:mandate) { Fabricate(:sepa_mandate, person: member, group: creditor) }

    it "is allowed for admins" do
      sign_in(people(:admin))

      expect { delete :destroy, params: params.merge(id: mandate.id) }
        .to change { SepaMandate.count }.by(-1)
    end

    it "is denied for finance" do
      sign_in(treasurer)

      expect { delete :destroy, params: params.merge(id: mandate.id) }
        .to raise_error(CanCan::AccessDenied)
    end
  end
end
