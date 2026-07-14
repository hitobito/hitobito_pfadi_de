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
end
