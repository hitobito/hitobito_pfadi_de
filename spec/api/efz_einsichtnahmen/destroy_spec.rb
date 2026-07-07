# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "efz_einsichtnahmen#destroy", type: :request do
  let(:member) { people(:member) }
  let(:einsichtnehmer) { people(:admin) }
  let!(:efz) { Fabricate(:efz_einsichtnahme, person: member, einsichtnehmer: einsichtnehmer) }

  it_behaves_like "jsonapi authorized requests", required_scopes: ["efz_einsichtnahmen"], person: nil do
    let(:service_token) { service_tokens(:efz_einsichtnahmen_token) }

    subject(:make_request) do
      jsonapi_delete "/api/efz_einsichtnahmen/#{efz.id}"
    end

    describe "basic destroy" do
      it "destroys the resource" do
        expect {
          make_request
          expect(response.status).to eq(200), response.body
        }.to change { EfzEinsichtnahme.count }.by(-1)
      end
    end
  end
end
