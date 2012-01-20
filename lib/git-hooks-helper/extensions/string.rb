class String
  def red;    "\e[1m\e[31m#{self}\e[0m"; end
  def green;  "\e[1m\e[32m#{self}\e[0m"; end
  def yellow; "\e[1m\e[33m#{self}\e[0m"; end
end