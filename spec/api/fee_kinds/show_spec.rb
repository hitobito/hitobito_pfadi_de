# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "fee_kinds#show", type: :request do
  it_behaves_like "jsonapi authorized requests", person: nil do
    let(:token) { service_tokens(:permitted_root_token).token }
    let(:params) { {} }

    let(:fee_kind) { fee_kinds(:top_fee_kind) }

    subject(:make_request) do
      jsonapi_get "/api/fee_kinds/#{fee_kind.id}", params: params
    end

    describe "basic fetch" do
      it "works" do
        expect(FeeKindResource).to receive(:find).and_call_original
        make_request
        expect(response.status).to eq(200)
        expect(d.jsonapi_type).to eq("fee_kinds")
        expect(d.id).to eq(fee_kind.id)
      end
    end
  end
end
