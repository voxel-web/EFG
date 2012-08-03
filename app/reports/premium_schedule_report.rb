require 'active_model/model'
require 'csv'

class PremiumScheduleReport
  LOAN_SCHEMES = ['All', 'SFLG only', 'EFG only']
  LOAN_TYPES = %w(All New Legacy)
  SCHEDULE_TYPES = %w(All New Changed)

  include ActiveModel::Model

  attr_accessor :collection_month, :lender_id, :loan_reference, :loan_scheme,
    :loan_type, :schedule_type
  attr_reader :finish_on, :start_on

  validates_format_of :collection_month, with: /\d+\/\d+/, allow_blank: true
  validate :all_the_things

  def count
    loans.count
  end

  def finish_on=(value)
    @finish_on = QuickDateFormatter.parse(value)
  end

  def lender
    Lender.find(lender_id) if lender_id.present?
  end

  def loans
    scope = Loan
      .select([
        'loans.*',
        'loan_changes.date_of_change AS _draw_down_date',
        'lenders.organisation_reference_code AS _lender_organisation'
      ].join(', '))
      .joins(:lender, :loan_changes)
      .where(loan_changes: { seq: 0 })

    scope = scope
      .joins(:state_aid_calculations)
      .where('state_aid_calculations.seq = (?)',
        StateAidCalculation.select('MAX(seq)').where(loan_id: 'loans.id').to_sql
      )

    if schedule_type.present? && schedule_type != 'All'
      calc_type = schedule_type == 'Changed' ? 'R' : %w(S N)
      scope = scope.where(state_aid_calculations: { calc_type: calc_type })
    end

    if loan_scheme.present? && loan_scheme != 'All'
      scheme = loan_scheme == 'SFLG Only' ? Loan::SFLG_SCHEME : Loan::EFG_SCHEME
      scope = scope.where(loans: { loan_scheme: scheme })
    end

    if loan_type.present? && loan_type != 'All'
      loan_source = loan_type == 'Legacy' ? Loan::LEGACY_SFLG_SOURCE : Loan::SFLG_SOURCE
      scope = scope.where(loans: { loan_source: loan_source })
    end

    scope = scope.where(lender_id: lender_id) if lender_id.present?
    scope = scope.where(reference: loan_reference) if loan_reference.present?
    scope
  end

  def start_on=(value)
    @start_on = QuickDateFormatter.parse(value)
  end

  def to_csv
    CSV.generate do |csv|
      csv << PremiumScheduleReportRow::HEADERS

      PremiumScheduleReportRow.from_loans(loans).each do |row|
        csv << row.to_csv
      end
    end
  end

  private
    def all_the_things
      return if loan_reference.present?

      if collection_month.blank? && schedule_type != 'New'
        errors.add(:collection_month, :required)
      end

      if finish_on.blank? && start_on.blank? && schedule_type != 'Changed'
        errors.add(:base, :start_or_finish_required)
      end

      if schedule_type == 'Changed' && (finish_on.present? || start_on.present?)
        errors.add(:base, :start_or_finish_forbidden)
      end
    end
end
