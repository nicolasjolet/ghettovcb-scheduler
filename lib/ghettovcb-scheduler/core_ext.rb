module CoreExt
  def String.in?(array)
    array.include?(self)
  end
end