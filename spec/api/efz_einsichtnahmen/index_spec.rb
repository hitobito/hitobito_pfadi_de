# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe "efz_einsichtnahmen#index", type: :request do
  let(:member) { people(:member) }
  let(:einsichtnehmer) { people(:admin) }
  let!(:efz) { Fabricate(:efz_einsichtnahme, person: member, einsichtnehmer: einsichtnehmer) }

  it_behaves_like "jsonapi authorized requests", required_scopes: ["efz_einsichtnahmen"], person: :admin do
    let(:service_token) { service_tokens(:efz_einsichtnahmen_token) }
    let(:params) { {} }

    subject(:make_request) do
      jsonapi_get "/api/efz_einsichtnahmen", params: params
    end

    describe "basic fetch" do
      it "works" do
        make_request
        expect(response.status).to eq(200), response.body
        expect(d.map(&:jsonapi_type).uniq).to match_array(["efz_einsichtnahmen"])
        expect(d.map(&:id)).to include(efz.id)
      end

      describe "sideloading" do
        before do
          params[:include] = "person,einsichtnehmer"
        end

        it "does not include person and einsichtnehmer with people scope on token" do
          params[:include] = "person,einsichtnehmer"
          make_request
          expect(response.status).to eq(200), response.body

          expect(d[0].sideload(:person)).to be_nil
          expect(d[0].sideload(:einsichtnehmer)).to be_nil
        end

        it "does include person but misses einsichtnehmer with people scope but token on adler" do
          service_token.update!(people: true)
          make_request
          expect(response.status).to eq(200), response.body
          expect(d[0].sideload(:person).id).to eq member.id
          expect(d[0].sideload(:einsichtnehmer)).to be_nil
        end

        it "does include person and einsichtnehmer with people scope and token scoped to root" do
          service_token.update!(people: true, layer: groups(:root))
          make_request
          expect(response.status).to eq(200), response.body
          expect(d[0].sideload(:person).id).to eq member.id
          expect(d[0].sideload(:einsichtnehmer).id).to eq einsichtnehmer.id
        end
      end
    end
  end
end
