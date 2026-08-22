# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

require "spec_helper"

describe MailingList do
  subject { mailing_lists(:info) }

  let(:layer_group) { subject.group.layer_group }

  before { is_expected.to be_valid }

  context "mail_name" do
    it "accepts empty value" do
      subject.mail_name = nil
      is_expected.to be_valid

      subject.mail_name = ""
      is_expected.to be_valid
    end

    it "accepts mail_name ending with the layer id" do
      subject.mail_name = "info.#{layer_group.id}"
      is_expected.to be_valid
    end

    it "does not accept mail_name without a valid suffix" do
      subject.mail_name = "info"
      is_expected.not_to be_valid

      subject.mail_name = "info#{layer_group.id}"
      is_expected.not_to be_valid
    end

    context "layer has abbreviations" do
      before { layer_group.update!(abbreviations: ["Adler", "adl"]) }

      it "accepts mail_name ending with any configured abbreviation" do
        subject.mail_name = "info.adler"
        is_expected.to be_valid

        subject.mail_name = "info.adl"
        is_expected.to be_valid
      end

      it "still accepts mail_name ending with the layer id" do
        subject.mail_name = "info.#{layer_group.id}"
        is_expected.to be_valid
      end

      it "does not accept mail_name with an unrelated suffix" do
        subject.mail_name = "info.other"
        is_expected.not_to be_valid
      end
    end

    it "allows to keep old mail_name even if invalid" do
      subject.mail_name = "invalid"
      subject.save(validate: false)

      subject.name = "Some change"
      is_expected.to be_valid
    end
  end
end
