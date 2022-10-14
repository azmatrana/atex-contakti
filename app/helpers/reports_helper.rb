module ReportsHelper

  def get_report_tab_class(report, kind)
    if report.persisted?
      report.kind == kind ? 'active' : 'hide'
    elsif report.errors.blank?
      kind == 'summary' ? 'active' : nil
    else
      report.kind == kind ? 'active' : nil
    end
  end

  def format_date_range(report)
    date_format = '%d/%m/%Y'
    if report.starts_at.present? && report.ends_at.present?
      if report.starts_at + 1.day > report.ends_at
        report.starts_at.strftime(date_format)
      else
        "#{report.starts_at.strftime(date_format)}-#{report.ends_at.strftime(date_format)}"
      end
    else
      ''
    end
  end

  def format_start_sending_at(report)
    # return false
    time_format = '%d/%m/%Y %H:%M'
    if report.start_sending_at?
      report.start_sending_at.strftime(time_format)
    # else
    #   ::Time.current.strftime(time_format)
    end
  end

  def start_sending_at_helper(report, form_object)
    formatted_date = format_start_sending_at(report)
    if report.schedule_start_sent_already
      html = '<input name="report[start_sending_at]"'\
                    'type="text" value="%s" class="form-control" readonly />' % formatted_date
      html.html_safe
    else
      html = '<input name="report[start_sending_at]" autocomplete="off"'\
                    'type="text" value="%s" class="form-control time-picker" />' % formatted_date
      html.html_safe
    end
  end

  def get_btn_class(report)
    "btn btn-default #{'disabled' unless report.persisted?}"
  end

  def get_hide_class(report)
    'hide' unless report.persisted?
  end

end
