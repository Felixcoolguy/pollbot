require_relative 'answer'
require_relative 'vote'

class Poll
  attr_accessor :channel_id
  attr_accessor :owner
  attr_accessor :question
  attr_accessor :answers

  def self.create(channel_id, user, *arguments)
    poll = Poll.new
    poll.channel_id = channel_id
    poll.owner = user
    poll.answers = Array.new

    line = arguments.join(' ')
    parts = line.split(',')

    if parts.length == 0
      nil and return
    elsif parts.length == 1 || parts.length == 2
      poll.question = parts[0].strip
      poll.answers.push(Answer.create(0, "Yes"))
      poll.answers.push(Answer.create(1, "No"))
    else
      poll.question = parts[0].strip
      parts.each_with_index { |text, index|
        next if index == 0
        poll.answers.push(Answer.create(index - 1, text.strip))
      }
    end
    poll
  end

  def results
    lines = Array.new

    answers.each do |a|
      lines.push "[#{a.index + 1}] #{a.title} : #{a.votes.length} votes"
    end

    lines
  end

  def vote(user_id, index)

    already_voted = false

    if !index.is_i? || index.to_i > answers.length || index.to_i < 1
      "This was an invalid vote, please vote #{1} - #{answers.length}"
    else
      answers.each do |a|
        user_vote = a.votes.find { |v| v.voter == user_id }
        if !user_vote.nil?
          a.votes.delete(user_vote)
          already_voted = true
        end
      end

      answer = answers[index.to_i - 1]
      vote = Vote.new
      vote.answer_index = index
      vote.voter = user_id
      answer.votes.push(vote)

      if already_voted
        "You already voted, but your vote was updated accordingly"
      else
        "Your vote has been added"
      end
    end
  end
end

class String
  def is_i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end
end
