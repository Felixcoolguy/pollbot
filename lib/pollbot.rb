require 'discordrb'
require 'dotenv'
require_relative 'pollbot/poll'
require_relative 'pollbot/database'

Dotenv.load

database = Database.new("pollbot.db")

bot = Discordrb::Commands::CommandBot.new token: ENV['TOKEN'], application_id: ENV['CLIENT_ID'], prefix: "!"
puts "This bot's invite URL is #{bot.invite_url}."

p = database.find_poll(225505218568126464)

def display_poll_results(event, title, poll)
  output = "#{title}"
  poll.results.each do |l|
    output = "#{output}\n#{l}"
  end
  event.respond output
  return
end

bot.command(:poll, chain_usable: false, description: "Start a poll") do |event, *arguments|
  poll = database.find_poll(event.channel.id)

  if poll.nil?
    if arguments.length > 0
      poll = database.create_poll(event.channel.id, event.user, arguments)
      if poll.nil?
        event.respond "<@#{event.user.id}> I can't make a poll of that"
      else
        display_poll_results(event, "New poll by #{event.user.username}: `#{poll.question}`", poll)
        event.respond "You can vote by calling `!vote <number>`"
      end
    else
      event.respond "<@#{event.user.id}> There currently is no poll running"
    end
  else
    if arguments.length > 0
      event.respond "<@#{event.user.id}> Sorry, only one poll per channel"
    end
    display_poll_results(event, "Poll by #{poll.owner_name}: `#{poll.question}`", poll)
    event.respond "You can vote by calling `!vote <number>`"
  end
  return
end

bot.command(:vote, chain_usable: false, description: "Vote for an option in a poll") do |event, answer_index|
  poll = database.find_poll(event.channel.id)

  if poll.nil?
    event.respond "<@#{event.user.id}> Sorry, but there is no poll open at the moment. Start one using `!poll <question>, <option 1>, <option 2>, etc`"
  else
    vote = database.find_vote_for_user(poll.poll_id, event.channel.id, event.user.id)

    if answer_index.nil?
      if vote.nil?
        event.respond "<@#{event.user.id}> You haven't voted in this poll yet"
      else
        answer = poll.answer_for_vote(vote.answer_id)
        if !answer.nil?
          event.respond "<@#{event.user.id}> You voted for `#{answer.title}`"
        end
      end
    else
      if answer_index.to_i < 1 || answer_index.to_i > poll.answers.count
        event.respond "<@#{event.user.id}> Invalid vote, you can vote 1 - #{poll.answers.count}"
      else
        if !vote.nil?
          database.remove_vote_for_user(poll.poll_id, event.channel.id, event.user.id)
        end

        answer = poll.answers[answer_index.to_i - 1]
        database.vote_for_user(poll.poll_id, event.channel.id, event.user.id, answer.answer_id)
      end
    end
  end
  poll = database.find_poll(event.channel.id)
  display_poll_results(event, "Current poll results for `#{poll.question}`", poll)
  return
end

bot.command(:close_poll, chain_usable: false, description: "This will close a poll") do |event|
  poll = database.find_poll(event.channel.id)

  if poll.nil?
    event.respond "<@#{event.user.id}> There is no poll open at the moment"
  else
    if poll.owner_id == event.user.id || event.user.id == ENV["OWNER_ID"]
      event.respond "The poll is now closed"
      display_poll_results(event, "Final poll results for `#{poll.question}`", poll)
      database.close_poll(poll.poll_id, event.channel.id)
    else
      event.respond "<@#{event.user.id}> You are not allowed to close this poll, only #{poll.owner_name} can."
    end
  end
  return
end

bot.command(:close_polls, chain_usable: false, description: "Closes down this bot") do |event|
  if event.user.id == ENV['OWNER_ID']
    event.respond "Pollbot is going down..."
    exit
  end
end

bot.command(:stats, chain_usable: false, description: "Show stats of Pollbot") do |event|
  stats = database.stats
  event.respond "We hosted #{stats[:Polls]} polls, with #{stats[:Votes]} votes"
  return
end

bot.run
