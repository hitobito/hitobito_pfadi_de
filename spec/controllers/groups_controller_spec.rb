# frozen_string_literal: true

#  Copyright (c) 2025, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe GroupsController do
  let(:leader) { people(:stammesverwaltung) }
  let(:group) { groups(:pfadfinder) }

  before { sign_in(leader) }

  context "PUT update" do
    it "updates bank account fields" do
      put :update, params: {id: group.id, group: {
        bank_account_owner: "John Doe",
        iban: "DE00 0000 0000 0000 0000 0",
        bic: "ASDF",
        bank_name: "Finanzinstitut"
      }}
      expect(assigns(:group).bank_account_owner).to eq("John Doe")
      expect(assigns(:group).iban).to eq("DE00 0000 0000 0000 0000 0")
      expect(assigns(:group).bic).to eq("ASDF")
      expect(assigns(:group).bank_name).to eq("Finanzinstitut")
    end
  end
end
