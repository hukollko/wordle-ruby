# frozen_string_literal: true
# Читаем словарь из 5lenwords_russian_base.txt.txt (по одному слову на строку)
# Предполагается, что все слова в этом файле – русские, одинаковой длины, в нижнем регистре, без пробелов.
words = File.readlines("5lenwords_russian_base.txt", chomp: true, encoding: "UTF-8")
letters = ("а".."я").to_a

while words.length > 1
  # 1. Считаем «вес» каждой оставшейся буквы
  weights = Hash.new(0)
  words.each do |word|
    # Уникальные символы, чтобы не засчитывать одну букву несколько раз
    word.each_char.uniq.tally(weights, &:itself)
  end
  # Оставляем в весах только те буквы, которые ещё не были угаданы/удалены
  weights.select! { |letter, _| letters.include?(letter) }

  # 2. Выбираем guess – слово с наибольшей суммой весов по уникальным буквам
  guess = words.max_by do |word|
    word.each_char.uniq.sum { |ch| weights[ch] }
  end

  # 3. Выводим приглашение и ждём отклик от пользователя
  print "#{guess} (осталось слов: %03d)> " % words.length
  STDOUT.flush

  # 4. Безопасно читаем ввод: если STDIN закрыт или EOF, raw может быть nil
  raw = gets
  break if raw.nil?   # прерываем игру, если ввода больше нет
  input = raw.chomp.downcase

  case input
  when "?"
    # Слово guess не подходит (не из словаря) – удаляем его из списка
    words.delete(guess)

  when "б", "буквы"
    # Выводим массив всех оставшихся букв (серые/неиспользованные)
    p letters

  when "с", "слова"
    # Выводим весь текущий список возможных слов
    p words

  when "q", "выход"
    # Завершаем игру досрочно
    exit

  when /^[_зж]{#{guess.length}}$/
    # Пользователь ввёл строку из символов "_" (нет в слове),
    # "з" (буква на своём месте) и "ж" (буква есть, но не на этом месте).
    # Например: "_з__ж" для 5-буквенного слова

    # Применяем фильтрацию списка words на основе каждого символа отклика
    guess.each_char.zip(input.each_char).each_with_index do |(letter, action), index|
      # Убираем текущую букву из списка «оставшихся букв» (letters)
      letters.delete(letter)

      case action
      when "_"
        # Если буква точно не входит в загаданное слово
        words.reject! { |word| word.include?(letter) }

      when "з"
        # Если буква есть и стоит на правильном месте (зелёный)
        words.reject! { |word| word[index] != letter }

      when "ж"
        # Если буква есть, но НЕ на этом месте (жёлтый)
        words.reject! { |word| !word.include?(letter) || word[index] == letter }
      end
    end

  else
    # Неверный формат ввода: ничего не меняем, просто сообщаем ошибку
    puts "Неверный ввод: введите ?, б(буквы), с(слова), выход или последовательность из _,з,ж длины #{guess.length}."
  end
end

# Когда цикл завершился, список words либо пуст, либо содержит ровно одно слово
if words.empty?
  puts "Словарь пуст, решения нет."
else
  puts "Загаданное слово: #{words.first}"
end