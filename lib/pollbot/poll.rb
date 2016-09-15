require_relative 'answer'
require_relative 'vote'

class Poll
  attr_accessor :poll_id
  attr_accessor :channel_id
  attr_accessor :owner_id
  attr_accessor :owner_name
  attr_accessor :question
  attr_accessor :answers

  def initialize
  end

  def results
    lines = Array.new

    answers.each_with_index { |answer, index|
      lines.push "[#{index + 1}] #{answer.title} : #{answer.vote_count} votes"
    }

    lines
  end

  def answer_for_vote(answer_id)
    a = answers.find { |a| a.answer_id == answer_id }
    return a
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
      vote.vote_id = nil
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
