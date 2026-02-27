# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "fee_kinds#index", type: :request do
  it_behaves_like "jsonapi authorized requests", required_flags: ["fee_kinds"], person: nil do
    let(:service_token) { service_tokens(:fee_kind_bawue_token) }
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/fee_kinds", params: params
    end

    describe "basic fetch" do
      # let!(:fee_kind_root) { fee_kinds(:top_fee_kind) }
      let(:fee_kind_bw) { fee_kinds(:baden_wuerttemberg_kind) }

      it "works" do
        expect(FeeKindResource).to receive(:all).and_call_original
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["fee_kinds"])
        expect(d.map(&:id)).to match_array([fee_kind_bw.id])
      end
    end
  end
end
