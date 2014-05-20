require "enju_trunk_circulation/engine"

module EnjuTrunkCirculation
  def report_path
    Engine.root + 'report'
  end
  module_function :report_path

  def new_report(name, base = nil)
    base ||= report_path
    ThinReports::Report.new layout: File.join(base, name)
  end
  module_function :new_report
end
