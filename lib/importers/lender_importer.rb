class LenderImporter < BaseImporter
  self.csv_path = Rails.root.join('import_data/lenders.csv')
  self.klass = Lender

  FIELD_MAPPING = {
    "OID"                         => :legacy_id,
    "NAME"                        => :name,
    "CREATION_TIME"               => :created_at,
    "LAST_MODIFIED"               => :updated_at,
    "VERSION"                     => :version,
    "HIGH_VOLUME"                 => :high_volume,
    "CAN_USE_ADD_CAP"             => :can_use_add_cap,
    "ORGANISATION_REFERENCE_CODE" => :organisation_reference_code,
    "PRIMARY_CONTACT_NAME"        => :primary_contact_name,
    "PRIMARY_CONTACT_PHONE"       => :primary_contact_phone,
    "PRIMARY_CONTACT_EMAIL"       => :primary_contact_email,
    "STD_CAP_LENDING_ALLOCATION"  => :std_cap_lending_allocation,
    "ADD_CAP_LENDING_ALLOCATION"  => :add_cap_lending_allocation,
    "DISABLED"                    => :disabled,
    "AR_TIMESTAMP"                => :ar_timestamp,
    "AR_INSERT_TIMESTAMP"         => :ar_insert_timestamp,
    "CREATED_BY"                  => :created_by,
    "MODIFIED_BY"                 => :modified_by,
    "ALLOW_ALERT_PROCESS"         => :allow_alert_process,
    "MAIN_POINT_OF_CONTACT_USER"  => :main_point_of_contact_user,
    "LOAN_SCHEME"                 => :loan_scheme
  }

  def attributes
    attrs = {}
    @row.each do |field_name, value|
      attrs[FIELD_MAPPING[field_name]] = value
    end
    attrs
  end
end