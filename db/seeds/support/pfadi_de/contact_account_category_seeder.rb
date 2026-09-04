# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

module PfadiDe
  module ContactAccountCategorySeeder
    # rubocop:disable Style/MutableConstant
    CATEGORIES = {
      "PhoneNumber" => {
        "Person" => [
          {key: "private", name: {de: "Privat"}, unique_per_contactable: true},
          {key: "mobile", name: {de: "Mobil"}, unique_per_contactable: true},
          {key: "work", name: {de: "Arbeit"}, unique_per_contactable: true},
          {key: "guardians", name: {de: "Erziehungsberechtigte"}, unique_per_contactable: true},
          {key: "father", name: {de: "Vater"}, unique_per_contactable: true},
          {key: "mother", name: {de: "Mutter"}, unique_per_contactable: true},
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ],
        "Group" => [
          {key: "office", name: {de: "Büro"}, unique_per_contactable: true},
          {key: "mobile", name: {de: "Mobil"}, unique_per_contactable: true},
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ]
      },
      "AdditionalAddress" => {
        "Person" => [
          {
            key: "parents_guardians",
            name: {de: "Abweichende Adresse Eltern/Erziehungsberechtigte"},
            unique_per_contactable: true
          },
          {key: "secondary_address", name: {de: "Zweitanschrift"}, unique_per_contactable: true},
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ],
        "Group" => [
          {key: "mailing_address", name: {de: "Versandanschrift"}, unique_per_contactable: true},
          {
            key: "efz_address",
            name: {de: "eFZ Anschrift"},
            unique_per_contactable: true,
            efz_address: true
          },
          {key: "rechtstraeger", name: {de: "Rechtsträger"}, unique_per_contactable: true},
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ]
      },
      "AdditionalEmail" => {
        "Person" => [
          {key: "guardians", name: {de: "Erziehungsberechtigte"}, unique_per_contactable: true},
          {key: "father", name: {de: "Vater"}, unique_per_contactable: true},
          {key: "mother", name: {de: "Mutter"}, unique_per_contactable: true},
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ],
        "Group" => [
          {
            key: "invoice_mailing",
            name: {de: "Versand Rechnungen"},
            unique_per_contactable: true,
            used_for_invoices: true
          },
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ]
      },
      "SocialAccount" => {
        "Person" => [
          {key: "website", name: {de: "Webseite"}, unique_per_contactable: false},
          {key: "instagram", name: {de: "Instagram"}, unique_per_contactable: false},
          {key: "facebook", name: {de: "Facebook"}, unique_per_contactable: false},
          {key: "tiktok", name: {de: "TikTok"}, unique_per_contactable: false},
          {key: "fediverse", name: {de: "Fediverse"}, unique_per_contactable: false},
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ],
        "Group" => [
          {key: "website", name: {de: "Webseite"}, unique_per_contactable: false},
          {key: "instagram", name: {de: "Instagram"}, unique_per_contactable: false},
          {key: "facebook", name: {de: "Facebook"}, unique_per_contactable: false},
          {key: "tiktok", name: {de: "TikTok"}, unique_per_contactable: false},
          {key: "fediverse", name: {de: "Fediverse"}, unique_per_contactable: false},
          {key: "other", name: {de: "Andere"}, unique_per_contactable: false}
        ]
      }
    }
    # rubocop:enable Style/MutableConstant

    def self.prepended(base)
      base::CATEGORIES.replace(CATEGORIES)
    end
  end
end
