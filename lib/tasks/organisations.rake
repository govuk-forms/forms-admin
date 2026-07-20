namespace :organisations do
  desc "Update organisations table using data from GOV.UK"
  task fetch: :environment do
    include AdvisoryLock::DSL

    Rails.logger.info("Starting organisation fetch")

    run_organisation_fetch(dry_run: false)

    Rails.logger.info("Organisation fetch complete")
  end

  desc "Dry run for update organisations table using data from GOV.UK"
  task fetch_dry_run: :environment do
    include AdvisoryLock::DSL

    Rails.logger.info("Starting dry run of organisation fetch")

    run_organisation_fetch(dry_run: true)

    Rails.logger.info("Dry run of organisation fetch complete")
  end

  desc "Add organisation that is not in GOV.UK organisation database"
  task :create, %i[name] => :environment do |_, args|
    usage_message = "usage: rails organisations:create[<name>]".freeze
    abort usage_message if args[:name].blank?

    organisation = Organisation.find_by(name: args[:name])
    abort "Organisation already exists: #{organisation.inspect}" if organisation

    organisation = Organisation.create!(
      slug: args[:name].parameterize,
      name: args[:name],
    )

    puts "Created #{organisation.inspect}"
  end

  desc "Change name of an organisation"
  task :rename, %i[old_name new_name] => :environment do |_, args|
    old_name = args[:old_name]
    new_name = args[:new_name]
    usage = "usage: rails organisations:rename[<old_name>,<new_name>]".freeze
    abort usage if old_name.blank? || new_name.blank?

    org = Organisation.find_by(name: old_name)
    abort "#{old_name} not found" if org.blank?
    abort "#{old_name} is from the GOV.UK API and should not be renamed by us" if org.govuk_content_id.present?

    org.name = new_name
    puts "Renamed org #{old_name} to #{new_name}" if org.save!
  end

  desc "Merge an organisation into another"
  task :merge, %i[source_organisation_slug target_organisation_slug] => :environment do |task, args|
    merge_organisations(**args, task:, dry_run: false)
  end

  namespace :merge do
    desc "Merge an organisation into another - dry run"
    task :dry_run, %i[source_organisation_slug target_organisation_slug] => :environment do |task, args|
      merge_organisations(**args, task:, dry_run: true)
    end
  end

  desc "Make an organisation internal"
  task :make_internal, %i[organisation_slug] => :environment do |task, args|
    change_organisation_internal_status(**args, status: true, task:, dry_run: false)
  end

  namespace :make_internal do
    desc "Set whether an organisation is internal - dry run"
    task :dry_run, %i[organisation_slug] => :environment do |task, args|
      change_organisation_internal_status(**args, status: true, task:, dry_run: true)
    end
  end

  desc "Make an organisation external"
  task :make_external, %i[organisation_slug] => :environment do |task, args|
    change_organisation_internal_status(**args, status: false, task:, dry_run: false)
  end

  namespace :make_external do
    desc "Make an organisation external - dry run"
    task :dry_run, %i[organisation_slug] => :environment do |task, args|
      change_organisation_internal_status(**args, status: false, task:, dry_run: true)
    end
  end

  namespace :domains do
    desc "Add domains to an organisation"
    task :add, %i[organisation_slug domains] => :environment do |_task, args|
      organisation_slug = args[:organisation_slug]
      domains = args.to_a[1..]

      usage_message = "usage: rake organisations:domains:add[<organisation_slug>, <domain1>, <domain2>, ...]".freeze
      abort usage_message if organisation_slug.blank? || domains.blank?

      organisation = Organisation.find_by(slug: organisation_slug)
      abort "Organisation with slug #{organisation_slug} does not exist" if organisation.nil?

      domains.each do |domain|
        Rails.logger.info("Adding domain: #{domain}")
        organisation.organisation_domains.create!(domain: domain)
      end
    end

    desc "Remove domains from an organisation"
    task :remove, %i[organisation_slug domains] => :environment do |_task, args|
      organisation_slug = args[:organisation_slug]
      domains = args.to_a[1..]

      usage_message = "usage: rake organisations:domains:remove[<organisation_slug>, <domain1>, <domain2>, ...]".freeze
      abort usage_message if organisation_slug.blank? || domains.blank?

      organisation = Organisation.find_by(slug: organisation_slug)
      abort "Organisation with slug #{organisation_slug} does not exist" if organisation.nil?

      domains.each do |domain|
        organisation.organisation_domains.find_by!(domain: domain).destroy!
        Rails.logger.info("Removed domain: #{domain}")
      rescue ActiveRecord::RecordNotFound
        Rails.logger.info("Domain #{domain} not found for organisation with slug #{organisation_slug}")
      end
    end

    desc "List domains associated with an organisation"
    task :list, %i[organisation_slug] => :environment do |_task, args|
      organisation_slug = args[:organisation_slug]

      usage_message = "usage: rake organisations:domains:list[<organisation_slug>]".freeze
      abort usage_message if organisation_slug.blank?

      organisation = Organisation.find_by(slug: organisation_slug)
      abort "Organisation with slug #{organisation_slug} does not exist" if organisation.nil?

      domains = organisation.organisation_domains.pluck(:domain).sort.join(", ")
      if domains.present?
        Rails.logger.info "Domains for organisation with slug '#{organisation_slug}': #{domains}"
      else
        Rails.logger.info "Organisation with slug '#{organisation_slug}' has no domains"
      end
    end

    desc "Populate organisation domains using the email addresses of existing users"
    task populate_from_users: :environment do
      Organisation.includes(:users, :organisation_domains).find_each do |organisation|
        next if organisation.users.empty?

        users = organisation.users.to_a
        domains = domains_for_users(users).uniq

        domains.each do |domain|
          organisation.organisation_domains.find_or_create_by!(domain: domain)
        end

        Rails.logger.info("Added domains for #{organisation.name}: #{domains.join(', ')}")
      end
    end
  end
end

def run_organisation_fetch(dry_run:)
  with_lock("forms-admin:organisations:fetch") do
    OrganisationsFetcher.new.call(dry_run:)
  end
end

def merge_organisations(task:, source_organisation_slug: nil, target_organisation_slug: nil, dry_run: false)
  usage = "usage: rails #{task.name}[<source_organisation_slug>, <target_organisation_slug>]".freeze
  abort usage if source_organisation_slug.blank? || target_organisation_slug.blank?

  source_organisation = Organisation.find_by_slug!(source_organisation_slug)
  target_organisation = Organisation.find_by_slug!(target_organisation_slug)

  if source_organisation.mou_signatures.any? != target_organisation.mou_signatures.any?
    abort "Can not merge organisations, as #{source_organisation.name} #{source_organisation.mou_signatures.any? ? 'has' : 'has not'} signed MOU but #{target_organisation.name} #{target_organisation.mou_signatures.any? ? 'has' : 'has not'}"
  end

  unless source_organisation.closed
    abort "Can not merge organisations as #{source_organisation.name} is not yet closed"
  end

  ActiveRecord::Base.transaction do
    users = User.where(organisation: source_organisation)
    groups = Group.where(organisation: source_organisation)

    users.lock.load
    groups.lock.load

    if groups.pluck(:name).to_set.intersect?(Group.where(organisation: target_organisation).pluck(:name))
      abort "Can not merge #{source_organisation.name} into #{target_organisation.name}, as there are some duplicate group names"
    end

    if dry_run
      Rails.logger.info("#{task.name}: Would move #{users.count} users and #{groups.count} groups from #{source_organisation.name} to #{target_organisation.name}")
      return
    end

    Rails.logger.info("#{task.name}: Moving #{users.count} users and #{groups.count} groups from #{source_organisation.name} to #{target_organisation.name}")

    users.update_all(organisation_id: target_organisation.id)
    users.touch_all
    groups.update_all(organisation_id: target_organisation.id)
    groups.touch_all
  end
end

def change_organisation_internal_status(task:, organisation_slug: nil, status: nil, dry_run: false)
  usage = "usage: rails #{task.name}[<organisation_slug>]".freeze
  abort usage if organisation_slug.blank?

  status_string = status ? "internal" : "external"

  organisation = Organisation.find_by_slug(organisation_slug)

  abort "Organisation not found" if organisation.blank?
  abort "Organisation '#{organisation.name}' is already #{status_string}" if organisation.internal == status

  ActiveRecord::Base.transaction do
    if dry_run
      Rails.logger.info("#{task.name}: Would make organisation '#{organisation.name}' #{status_string}")
      return
    end

    Rails.logger.info("#{task.name}: Making organisation '#{organisation.name}' #{status_string}")

    organisation.internal = status
    organisation.save!

    Rails.logger.info("#{task.name}: Made organisation '#{organisation.name}' #{status_string}")
  end
end

def domains_for_users(users)
  users.filter_map do |user|
    next if user.email.blank?

    email_domain = user.email.split("@").last&.downcase&.strip
    next if email_domain.blank? || !user.email.include?("@")

    email_domain
  end
end
