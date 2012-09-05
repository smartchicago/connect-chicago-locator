module ApplicationHelper
  def title(page_title)
    content_for :title, page_title.to_s
  end
  
  def snippet(string, length = 40) 
    string.size > length+5 ? [string[0,length],string[-5,5]].join("...") : string
  end 
  
  def yes_no_icon input
    #puts "input: #{input}"
    if input == "1"
      return "<i class='icon-ok'></i>&nbsp;Yes".html_safe()
    elsif input == "0"
      return "<i class='icon-remove'></i>&nbsp;No".html_safe()
    else
      return "<i class='icon-minus'></i>&nbsp;Unknown".html_safe()
    end
  end
  
  def encodeAddress address
    address.gsub(/\/n/, ' ').gsub(/ /, '+')
  end
  
  def formatAddress street, city, state, zip, room
    result = street
    result += "<br />"
    result += "#{city}, #{state} #{zip}"
    unless room.nil?
      result += "<br />"
      result += room
    end
    result.html_safe()
  end

  def formatContact name, email
    result = name
    unless (email.nil?)
      result = "<a href='mailto:#{email}'>#{name}</a>";
    end
    result.html_safe()
  end
  
  def formatLocationAttribute title, attribute 
    result = ""
    unless attribute.nil?
      result += "<tr>"
      result += "<td><img src='/images/computer.png' alt=\"" + title + "\"/></td>"
      result += "<td>" + title + "<br />" + attribute + "</td>"
      result += "</tr>"
    end
    result.html_safe()
  end
end
