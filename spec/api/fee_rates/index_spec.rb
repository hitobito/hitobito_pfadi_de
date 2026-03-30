# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "fee_rates#index", type: :request do
  it_behaves_like "jsonapi authorized requests", required_scopes: ["fee_kinds"], person: nil do
    let(:service_token) { service_tokens(:fee_kind_bawue_token) }
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/fee_rates", params: params
    end

    describe "basic fetch" do
      let(:fee_rate_jahr) { fee_rates(:jahresbeitragssatz) }
      let(:fee_rate_halbjahr) { fee_rates(:halbjahresbeitragssatz) }
      let(:fee_rate_kinder) { fee_rates(:kleinkinderbeitragssatz) }

      it "works" do
        expect(FeeRateResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["fee_rates"])
        expect(d.map(&:id)).to match_array [
          fee_rate_jahr,
          fee_rate_halbjahr,
          fee_rate_kinder
        ].map(&:id)
      end
    end
  end
end
