# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe RoleResource, type: :resource do
  let(:person) { people(:stammesverwaltung) }
  let(:new_person) { Fabricate(:person) }
  let(:context) { double(current_ability: ability, current_scopes:, action_name: "create") }

  describe "creating" do
    let(:payload) do
      {
        data: {
          type: "roles",
          attributes: {
            group_id: groups(:adler_mitglieder).id,
            person_id: new_person.id,
            type: Group::Mitglieder::OrdentlicheMitgliedschaft.sti_name,
            fee_kind_id: fee_kinds(:baden_wuerttemberg_kind).id
          }
        }
      }
    end

    let(:instance) { RoleResource.build(payload) }

    it "may assign unrestricted fee kind" do
      expect { instance.save }.to change { new_person.roles.count }.by(1)
    end

    context "with restricted fee kind" do
      before { fee_kinds(:top_fee_kind).update!(restricted: true) }

      it "may not assign it without assign_restricted_fee_kinds" do
        expect { instance.save }.to raise_error(CanCan::AccessDenied)
      end

      context "as admin" do
        let(:person) { people(:admin) }

        it "may assign it" do
          expect { instance.save }.to change { new_person.roles.count }.by(1)
        end
      end
    end
  end
end
