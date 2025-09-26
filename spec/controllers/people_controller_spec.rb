# frozen_string_literal: true

#  Copyright (c) 2025, BDP and DPSG. This file is part of
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
        exit_date: "01.01.2020",
        consent_data_retention: true,
        bank_account_owner: "John Doe",
        iban: "DE00 0000 0000 0000 0000 0",
        bic: "ASDF",
        bank_name: "Finanzinstitut",
        payment_method: "debit"
      }}
      expect(assigns(:person).pronoun).to eq("sie")
      expect(assigns(:person).exit_date).to eq(Date.parse("01.01.2020"))
      expect(assigns(:person).consent_data_retention).to be true
      expect(assigns(:person).bank_account_owner).to eq("John Doe")
      expect(assigns(:person).iban).to eq("DE00 0000 0000 0000 0000 0")
      expect(assigns(:person).bic).to eq("ASDF")
      expect(assigns(:person).bank_name).to eq("Finanzinstitut")
      expect(assigns(:person).payment_method).to eq("debit")
    end
  end

  describe "GET #show" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before do
      leader.update(pronoun: "sieoderer", exit_date: "01.01.2020")
    end

    it "displays some of the pfadi_de fields" do
      get :show, params: {group_id: group, id: leader.id}

      expect(dom).to have_text "sieoderer"
      expect(dom).to have_text "01.01.2020"
    end
  end
end
