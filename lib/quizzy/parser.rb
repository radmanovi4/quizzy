module Quizzy
  class Parser
    def self.parse_file(path_to_file)
      file = File.open(path_to_file, 'rb')
      full_text = file.read
      file.close

      parse_markdown(full_text)
    end

    private

    def self.parse_markdown(markdown_text)
      lines = markdown_text.split("\n").map(&:strip).reject(&:empty?)

      question_borders = lines.each_index.select do |index|
        classify_entry(lines[index], 'category')
      end
      question_borders << lines.length

      question_borders.each_cons(2) do |left, right|
        parse_question(lines[left...right])
      end
    end

    def self.parse_question(question_md)
      category_section = select_only(question_md, 'category').first
      category_section.slice!(0)
      category_names = category_section.split(',')

      categories = []

      category_names.each do |category_name|
        categories << Category.find_or_create_by(name: category_name.strip)
      end

      question_text = select_only(question_md, 'question_text').first
      question_text.slice!(0)
      question = Question.create(text: question_text.strip)

      answers_texts = select_only(question_md, 'answer')
      answers_texts.each do |answer_text|
        is_correct = classify_entry(answer_text.slice!(0), 'correct_answer')
        question.answers << Answer.create(
          text: answer_text.strip,
          is_correct: is_correct
        )
      end

      categories.each { |category| question.categories << category }
    end

    def self.select_only(entries, type)
      entries.select { |entry| classify_entry(entry, type) }
    end

    def self.classify_entry(entry, type)
      if type == 'answer'
        classify_entry(entry, 'correct_answer') ||
          classify_entry(entry, 'incorrect_answer')
      else
        entry.chars.first == Quizzy::MARKDOWN_CHARS[type]
      end
    end
  end
end
