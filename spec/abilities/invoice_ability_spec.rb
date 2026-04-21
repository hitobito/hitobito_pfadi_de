#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceAbility do
  subject { ability }

  let(:ability) { Ability.new(person) }
  let(:person) { Fabricate(:person) }
  let(:group) { Fabricate(Group::Bundesgeschaeftsstelle.sti_name, parent: groups(:root)) }
  let(:fee_kind) { FeeKind.build(layer: group) }

  before do
    Fabricate(role_class.sti_name, person:, group:)
  end

  context "without finance permission" do
    let(:role_class) { Group::Bundesgeschaeftsstelle::HauptamtlichSachbearbeitung }

    [:index, :show, :new, :create, :edit, :update].each do |action|
      it "can not #{action} fee kind" do
        is_expected.not_to be_able_to(action, fee_kind)
      end
    end
  end

  context "with finance permission" do
    let(:role_class) { Group::Bundesgeschaeftsstelle::Bundesgeschaeftsfuehrung }

    [:index, :show, :new, :create, :edit, :update].each do |action|
      it "can #{action} fee kind" do
        is_expected.to be_able_to(action, fee_kind)
      end
    end
  end
end
