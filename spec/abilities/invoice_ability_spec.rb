#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceAbility do
  subject { ability }

  let(:ability) { Ability.new(person) }
  let(:person) { people(:admin) }
  let(:group) { Fabricate(Group::Bundesgeschaeftsstelle.sti_name, parent: groups(:root)) }
  let(:fee_kind) { FeeKind.build(layer: group) }

  context "without finance permission" do
    [:index, :show, :new, :create, :edit, :update].each do |action|
      it "can not #{action} fee kind" do
        is_expected.not_to be_able_to(action, fee_kind)
      end
    end
  end

  context "with finance permission" do
    before do
      Fabricate(Group::Bundesgeschaeftsstelle::Bundesgeschaeftsfuehrung.sti_name, person:, group:)
    end

    [:index, :show, :new, :create, :edit, :update].each do |action|
      it "can #{action} fee kind" do
        is_expected.to be_able_to(action, fee_kind)
      end
    end
  end
end
