# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PersonAbility do
  let(:user) { role.person }

  subject { Ability.new(user.reload) }

  context "on herself" do
    let(:role) { roles(:member) }

    it "may show details" do
      is_expected.to be_able_to(:show_details, user)
    end

    it "may index messages" do
      is_expected.to be_able_to(:index_messages, user)
    end
  end

  context "on manageds" do
    let(:role) { roles(:member) }
    let!(:managed) do
      people(:bottom_leader).tap { |p| PeopleManager.create!(managed: p, manager: user) }
    end

    it "may show details" do
      is_expected.to be_able_to(:show_details, managed)
    end

    it "may index messages" do
      is_expected.to be_able_to(:index_messages, managed)
    end
  end

  context :admin do
    let(:role) { roles(:admin) }
    let(:other) { people(:member) }

    it "may index messages on arbitrary person" do
      is_expected.to be_able_to(:index_messages, other)
    end
  end

  context :layer_and_below_read do
    let(:role) { Fabricate(Group::Stamm::Stammesfuehrung.name.to_sym, group: groups(:adler)) }
    let(:other) { people(:member) }

    it "may not index messages on another person" do
      is_expected.not_to be_able_to(:index_messages, other)
    end

    it "may still view details of another person" do
      is_expected.to be_able_to(:show_details, other)
    end
  end

  context :layer_and_below_full do
    let(:role) { roles(:stammesverwaltung) }
    let(:other) { people(:member) }

    it "may not index messages on another person" do
      is_expected.not_to be_able_to(:index_messages, other)
    end

    it "may still view details of another person" do
      is_expected.to be_able_to(:show_details, other)
    end
  end

  context :group_read_contact_data do
    # Uses a different role class than the plain :member fixture (also a Mitglied in the
    # same group) so that stubbing permissions on the acting user's role class does not
    # incidentally grant the same permission to the other person used in these examples.
    let(:role) do
      Fabricate(Group::StammGruppePfadfinder::Hilfsleitung.name.to_sym, group: groups(:pfadfinder))
    end
    let(:other) { roles(:member).person }

    before { Group::StammGruppePfadfinder::Hilfsleitung.permissions = [:group_read_contact_data] }

    after { Group::StammGruppePfadfinder::Hilfsleitung.permissions = [:group_read] }

    it "may show contact data of a fellow group member" do
      is_expected.to be_able_to(:show, other)
    end

    it "may not show_full or show_details a fellow group member" do
      is_expected.not_to be_able_to(:show_full, other)
      is_expected.not_to be_able_to(:show_details, other)
    end

    it "may not show people outside the group" do
      is_expected.not_to be_able_to(:show, people(:admin))
    end

    it "does not make the holder visible to the fellow group member in return" do
      other_ability = Ability.new(other.reload)
      expect(other_ability).not_to be_able_to(:show, user)
    end
  end
end
