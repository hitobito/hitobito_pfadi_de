# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "sepa_mandates#update", type: :request do
  let!(:mandate) { Fabricate(:sepa_mandate, person: people(:member), group: groups(:adler)) }

  it_behaves_like "jsonapi authorized requests", required_scopes: ["sepa_mandates"], person: nil do
    let(:service_token) { service_tokens(:sepa_mandates_token) }
    let(:payload) do
      {
        data: {
          id: mandate.id.to_s,
          type: "sepa_mandates",
          attributes: {revoked_at: "2026-09-01T10:00:00+02:00"}
        }
      }
    end

    subject(:make_request) do
      jsonapi_patch "/api/sepa_mandates/#{mandate.id}", payload
    end

    it "revokes the mandate" do
      make_request
      expect(response.status).to eq(200), response.body
      expect(mandate.reload).not_to be_active
    end
  end
end
