# Methods added to this helper will be available to all templates in the application.
module TasksHelper
  def task_asset_info(task,link=false)
    return if task.asset_id.blank? || action_is('show')
    a = task.asset
    a_to_dom = a.class.to_s.underscore.downcase
    print =  "<br/><small class='xs'><span class='asset_type "
    print << "#{a_to_dom}'>#{a.class.to_s}: </span>"
    print << link if link
    print << " @ #{a.company}" if a.respond_to?('company') && a.company.present?
    print << " | Email: <a href='mailto:#{a.email}'>#{a.email}</a>" if a.email.present?
    print << " | Phone: #{a.phone}" if a.phone.present?
    print << "</small>"
    print.html_safe
  end
end
