# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe PersonReadables do
  let(:group) { groups(:pfadfinder) }

  # Uses a different role class than the plain :member fixture (also a Mitglied in the
  # same group) so that stubbing permissions on the acting user's role class does not
  # incidentally grant the same permission to the other person used in these examples.
  let(:role) do
    Fabricate(Group::StammGruppePfadfinder::Hilfsleitung.name.to_sym, group: group)
  end
  let(:user) { role.person.reload }
  let(:other) { roles(:member).person }

  before { Group::StammGruppePfadfinder::Hilfsleitung.permissions = [:group_read_contact_data] }

  after { Group::StammGruppePfadfinder::Hilfsleitung.permissions = [:group_read] }

  describe "listing the group" do
    subject { Person.accessible_by(PersonReadables.new(user, group)) }

    it "includes fellow group members" do
      is_expected.to include(other)
    end
  end

  describe "the global list" do
    subject { Person.accessible_by(PersonReadables.new(user)) }

    it "includes fellow group members" do
      is_expected.to include(other)
    end

    it "does not include people outside the group" do
      is_expected.not_to include(people(:admin))
    end
  end

  describe PersonFullReadables do
    subject { Person.accessible_by(PersonFullReadables.new(user)) }

    it "does not include fellow group members" do
      is_expected.not_to include(other)
    end
  end

  describe PersonDetailsReadables do
    subject { Person.accessible_by(PersonDetailsReadables.new(user)) }

    it "does not include fellow group members" do
      is_expected.not_to include(other)
    end
  end
end
