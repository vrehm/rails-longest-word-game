class GameController < ApplicationController
  require 'open-uri'
  require 'json'

  def grid
    @start_time = Time.now
    @grid = generate_grid(9)
  end

  def score
    @end_time = Time.now.to_i
    @start_time = Time.parse(params[:start_time]).to_i
    @grid = params[:grid].split("")
    @proposition = params[:proposition]
    @result = run_game(@proposition, @grid, @start_time, @end_time)
  end

  def generate_grid(grid_size)
    # vowel_frequency_cumulated = 0.3977
    vowel_frequency = 0.3
    vowels = ['A', 'E', 'I', 'O', 'U']
    consonants = ['B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'Y', 'Z']
    Array.new(grid_size) { rand > vowel_frequency ? consonants[rand(21)] : vowels[rand(5)] }
  end

  def included?(guess, grid)
    the_grid = grid.clone
    guess.chars.each do |letter|
      the_grid.delete_at(the_grid.index(letter)) if the_grid.include?(letter)
    end
    grid.size == guess.size + the_grid.size
  end

  def compute_score(attempt, time_taken)
    (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time - start_time }

    result[:translation] = get_translation(attempt)
    result[:score], result[:message] = score_and_message(
      attempt, result[:translation], grid, result[:time])

    result
  end

  def score_and_message(attempt, translation, grid, time)
    if translation
      if included?(attempt.upcase, grid)
        score = compute_score(attempt, time)
        [score, "well done"]
      else
        [0, "not in the grid"]
      end
    else
      [0, "not an english word"]
    end
  end

  def get_translation(word)
    response = open("http://api.wordreference.com/0.8/80143/json/enfr/#{word.downcase}")
    json = JSON.parse(response.read.to_s)
    json['term0']['PrincipalTranslations']['0']['FirstTranslation']['term'] unless json["Error"]
  end
end
