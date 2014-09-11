class Domain < ActiveRecord::Base
  # TODO whois requests ip whitelist for full info for own domains and partial info for other domains
  # TODO most inputs should be trimmed before validatation, probably some global logic?
  belongs_to :registrar
  belongs_to :owner_contact, class_name: 'Contact'

  has_many :domain_contacts, dependent: :delete_all

  has_many :tech_contacts, -> do
    where(domain_contacts: { contact_type: DomainContact::TECH })
  end, through: :domain_contacts, source: :contact

  has_many :admin_contacts, -> do
    where(domain_contacts: { contact_type: DomainContact::ADMIN })
  end, through: :domain_contacts, source: :contact

  has_many :nameservers, dependent: :delete_all

  has_many :domain_statuses, dependent: :delete_all

  has_many :domain_transfers, dependent: :delete_all

  delegate :code, to: :owner_contact, prefix: true
  delegate :email, to: :owner_contact, prefix: true
  delegate :ident, to: :owner_contact, prefix: true
  delegate :phone, to: :owner_contact, prefix: true
  delegate :name, to: :registrar, prefix: true

  before_create :generate_auth_info

  validates :name_dirty, domain_name: true, uniqueness: true
  validates :period, numericality: { only_integer: true }
  validates :owner_contact, presence: true

  validate :validate_period
  #validate :validate_nameservers_uniqueness

  def name=(value)
    value.strip!
    write_attribute(:name, SimpleIDN.to_unicode(value))
    write_attribute(:name_puny, SimpleIDN.to_ascii(value))
    write_attribute(:name_dirty, value)
  end

  def pending_transfer
    domain_transfers.find_by(status: DomainTransfer::PENDING)
  end

  ### VALIDATIONS ###

  def validate_nameservers_count
    sg = SettingGroup.domain_validation
    min, max = sg.setting(:ns_min_count).value.to_i, sg.setting(:ns_max_count).value.to_i

    return if nameservers.length.between?(min, max)
    errors.add(:nameservers, :out_of_range, { min: min, max: max })
  end

  def validate_nameservers_uniqueness
    validated = []
    nameservers.each do |ns|
      next if validated.include?(ns.hostname)

      existing = nameservers.select { |x| x.hostname == ns.hostname }
      if existing.length > 1
        validated << ns.hostname
        errors.add(:nameservers, :taken)
        add_epp_error('2302', 'hostObj', ns.hostname, [:nameservers, :taken])
      end
    end
  end

  def validate_admin_contacts_count
    errors.add(:admin_contacts, :out_of_range) if admin_contacts_count.zero?
  end

  def validate_period
    return unless period.present?
    if period_unit == 'd'
      valid_values = %w(365 366 710 712 1065 1068)
    elsif period_unit == 'm'
      valid_values = %w(12 24 36)
    else
      valid_values = %w(1 2 3)
    end

    errors.add(:period, :out_of_range) unless valid_values.include?(period.to_s)
  end

  def all_dependencies_valid?
    validate_nameservers_count
    validate_admin_contacts_count
  end

  ## SHARED

  def to_s
    name
  end

  def generate_auth_info
    begin
      self.auth_info = SecureRandom.hex
    end while self.class.exists?(auth_info: auth_info)
  end

  def tech_contacts_count
    domain_contacts.select { |x| x.contact_type == DomainContact::TECH }.count
  end

  def admin_contacts_count
    domain_contacts.select { |x| x.contact_type == DomainContact::ADMIN }.count
  end

  class << self
    def convert_period_to_time(period, unit)
      return period.to_i.days if unit == 'd'
      return period.to_i.months if unit == 'm'
      return period.to_i.years if unit == 'y'
    end
  end
end
