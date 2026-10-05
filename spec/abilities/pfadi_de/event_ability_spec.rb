# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe EventAbility do
  subject { ability }

  let(:ability) { Ability.new(role.person.reload) }

  context :admin do
    let(:role) { roles(:admin) }
    let(:event) { events(:top_event) }

    it "may not create tags (only via the /tags admin screen)" do
      is_expected.not_to be_able_to(:create_tags, event)
    end

    it "may assign tags" do
      is_expected.to be_able_to(:assign_tags, event)
    end
  end

  context :layer_and_below_full do
    let(:role) { roles(:stammesverwaltung) }
    let(:event) { Fabricate(:event, groups: [groups(:adler)], globally_visible: false) }

    it "may not create tags" do
      is_expected.not_to be_able_to(:create_tags, event)
    end

    it "may still assign existing tags" do
      is_expected.to be_able_to(:assign_tags, event)
    end
  end
end
