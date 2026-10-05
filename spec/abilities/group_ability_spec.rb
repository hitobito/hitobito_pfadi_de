# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe GroupAbility do
  let(:user) { role.person }
  let(:group) { role.group }

  subject { Ability.new(user.reload) }

  context :layer_and_below_full do
    let(:role) { Fabricate(Group::Bundesvorstand::Bundesvorsitz.name.to_sym, group: groups(:bundesvorstand)) }

    it "may not index service tokens in group" do
      is_expected.not_to be_able_to(:index_service_tokens, group)
    end
  end

  context :layer_full do
    let(:role) { Fabricate(Group::Bundesvorstand::Bundesschatzmeister.name.to_sym, group: groups(:bundesvorstand)) }

    it "may not index service tokens in group" do
      is_expected.not_to be_able_to(:index_service_tokens, group)
    end
  end

  context :admin do
    let(:admin_group) { Fabricate(Group::Bundesebene.name) }
    let(:role) { Fabricate(Group::Bundesebene::MVAdmin.name.to_sym, group: admin_group) }

    it "may index service tokens in group" do
      is_expected.to be_able_to(:index_service_tokens, admin_group)
    end

    it "may index service tokens in group on another layer" do
      is_expected.to be_able_to(:index_service_tokens, groups(:baden_wuerttemberg))
    end
  end
end
