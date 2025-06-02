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

  case input = gets.chomp.downcase
  when "?"
    words.delete(guess)
  when "б", "буквы"
    p letters
  when "с", "слова"
    p words
  when "q", "выход"
    exit
  when /^[_зж]{#{guess.length}}$/
    actions = guess.each_char.zip(input.each_char)
    actions.each_with_index do |(letter, action), index|
      letters.delete(letter)

      case action
      when "_"
        words.reject! { |word| word.include?(letter) }
      when "з"
        words.reject! { |word| word[index] != letter }
      when "ж"
        words.reject! { |word| !word.include?(letter) || word[index] == letter }
      end
    end
  else
    puts "Неверный ввод: введите ?, б(буквы), с(слова), выход или последовательность из _,з,ж."
  end
end

puts "Загаданное слово: #{words.first}"

