# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe PeopleController do
  let(:leader) { people(:stammesverwaltung) }
  let(:group) { groups(:adler) }

  before { sign_in(leader) }

  context "PUT update" do
    it "updates pfadi_de fields" do
      put :update, params: {group_id: group.id, id: leader.id, person: {
        pronoun: "sie",
        consent_data_retention: true,
        bank_account_owner: "John Doe",
        iban: "DE00 0000 0000 0000 0000 0",
        bic: "ASDF",
        bank_name: "Finanzinstitut"
      }}
      expect(assigns(:person).pronoun).to eq("sie")
      expect(assigns(:person).consent_data_retention).to be true
      expect(assigns(:person).bank_account_owner).to eq("John Doe")
      expect(assigns(:person).iban).to eq("DE00 0000 0000 0000 0000 0")
      expect(assigns(:person).bic).to eq("ASDF")
      expect(assigns(:person).bank_name).to eq("Finanzinstitut")
    end
  end

  describe "GET#show" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      leader.update(pronoun: "sieoderer")
      Group::Mitglieder::OrdentlicheMitgliedschaft.create!(
        person: leader,
        group: groups(:adler_mitglieder),
        start_on: "2019-01-01",
        end_on: "2020-01-01",
        fee_kind: fee_kinds(:baden_wuerttemberg_kind)
      )
    end

    it "displays some of the pfadi_de fields" do
      get :show, params: {group_id: group, id: leader.id}

      expect(dom).to have_text "sieoderer"
      expect(dom).to have_text "01.01.2020"
    end

    describe "eFZ Einsichtnahme Button" do
      it "does not render button if not permitted" do
        get :show, params: {group_id: group.id, id: leader.id}
        expect(dom).not_to have_link "Führungszeugnis erfassen"
      end

      it "does render button if permitted" do
        Fabricate(Group::Stamm::ErfassungFuehrungszeugnis.sti_name, group: groups(:adler), person: leader)
        get :show, params: {group_id: group.id, id: leader.id}
        expect(dom).to have_link "Führungszeugnis erfassen",
          href: new_group_person_efz_einsichtnahme_path(group, leader)
      end
    end

    describe "latest eFZ Einsichtnahme info" do
      let(:einsichtnehmer) { people(:stammesverwaltung) }
      let(:latest_efz_issued_on) { dom.find("dt.muted", text: "eFZ Ausstellungsdatum").send(:parent) }
      let(:latest_efz_einsicht_on) { dom.find("dt.muted", text: "eFZ Einsichtnahme").send(:parent) }

      it "shows nothing when not present" do
        get :show, params: {group_id: group.id, id: leader.id}
        expect { latest_efz_issued_on }.to raise_error(Capybara::ElementNotFound)
        expect { latest_efz_einsicht_on }.to raise_error(Capybara::ElementNotFound)
      end

      it "shows last_efz_issued_on as well as last einsichtnehmer" do
        Fabricate(:efz_einsichtnahme, einsichtnehmer:, person: leader, issued_on: "20.05.2026",
          einsicht_on: "29.05.2026")
        get :show, params: {group_id: group.id, id: leader.id}
        expect(latest_efz_issued_on).to have_text "20.05.2026"
        expect(latest_efz_einsicht_on).to have_text "29.05.2026"
        expect(latest_efz_einsicht_on).to have_link "Some Stammesverwalter", href: person_path(einsichtnehmer)
      end
    end

    describe "active SEPA mandate" do
      let(:label) { "Aktives SEPA-Mandat" }
      let(:value) { dom.find("dt", text: label).send(:parent) }

      it "is not shown when mandates are not enabled for the layer" do
        get :show, params: {group_id: group.id, id: leader.id}
        expect(dom).not_to have_text label
      end

      context "with mandates enabled for the layer" do
        before do
          group.update!(sepa_mandate_mode: "optional", sepa_glaeubiger_id: "DE98ZZZ09999999999")
        end

        it "shows no when the person has no active mandate" do
          get :show, params: {group_id: group.id, id: leader.id}
          expect(value).to have_text "Nein"
        end

        it "shows yes when the person has an active mandate" do
          Fabricate(:sepa_mandate, person: leader, group:)
          get :show, params: {group_id: group.id, id: leader.id}
          expect(value).to have_text "Ja"
        end
      end
    end
  end

  describe "GET#show with SEPA mandates tab" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it "shows the tab to people who may read the mandates" do
      get :show, params: {group_id: group.id, id: leader.id}
      expect(dom).to have_link "SEPA-Mandate", href: group_person_sepa_mandates_path(group, leader)
    end
  end
end
