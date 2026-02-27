# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "fee_rates#show", type: :request do
  it_behaves_like "jsonapi authorized requests", required_flags: ["fee_kinds"], person: nil do
    let(:service_token) { service_tokens(:fee_kind_bawue_token) }
    let(:params) { {} }

    let(:fee_rate) { fee_rates(:jahresbeitragssatz) }

    subject(:make_request) do
      jsonapi_get "/api/fee_rates/#{fee_rate.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(FeeRateResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("fee_rates")
        expect(d.id).to eq(fee_rate.id)
      end
    end
  end
end
