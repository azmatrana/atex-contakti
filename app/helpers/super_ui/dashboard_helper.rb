module SuperUi::DashboardHelper

  def percentage_division(numerator, denominator)
    if numerator == 0 or denominator == 0
      0
    elsif !numerator.is_a? Numeric or !denominator.is_a? Numeric
      raise ArgumentError.new('Argument is not a number')
    else
      ((numerator.to_f / denominator.to_f) * 100).round(0)
    end
  end

end
