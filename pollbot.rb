require 'discordrb'
require 'dotenv'
require './lib/poll'

Dotenv.load

bot = Discordrb::Commands::CommandBot.new token: ENV['TOKEN'], application_id: ENV['CLIENT_ID'], prefix: "!"
puts "This bot's invite URL is #{bot.invite_url}."
polls = Array.new

def display_poll_results(event, title, poll)
  event.respond title
  poll.results.each do |l|
    event.respond l
  end
end

bot.command(:poll, chain_usable: false, description: "Start a poll") do |event, *arguments|
  @poll = polls.find { |p| p.channel_id == event.channel.id }

  if @poll.nil?
    if arguments.length > 0

      @poll = Poll.create(event.channel.id, event.user, arguments)
      if @poll.nil?
        event.respond "I can't make a poll of that"
      else
        polls.push(@poll)
        display_poll_results(event, "New poll by #{event.user.username}: `#{@poll.question}`", @poll)
        event.respond "You can vote by calling `!vote <number>`"
      end
    else
      event.respond "There currently is no poll running"
    end
  else
    if arguments.length > 0
      event.respond "Sorry, only one poll per channel"
    end
    display_current_poll(event, "Poll by #{@poll.owner.name}: `#{@poll.question}`", @poll)
    event.respond "You can vote by calling `!vote <number>`"
  end
  return
end

bot.command(:vote, chain_usable: false, description: "Vote for an option in a poll") do |event, arguments|
  @poll = polls.find { |p| p.channel_id == event.channel.id }

  if @poll.nil?
    event.respond "Sorry, but there is no poll open at the moment. Start one using `!poll <question>, <option 1>, <option 2>, etc`"
  else
    event.respond @poll.vote(event.user.id, arguments)
    display_poll_results(event, "Current poll results for `#{@poll.question}`", @poll)
  end

  return
end

bot.command(:close_poll, chain_usable: false, description: "This will close a poll") do |event|
  poll = polls.find { |p| p.channel_id == event.channel.id }
  if poll.nil?
    event.respond "There is no poll open at the moment"
  else
    if poll.owner.id == event.user.id
      event.respond "The poll is now closed"
      display_poll_results(event, "Final poll results for `#{poll.question}`", poll)
      polls.delete(poll)
    else
      event.respond "You are not allowed to close this poll, only #{poll.owner.username} can."
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

bot.run
