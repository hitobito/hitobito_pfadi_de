#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito_pfadi_de and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pfadi_de.

class MigrateGroupTypes < ActiveRecord::Migration[8.0]
  def up
    Group.transaction do

      # All subclasses of Group::Arbeitsbereich have been split into Group::Bund* and Group::Land*.
      # Therefore, depending on the layer which they are attached to, we have to change their type.
      arbeitsbereich_types = [
        "Woelflingsstufe",
        "Pfadfinderstufe",
        "RangerRoverstufe",
        "Stufen",
        "Erwachsenenarbeit",
        "Ausbildung",
        "Internationales",
        "Intakt",
        "IntaktPsychischeGesundheit",
        "IntaktPraeventionUndIntervention",
        "IntaktMachtUndMiteinander",
        "OeffentlichkeitsarbeitMedien",
        "PolitischeBildungPolitikUndGesellschaft",
        "It",
        "Findungskommission",
        "Rainbow",
        "Inklusion",
        "WachstumUndStaemme",
        "Sonstiges"
      ]
      arbeitsbereich_types.each do |arbeitsbereich_type|
        new_bund_type = "Group::Bund#{arbeitsbereich_type}"
        Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
          .where(type: "Group::Arbeitsbereich#{arbeitsbereich_type}",
            layer: { type: "Group::Bundesebene" })
          .update_all(type: new_bund_type)

        new_land_type = "Group::Land#{arbeitsbereich_type}"
        Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
          .where(type: "Group::Arbeitsbereich#{arbeitsbereich_type}",
            layer: { type: "Group::Landesverband" })
          .update_all(type: new_land_type)
      end

      # All group types Group::Stammes* have been renamed to Group::Stamm*.
      # Therefore, depending on the layer which they are attached to, we have to change their type.
      arbeitsbereich_types.each do |arbeitsbereich_type|
        new_stamm_type = "Group::Stamm#{arbeitsbereich_type}"
        Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
          .where(type: "Group::StammesArbeitsbereich#{arbeitsbereich_type}",
            layer: { type: "Group::Stamm" })
          .update_all(type: new_stamm_type)
      end

      # default_children changed on some groups.
      # Therefore, we have to create default_children on all groups.
      Group.find_each do |group|
        group.default_children.each do |group_type|
          next if Group.where(type: group_type, parent_id: group.id).exists?

          child = group_type.new(name: group_type.label)
          child.parent = group
          child.save!
        end
      end

      # Group::Projekt is now nested inside another group type Group::Projekte.
      # Therefore, we have to move all Group::Projekte which are directly attached to
      # Group::Bundesebene inside these parent groups.
      bund_projekte = Group.where(type: "Group::Projekte").first
      if bund_projekte.present?
        Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
          .where(type: "Group::Projekt", layer: { type: "Group::Bundesebene" })
          .update_all(parent_id: bund_projekte.id)
      end

      # Group::Meute, Gilde, Sippe and Runde are now nested inside a group type Group::Gruppen.
      # Therefore, we have to move all such groups which are directly attached to a
      # Group::Stamm inside these parent groups.
      Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
        .where(type: ["Group::Meute", "Group::Gilde", "Group::Sippe", "Group::Runde"],
          layer: { type: "Group::Stamm" })
        .find_each do |group|
        stamm_gruppen = Group.where(parent_id: group.layer_group_id, type: "Group::Gruppen").first
        group.update(parent_id: stamm_gruppen.id)
      end

      # All subclasses of Group::*Arbeitsbereich are now nested inside Group::*Arbeitsbereiche.
      # Therefore, we have to move all such groups which are directly attached to a layer inside
      # these parent groups.
      arbeitsbereich_types = arbeitsbereich_types.map do |t|
        t.gsub("Group::Arbeitsbereich", "")
      end
      bund_arbeitsbereiche = Group.where(type: "Group::BundArbeitsbereiche").first
      if bund_arbeitsbereiche.present?
        Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
          .where(type: arbeitsbereich_types.map { |t| "Group::Bund#{t}" },
            layer: { type: "Group::Bundesebene" })
          .update_all(parent_id: bund_arbeitsbereiche.id)
      end
      Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
        .where(type: arbeitsbereich_types.map { |t| "Group::Land#{t}" },
          layer: { type: "Group::Landesverband" })
        .find_each do |group|
        land_arbeitsbereiche = Group.where(parent_id: group.layer_group_id,
          type: "Group::LandArbeitsbereiche").first_or_create(name: "Arbeitsbereiche")
        group.update(parent_id: land_arbeitsbereiche.id)
      end
      Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
        .where(type: arbeitsbereich_types.map { |t| "Group::Bezirk#{t}" },
          layer: { type: "Group::Bezirk" })
        .find_each do |group|
        bezirk_arbeitsbereiche = Group.where(parent_id: group.layer_group_id,
          type: "Group::BezirkArbeitsbereiche").first_or_create(name: "Arbeitsbereiche")
        group.update(parent_id: bezirk_arbeitsbereiche.id)
      end
      Group.joins("INNER JOIN groups layer on groups.layer_group_id = layer.id")
        .where(type: arbeitsbereich_types.map { |t| "Group::Stamm#{t}" },
          layer: { type: "Group::Stamm" })
        .find_each do |group|
        stamm_arbeitsbereiche = Group.where(parent_id: group.layer_group_id,
          type: "Group::StammArbeitsbereiche").first_or_create(name: "Arbeitsbereiche")
        group.update(parent_id: stamm_arbeitsbereiche.id)
      end

      original = Group.validate_zip_code
      Group.validate_zip_code = false
      Group.rebuild!
      Group.validate_zip_code = original
    end
  end
end
