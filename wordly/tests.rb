# tests.rb

# frozen_string_literal: true
require "open3"

# Устанавливаем кодировку по умолчанию (особенно важно на Windows)
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

queue = Queue.new

# Читаем все слова из словаря (UTF-8)
File.foreach("5lenwords_russian_base.txt", chomp: true, encoding: "UTF-8") do |w|
  word = w.strip.force_encoding("UTF-8")
  queue << word unless word.empty?
end

results = Hash.new(0)

workers = 8.times.map do
  Thread.new do
    until queue.empty?
      word = queue.shift
      guesses = 0

      Open3.popen2("ruby wordly.rb") do |stdin, stdout, _waiter|
        loop do
          raw = stdout.read(3)
          break if raw.nil?

          read = raw.force_encoding("UTF-8")
          if read == "Заг"
            # дочитать остаток "аданное"
            stdout.read(7)
            break
          end

          guesses += 1

          part = stdout.read(2)
          part = "" if part.nil?
          guess = "#{read}#{part.force_encoding("UTF-8")}"

          stdout.read(10)

          guess.force_encoding("UTF-8")
          word_utf8 = word.force_encoding("UTF-8")

          feedback_chars = guess.each_char.map.with_index do |ch, idx|
            c = ch.force_encoding("UTF-8")
            if word_utf8[idx] == c
              "з"
            elsif word_utf8.include?(c)
              "ж"
            else
              "_"
            end
          end

          begin
            stdin.write(feedback_chars.join + "\n")
            stdin.flush
          rescue Errno::EPIPE
            # Дочерний процесс закрыл STDIN (игра уже завершилась) — прерываем цикл
            break
          end
        end

        final_line = stdout.gets&.force_encoding("UTF-8")
        unless final_line && final_line.start_with?("Загаданное слово:")
          raise "Ожидалось «Загаданное слово: …», получили: #{final_line.inspect}"
        end

        guessed = final_line.split(":", 2)[1].strip
        unless guessed == word
          raise "Игра угадала «#{guessed}», а должна была «#{word}»"
        end
      end

      results[guesses] += 1
    end
  end
end

workers.each(&:join)

puts "Результаты (сколько слов угадано за N попыток):"
p results.sort.to_h

score = (results[1] + results[2] + results[3]) * 10 +
  (results[4] + results[5] + results[6]) * 5
puts "Итоговый score: #{score}"