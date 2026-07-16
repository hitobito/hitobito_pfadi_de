# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de

require "hexapdf"

module Export::Pdf
  class EfzAntrag
    TEMPLATE_PATH = "lib/pdf_templates/efz_antrag.pdf"
    ADDRESS_LABEL_EFZ = "anschrift_efz"
    DATE_FORMAT = "%d.%m.%Y"

    TemplateNotFound = Class.new(StandardError)

    attr_reader :group, :person

    def initialize(group, person)
      @group = group
      @person = person
    end

    def generate
      fill_form_fields
      doc.acro_form.flatten

      # Important: use `incremental: true` to preserve the original fonts
      # Without incremental, fonts are re-encoded during writing and may change,
      # which leads to incorrect fonts in the generated PDF.
      doc.write_to_string(validate: false, incremental: true)
    end

    def form_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      {
        # Data of the person for who the eFZ is being requested
        "mitglied_name" => format_address_only_name(person),
        "mitglied_address" => format_address_without_name(person),
        "mitglied_number" => person.id.to_s,
        "mitglied_birthdate" => person.birthday&.strftime(DATE_FORMAT),
        "mitglied_city" => person.town,

        # Data of the group which is responsible for the eFZ inspection
        "group_name" => format_address_only_name(efz_verantwortliche_stelle),
        "group_address" => format_address_without_name(efz_verantwortliche_stelle),
        "group_mail" => efz_verantwortliche_stelle.email,
        "group_phone" => phone_number(efz_verantwortliche_stelle),
        "group_url" => group_url(efz_verantwortliche_stelle),

        # Data of the recipient of the eFZ
        "efz_recipient_name" =>
          format_address_only_name(efz_verantwortliche_stelle, label: ADDRESS_LABEL_EFZ),
        "efz_recipient_address" =>
          format_address_without_name(efz_verantwortliche_stelle, label: ADDRESS_LABEL_EFZ),

        "date" => Date.current.strftime(DATE_FORMAT)
      }.transform_values(&:to_s)
    end

    private

    def doc
      @doc ||= HexaPDF::Document.open(template_path)
    end

    # Finds the template in the last wagon which is the organisation specific wagon
    # of the current hitobito instance.
    def template_path
      path = File.join(Wagons.all.last.root, TEMPLATE_PATH)
      raise TemplateNotFound, "Template not found: #{path}" unless File.exist?(path)
      path
    end

    # Fill the form fields with the data
    # We can not simply use `acro_form.fill` because it would fill for each key
    # the first field it finds. But our form contains multiple fields with the same name,
    # so we must iterate over all fields and fill them manually.
    def fill_form_fields
      doc.acro_form.each_field do |field|
        field_name = field.field_name
        field.field_value = form_data[field_name] if form_data.key?(field_name)
      end
    end

    def efz_verantwortliche_stelle
      @efz_verantwortliche_stelle ||= group.decorate.efz_verantwortliche_stelle
    end

    def group_url(group)
      Rails.application.routes.url_helpers.group_url(
        group,
        host: Settings.application.hostname,
        protocol: Settings.application.protocol
      )
    end

    def format_address_without_name(contactable, label: nil)
      Contactable::Address.new(contactable, label:).efz_full_address_without_name
    end

    def format_address_only_name(contactable, label: nil)
      Contactable::Address.new(contactable, label:).efz_only_name
    end

    def phone_number(contactable)
      contactable.phone_numbers.first&.number || ""
    end
  end
end
