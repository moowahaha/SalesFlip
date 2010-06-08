# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def add_new( text, path )
    "<a href='#{path}' id='new'><b>+</b>#{text}</a>"
  end
  
  def show_attribute( object, attribute, custom = false )
    if object.send(attribute).present?
      att = ""
      att << "<dt>#{I18n.t("simple_form.labels.#{attribute}")}</dt>"
      att << "<dd>"
      custom ? att << custom : att << object.send(attribute).to_s
      att << "</dd>"
    end
  end
  
  def rating_for( object )
    rating = "<span class='rating'>"
    if object.rating.present?
      object.rating.times       { rating << "<span class='on'>&#9733;</span>" }
      (5 - object.rating).times { rating << "<span class='off'>&#9733;</span>" }
    else
      5.times {rating << "<span class='off'>&#9733;</span>"}
    end
    rating << "</span>"
    rating
  end
  
  def activity_icon(string)
    case string
    when "created"; "&#9998;";
    when "updated"; "&#9998;";
    when "re-assigned"; "&#10132;";
    when "rejected"; "&#10008;";
    when "converted"; "&#10004;";
    when "completed"; "&#10004;";
    when "deleted"; "&#10006;";
    else
      "&#9670;"
    end
  end
  
end
