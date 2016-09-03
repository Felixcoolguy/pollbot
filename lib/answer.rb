class Answer
  attr_accessor :index
  attr_accessor :title
  attr_accessor :votes

  def self.create(index, text)
    answer = Answer.new
    answer.index = index
    answer.title = text
    answer.votes = Array.new
    answer
  end
end
