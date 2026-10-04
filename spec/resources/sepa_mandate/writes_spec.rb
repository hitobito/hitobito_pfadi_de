# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe SepaMandateResource, type: :resource do
  let(:member) { people(:member) }
  let(:group) { groups(:adler) }

  before do
    group.update!(sepa_mandate_mode: "optional", sepa_glaeubiger_id: "DE98ZZZ09999999999")
    member.update!(iban: "DE02120300000000202051")
  end

  describe "creating" do
    let(:attributes) do
      {
        person_id: member.id,
        group_id: group.id,
        issued_at: "2026-09-01T10:00:00+02:00",
        valid_from: "2026-10-01"
      }
    end
    let(:payload) { {data: {type: "sepa_mandates", attributes:}} }
    let(:instance) { SepaMandateResource.build(payload) }

    context "with finance on the creditor layer" do
      let(:role) { Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group:) }
      let(:ability) { Ability.new(role.person) }

      it "works" do
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { SepaMandate.count }.by(1)

        mandate = SepaMandate.last
        expect(mandate.person).to eq member
        expect(mandate.group).to eq group
        expect(mandate.creator).to eq role.person
        expect(mandate.valid_from).to eq Date.new(2026, 10, 1)
        expect(mandate.reference).to start_with("#{group.id}-#{member.id}-")
      end

      it "accepts a manual reference, evidence and mandate text version" do
        attributes.merge!(reference: "ALT-0815", evidence: "Papiermandat", mandate_text_version: 2)

        expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        expect(SepaMandate.last).to have_attributes(reference: "ALT-0815",
          evidence: "Papiermandat", mandate_text_version: 2)
      end

      it "validates the manual reference" do
        attributes[:reference] = "not allowed"

        expect(instance.save).to eq(false)
        expect(instance.errors[:reference]).to be_present
      end

      it "may not write revoked_at" do
        attributes[:revoked_at] = "2026-09-01T10:00:00+02:00"

        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end

      it "may not write the status" do
        attributes[:status] = "revoked"

        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    context "without person_id" do
      let(:ability) { Ability.new(people(:admin)) }

      before { attributes.delete(:person_id) }

      it "raises an invalid request error" do
        expect { instance.save }.to raise_error(Graphiti::Errors::InvalidRequest)
      end
    end

    context "not authorized" do
      let(:role) { Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group: groups(:silberreiher)) }
      let(:ability) { Ability.new(role.person) }

      it "raises AccessDenied" do
        expect { instance.save }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "service token" do
      let(:token) { service_tokens(:sepa_mandates_token) }
      let(:ability) { TokenAbility.new(token) }

      it "can create when token has the sepa_mandates scope" do
        expect {
          expect(instance.save).to eq(true), instance.errors.full_messages.to_sentence
        }.to change { SepaMandate.count }.by(1)
        expect(SepaMandate.last.creator).to be_nil
      end

      it "cannot create when token is missing the sepa_mandates scope" do
        token.update!(sepa_mandates: false)
        allow(Graphiti.context[:object]).to receive(:current_ability)
          .and_return(TokenAbility.new(token))

        expect { instance.save }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "revoking" do
    let!(:mandate) { Fabricate(:sepa_mandate, person: member, group:) }
    let(:attributes) { {revoked_at: "2026-09-01T10:00:00+02:00"} }
    let(:payload) { {id: mandate.id.to_s, data: {id: mandate.id.to_s, type: "sepa_mandates", attributes:}} }
    let(:instance) { SepaMandateResource.find(payload) }

    context "with finance on the creditor layer" do
      let(:role) { Fabricate(Group::Stamm::Stammesschatzmeister.sti_name, group:) }
      let(:ability) { Ability.new(role.person) }

      it "revokes the mandate" do
        expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence

        expect(mandate.reload).not_to be_active
        expect(mandate.revoked_at).to eq Time.zone.parse("2026-09-01T10:00:00+02:00")
        expect(mandate.revoker).to eq role.person
      end

      it "may not change other attributes" do
        attributes[:valid_from] = "2026-12-01"

        expect { instance.update_attributes }.to raise_error(Graphiti::Errors::InvalidRequest)
      end

      it "requires revoked_at" do
        attributes.delete(:revoked_at)

        expect { instance.update_attributes }.to raise_error(Graphiti::Errors::InvalidRequest)
      end

      it "may not revoke twice" do
        mandate.revoke!

        expect { instance.update_attributes }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "with read permission only" do
      let(:ability) { Ability.new(member) }

      it "raises AccessDenied" do
        expect { instance.update_attributes }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "service token" do
      let(:token) { service_tokens(:sepa_mandates_token) }
      let(:ability) { TokenAbility.new(token) }

      it "can revoke when token has the sepa_mandates scope" do
        expect(instance.update_attributes).to eq(true), instance.errors.full_messages.to_sentence
        expect(mandate.reload).not_to be_active
        expect(mandate.revoker).to be_nil
      end

      it "cannot revoke with a read only token" do
        token.update!(permission: "layer_and_below_read")
        allow(Graphiti.context[:object]).to receive(:current_ability)
          .and_return(TokenAbility.new(token))

        expect { instance.update_attributes }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
