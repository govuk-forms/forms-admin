namespace :groups do
  desc "Move all groups in one organisation to another"
  task :move_all_groups_between_organisations, %i[source_organisation_id target_organisation_id] => :environment do |_, args|
    task_name = "groups:move_all_groups_between_organisations"
    source_organisation_id = args[:source_organisation_id]
    target_organisation_id = args[:target_organisation_id]

    run_bulk_task(task_name:, source_organisation_id:, target_organisation_id:, rollback: false)
  end

  desc "Move all groups in one organisation to another (dry run)"
  task :move_all_groups_between_organisations_dry_run, %i[source_organisation_id target_organisation_id] => :environment do |_, args|
    task_name = "groups:move_all_groups_between_organisations_dry_run"
    source_organisation_id = args[:source_organisation_id]
    target_organisation_id = args[:target_organisation_id]

    run_bulk_task(task_name:, source_organisation_id:, target_organisation_id:, rollback: true)
  end

  desc "Remove empty group"
  task :remove_group, %i[group_id] => :environment do |_, args|
    usage_message = "usage: rake groups:remove_group[<group_external_id>]".freeze
    abort usage_message if args[:group_id].blank?
    remove_group("groups:remove_group", args[:group_id])
  end

  desc "Remove empty group dry run"
  task :remove_group_dry_run, %i[group_id] => :environment do |_, args|
    usage_message = "usage: rake groups:remove_group_run[<group_external_id>]".freeze
    abort usage_message if args[:group_id].blank?

    ActiveRecord::Base.transaction do
      remove_group("groups:remove_group_dry_run", args[:group_id])
      raise ActiveRecord::Rollback
    end
  end

  desc "Toggle a group-scoped feature flag for a group"
  task :toggle_feature_flag, %i[feature_name group_id] => :environment do |_, args|
    usage_message = "usage: rake groups:toggle_feature_flag[<feature_name>, <group_external_id>]".freeze
    abort usage_message if args[:feature_name].blank? || args[:group_id].blank?

    # accept the feature name with or without the _enabled suffix
    attribute_name = "#{args[:feature_name].delete_suffix('_enabled')}_enabled"

    unless Group.feature_flag_attributes.include?(attribute_name)
      valid_names = Group.feature_flag_attributes.map { |attribute| attribute.delete_suffix("_enabled") }
      abort "unknown feature flag: #{args[:feature_name]}. Valid feature flags: #{valid_names.join(', ')}"
    end

    toggle_group_feature_flag(args[:group_id], attribute_name)
  end
end

def run_task(task_name, args, rollback:)
  *group_ids, org_id = args.to_a

  usage_message = "usage: rake #{task_name}[<group_external_id>, ..., <organisation_id>]".freeze
  abort usage_message if group_ids.blank? || org_id.blank?

  ActiveRecord::Base.transaction do
    change_organisation(group_ids, org_id, task_name:)
    raise ActiveRecord::Rollback if rollback
  end
end

def run_bulk_task(task_name:, source_organisation_id:, target_organisation_id:, rollback:)
  usage_message = "usage: rake #{task_name}[<source_organisation_id>, <target_organisation_id>]".freeze
  abort usage_message if source_organisation_id.blank? || target_organisation_id.blank?

  ActiveRecord::Base.transaction do
    source_organisation = Organisation.find_by(id: source_organisation_id)
    target_organisation = Organisation.find_by(id: target_organisation_id)

    raise ActiveRecord::RecordNotFound, "No organisation associated with source_organisation #{source_organisation_id}" if source_organisation.blank?
    raise ActiveRecord::RecordNotFound, "No organisation associated with target_organisation_id #{target_organisation_id}" if target_organisation.blank?

    groups = source_organisation.groups

    update_groups(groups:, target_organisation:, task_name:)
    raise ActiveRecord::Rollback if rollback
  end
end

def update_groups(groups:, target_organisation:, task_name:)
  groups.each do |group|
    Rails.logger.info "#{task_name}: changing #{fmt_group(group)} from #{fmt_organisation(group.organisation)} to #{fmt_organisation(target_organisation)}"

    group.organisation = target_organisation
    group.save!
  end
end

def fmt_organisation(org)
  "organisation #{org.id} (#{org.name})"
end

def fmt_group(group)
  "group #{group.external_id} (#{group.name})"
end

def fmt_form(form)
  "form #{form.id} (#{form.name})"
end

def remove_group(task_name, group_id)
  group = Group.find_by!(external_id: group_id)

  Rails.logger.info "#{task_name}: trying to remove #{fmt_group(group)}"

  if group.group_forms.any?
    Rails.logger.info "#{task_name}: #{fmt_group(group)} contains #{group.group_forms.count} forms. Please remove the forms first."
    raise SystemExit
  end

  group.destroy!
  Rails.logger.info "#{task_name}: removed #{fmt_group(group)}"
end

def toggle_group_feature_flag(group_id, attribute_name)
  group = Group.find_by!(external_id: group_id)

  group.send("#{attribute_name}=", !group.send(attribute_name))
  group.save!

  Rails.logger.info "#{attribute_name} for #{fmt_group(group)} is now set to #{group.reload.send(attribute_name)}"
end
