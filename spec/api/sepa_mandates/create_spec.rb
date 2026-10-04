# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "sepa_mandates#create", type: :request do
  let(:member) { people(:member) }
  let(:group) { groups(:adler) }

  before do
    group.update!(sepa_mandate_mode: "optional", sepa_glaeubiger_id: "DE98ZZZ09999999999")
    member.update!(iban: "DE02120300000000202051")
  end

  it_behaves_like "jsonapi authorized requests", required_scopes: ["sepa_mandates"], person: nil do
    let(:service_token) { service_tokens(:sepa_mandates_token) }
    let(:payload) do
      {
        data: {
          type: "sepa_mandates",
          attributes: {
            person_id: member.id,
            group_id: group.id,
            issued_at: "2026-09-01T10:00:00+02:00",
            valid_from: "2026-10-01"
          }
        }
      }
    end

    subject(:make_request) do
      jsonapi_post "/api/sepa_mandates", payload
    end

    it "creates the mandate" do
      expect {
        make_request
        expect(response.status).to eq(201), response.body
      }.to change { SepaMandate.count }.by(1)
    end
  end
end
