require_relative "poll"

class Database

  require 'sqlite3'

  @db = nil

  def initialize(filename)

    @db = SQLite3::Database.open(filename)
    @db.results_as_hash = true
    create_schema()

  end

  def create_poll(channel_id, user, *arguments)
    line = arguments.join(' ')
    parts = line.split(',')

    question = nil
    answers = Array.new

    if parts.length == 0
      return nil
    elsif parts.length == 1 || parts.length == 2
      question = parts[0].strip
      answers = ['Yes', 'No']
    else
      question = parts[0].strip
      parts.each_with_index { |text, index|
        next if index == 0
        answers.push text.strip
      }
    end

    poll_insert = @db.prepare "INSERT INTO Polls (ChannelId, OwnerId, OwnerName, Question, Open) VALUES (?, ?, ?, ?, ?)"
    poll_insert.bind_param 1, channel_id
    poll_insert.bind_param 2, user.id
    poll_insert.bind_param 3, user.username
    poll_insert.bind_param 4, question
    poll_insert.bind_param 5, 1
    result = poll_insert.execute

    poll_id = @db.last_insert_row_id

    answers.each_with_index do |answer, index|
      answer_insert = @db.prepare "INSERT INTO Answers (PollId, SortOrder, Title) VALUES (?, ?, ?)"
      answer_insert.bind_param 1, poll_id
      answer_insert.bind_param 2, index
      answer_insert.bind_param 3, answer
      answer_insert.execute
    end

    find_poll(channel_id)

  end

  def find_poll(channel_id)
    poll_query = @db.prepare "SELECT Id, ChannelId, OwnerId, OwnerName, Question FROM Polls WHERE ChannelId = ? AND Open = 1"
    poll_query.bind_param 1, channel_id
    results = poll_query.execute
    row = results.first
    puts row
    if row.nil?
      return nil
    else
      poll = Poll.new
      poll.poll_id = row['Id']
      poll.channel_id = row['ChannelId']
      poll.owner_id = row['OwnerId']
      poll.owner_name = row['OwnerName']
      poll.question = row['Question']
      find_answers(poll)
    end
  end

  def find_answers(poll)
    poll.answers = Array.new

    answer_query = @db.prepare "SELECT Id, Title FROM Answers WHERE PollId = ? ORDER BY SortOrder"
    answer_query.bind_param 1, poll.poll_id
    results = answer_query.execute

    results.each do |row|
      answer = Answer.create(row['Id'], row['Title'])
      poll.answers.push get_vote_count(answer)
    end

    poll
  end

  def get_vote_count(answer)
    vote_query = @db.prepare "SELECT count(Id) as VoteCount FROM Votes WHERE AnswerId = ?"
    vote_query.bind_param 1, answer.answer_id
    results = vote_query.execute

    results.each do |row|
      answer.vote_count = row['VoteCount']
    end

    answer
  end

  def find_vote_for_user(poll_id, channel_id, user_id)
    vote_query = @db.prepare "SELECT Id, AnswerId, PollId, ChannelId, Voter FROM Votes WHERE ChannelId = ? AND Voter = ? AND PollId = ?"
    vote_query.bind_param 1, channel_id
    vote_query.bind_param 2, user_id
    vote_query.bind_param 3, poll_id
    results = vote_query.execute

    row = results.first

    if row.nil?
      return nil
    else
      vote = Vote.new
      vote.answer_id = row['AnswerId']
      vote.poll_id = row['PollId']
      vote.channel_id = row['ChannelId']
      vote.vote_id = row['Id']
      vote.voter = row['Voter']
      return vote
    end
  end

  def vote_for_user(poll_id, channel_id, user_id, answer_id)
    answer_insert = @db.prepare "INSERT INTO Votes (ChannelId, PollId, AnswerId, Voter) VALUES (?, ?, ?, ?)"
    answer_insert.bind_param 1, channel_id
    answer_insert.bind_param 2, poll_id
    answer_insert.bind_param 3, answer_id
    answer_insert.bind_param 4, user_id
    answer_insert.execute
  end

  def remove_vote_for_user(poll_id, channel_id, user_id)
    answer_insert = @db.prepare "DELETE FROM Votes WHERE ChannelId = ? AND Voter = ? AND PollId = ?"
    answer_insert.bind_param 1, channel_id
    answer_insert.bind_param 2, user_id
    answer_insert.bind_param 3, poll_id
    answer_insert.execute
  end

  def close_poll(poll_id, channel_id)
    update = @db.prepare "UPDATE Polls SET Open = 0 WHERE Id = ? AND ChannelId = ?"
    update.bind_param 1, poll_id
    update.bind_param 2, channel_id
    update.execute
  end

  def stats
    poll_query = @db.prepare "SELECT COUNT(Id) as Count FROM Polls"
    vote_query = @db.prepare "SELECT Count(Id) as Count FROM Votes"

    poll_row = poll_query.execute.first
    vote_row = vote_query.execute.first

    return {
      Polls: poll_row['Count'],
      Votes: vote_row['Count']
    }
  end

  private
  def create_schema()
    @db.execute "CREATE TABLE IF NOT EXISTS Polls(Id INTEGER PRIMARY KEY NOT NULL, ChannelId INTEGER NOT NULL, OwnerId INTEGER NOT NULL, OwnerName TEXT NOT NULL, Question TEXT NOT NULL, Open INTEGER NOT NULL)"
    @db.execute "CREATE TABLE IF NOT EXISTS Answers(Id INTEGER PRIMARY KEY NOT NULL, PollId INTEGER NOT NULL, SortOrder INTEGER NOT NULL, Title TEXT NOT NULL)"
    @db.execute "CREATE TABLE IF NOT EXISTS Votes(Id INTEGER PRIMARY KEY NOT NULL, ChannelId INTEGER NOT NULL, PollId INTEGER NOT NULL, AnswerId INTEGER NOT NULL, Voter INTEGER NOT NULL)"
  end

end
