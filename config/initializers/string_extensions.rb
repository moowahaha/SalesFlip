class String
  def to_dom_id
    self.downcase.gsub(/\s/, '-').gsub(/[^\w^\-]/, '')
  end

  def strip_html
    self.gsub(/<\/?[^>]*>/, "") if self
  end
end
