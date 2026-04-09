# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe Wizards::RegisterNewUserWizard do
  let(:params) { {} }
  let(:role_type) { Group::Mitglieder::OrdentlicheMitgliedschaft }
  let(:group) { groups(:adler_mitglieder) }
  let!(:fee_kind) do
    Fabricate(
      :fee_kind,
      name: "Test Fee Kind",
      layer: groups(:adler),
      parent: fee_kinds(:baden_wuerttemberg_kind)
    )
  end

  subject(:wizard) do
    described_class.new(group: group, **params).tap { |w| w.step_at(0) }
  end

  subject(:new_user_form) { wizard.new_user_form }

  context "with role that has fee_kind" do
    before { group.update!(self_registration_role_type: role_type) }

    describe "#person_attributes" do
      it "excludes fee_kind_id from person attributes" do
        params[:new_user_form] = {
          first_name: "test",
          last_name: "user",
          fee_kind_id: fee_kind.id
        }

        person_attrs = wizard.send(:person_attributes)
        expect(person_attrs).not_to have_key("fee_kind_id")
        expect(person_attrs).to include("first_name" => "test", "last_name" => "user")
      end
    end

    describe "#build_role" do
      it "assigns fee_kind_id to the created role" do
        params[:new_user_form] = {
          first_name: "test",
          last_name: "user",
          fee_kind_id: fee_kind.id
        }

        expect { wizard.save! }.to change { Person.count }.by(1)
          .and change { group.roles.where(type: role_type.sti_name).count }.by(1)

        person = Person.find_by(first_name: "test")
        role = person.roles.last

        expect(role.fee_kind_id).to eq(fee_kind.id)
        expect(role.fee_kind).to eq(fee_kind)
      end

      it "creates role without fee_kind_id if not provided" do
        params[:new_user_form] = {
          first_name: "test",
          last_name: "user"
        }

        expect { wizard.save! }.to change { Person.count }.by(1)
          .and change { group.roles.where(type: role_type.sti_name).count }.by(1)

        person = Person.find_by(first_name: "test")
        role = person.roles.last

        # Should get default fee_kind from ensure_fee_kind callback
        expect(role.fee_kind).to be_present
      end
    end
  end
end
