# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "efz_einsichtnahmen#create", type: :request do
  let(:member) { people(:member) }
  let(:einsichtnehmer) { people(:admin) }

  it_behaves_like "jsonapi authorized requests", required_scopes: ["efz_einsichtnahmen"], person: nil do
    let(:service_token) { service_tokens(:efz_einsichtnahmen_token) }
    let(:payload) do
      {
        data: {
          type: "efz_einsichtnahmen",
          attributes: {
            person_id: member.id,
            einsichtnehmer_id: einsichtnehmer.id,
            einsicht_on: "2026-01-01",
            issued_on: "2026-01-01"
          }
        }
      }
    end

    subject(:make_request) do
      jsonapi_post "/api/efz_einsichtnahmen", payload
    end

    describe "basic create" do
      it "creates the resource" do
        expect {
          make_request
          expect(response.status).to eq(201), response.body
        }.to change { EfzEinsichtnahme.count }.by(1)
      end
    end
  end
end
