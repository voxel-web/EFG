module LoanModificationsHelper
  def format_modification_value(value)
    case value
    when Date
      value.to_s(:screen)
    when Money
      value.format
    else
      value
    end
  end
end
