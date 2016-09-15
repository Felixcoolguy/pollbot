class Answer
  attr_accessor :answer_id
  attr_accessor :title
  attr_accessor :vote_count

  def self.create(id, text)
    answer = Answer.new
    answer.answer_id = id
    answer.title = text
    answer.vote_count = 0
    answer
  end
end
