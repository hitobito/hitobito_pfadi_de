# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "spec_helper"

describe Person do
  describe "PaperTrail", versioning: true do
    let(:person) { people(:member) }

    it "ignores last_entry_date_with_fee_kind changes" do
      expect do
        person.update!(last_entry_date_with_fee_kind: Date.current)
      end.not_to change { person.versions.count }
    end

    it "ignores should_recalculate_last_entry_date_with_fee_kind changes" do
      expect do
        person.update!(should_recalculate_last_entry_date_with_fee_kind: true)
      end.not_to change { person.versions.count }
    end

    it "tracks other attribute changes normally" do
      expect do
        person.update!(first_name: "NewName")
      end.to change { person.versions.count }

      expect(person.versions.last.changeset).to have_key("first_name")
    end
  end
end
