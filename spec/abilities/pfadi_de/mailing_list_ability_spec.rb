# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe MailingListAbility do
  let(:user) { role.person }

  subject { Ability.new(user.reload) }

  context :layer_and_below_full do
    let(:role) do
      Fabricate(Group::Landesverband::Landesmitgliederverwaltung.name.to_sym,
        group: groups(:baden_wuerttemberg))
    end
    let(:list) { Fabricate(:mailing_list, group: groups(:adler)) }

    it "may show mailing list of a Stamm below" do
      is_expected.to be_able_to(:show, list)
    end

    it "may index subscriptions of a Stamm below" do
      is_expected.to be_able_to(:index_subscriptions, list)
    end

    it "may export subscriptions of a Stamm below" do
      is_expected.to be_able_to(:export_subscriptions, list)
    end

    it "may create, update and destroy mailing lists of a Stamm below" do
      is_expected.to be_able_to(:create, list)
      is_expected.to be_able_to(:update, list)
      is_expected.to be_able_to(:destroy, list)
    end

    it "may create subscriptions (Abos) of a Stamm below" do
      is_expected.to be_able_to(:create, list.subscriptions.new)
    end
  end

  context :layer_and_below_read do
    let(:role) do
      Fabricate(Group::Landesverband::ErfassungFuehrungszeugnis.name.to_sym,
        group: groups(:baden_wuerttemberg))
    end
    let(:list) { Fabricate(:mailing_list, group: groups(:adler)) }

    it "may show mailing list of a Stamm below" do
      is_expected.to be_able_to(:show, list)
    end

    it "may index subscriptions of a Stamm below" do
      is_expected.to be_able_to(:index_subscriptions, list)
    end

    it "may export subscriptions of a Stamm below" do
      is_expected.to be_able_to(:export_subscriptions, list)
    end

    it "may not create, update or destroy mailing lists" do
      is_expected.not_to be_able_to(:create, list)
      is_expected.not_to be_able_to(:update, list)
      is_expected.not_to be_able_to(:destroy, list)
    end

    it "may not create subscriptions (Abos)" do
      is_expected.not_to be_able_to(:create, list.subscriptions.new)
    end
  end
end
