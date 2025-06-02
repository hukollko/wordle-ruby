# frozen_string_literal: true

words = File.readlines("words.txt", chomp: true)
letters = ("а".."я").to_a

while words.length > 1
  weights = Hash.new(0)
  words.each { |word| word.each_char.uniq.tally(weights, &:itself) }
  weights.select! { |letter, _| letters.include?(letter) }

  guess = words.max_by { |word| word.each_char.uniq.sum(&weights) }

  print "#{guess} (осталось слов: %03d)> " % words.length
  STDOUT.flush

end

puts "Загаданное слово: #{words.first}"

