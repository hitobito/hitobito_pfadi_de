# Hitobito Pfadi DE

This hitobito wagon defines the organization hierarchy with groups and roles of BdP and DPSG.

The shared pfadi_de wagon should define the following, which is supposed to be the same for
both organizations:
- Shared group and role types
- All permissions / abilities
- All business logic, including specs for the intended states of the feature toggles for both organizations
- The complete database structure
- The complete JSON:API
- German translation overrides, where the hitobito core uses Swiss German terms

In the hitobito_bdp and hitobito_dpsg wagons, we only define the following:
- Specific group and role types which must not exist in the other wagon
- Translations for all group and role types
- Customization to the used attributes of models, where absolutely necessary
- Corporate design, colors, fonts, logo
- Feature toggles in settings.yml to activate / deactivate logic from pfadi_de

This strategy enables lower maintenance costs and high compatibility across organizations of tools
and third-party software interacting with hitobito_bdp or hitobito_dpsg.

## Pfadi DE Organization Hierarchy

Since not all group and role types are translated in hitobito_pfadi_de, please see the
wagon repository readmes in hitobito_bdp and hitobito_dpsg for the complete organization hierarchy.
