require_relative 'definitions'
require_relative 'classes'
require_relative 'mapping'
require_relative 'algorithm_data'
require_relative 'algorithm_manipulation'
require_relative 'color_printer'
require_relative 'patterns'
require_relative 'cube'

# p "R U R U' R' U R' U'".recurrence_time

# p "R U R' U".recurrence_time # 5
# p "R U R' U'".recurrence_time # 6

# p "R' U".recurrence_time # 63
# p "R U".recurrence_time # 105

# p "R U L D'".recurrence_time #420
# p "D' F' R2 L".recurrence_time #840
# p "R B U' L' F' R2 B2 L2 D' L2 B' U F' U B U2 F2 R2 B L2".recurrence_time #1260


# mapping used to be here


# puts Masks[:cross].to_cube
# puts Masks[:face].to_cube
# puts Masks[:f2l].to_cube
# puts Masks[:solved].to_cube

=begin
 # TO BE USED LATER FOR BETTER (SHORTER) OLL / PLL ALGORITHMS

def oll_see perm
  bottom, front = 0, 5
  cc = Cube.new.permutate perm
  pieces = cc.pieces.select {|i| i[0].include? bottom.opposite} .map {|i| t_piece i, [bottom, front], [0,5]}
  r = []
  # 3.pieces_clockwise.map {|i| resort(*pieces.find {|j| j[1].sort == i}) [0]} .flatten.each_with_index {|v, i| r << i if v == 3}
  3.pieces_clockwise.map {|i| pieces.map {|j| resort(*j.reverse)} .assoc(i)[1]} .flatten.each_with_index {|v, i| r << i if v == 3}
  return r
end

def pll_see perm
  cc = Cube.new.permutate perm
  bottom = 0
  front = 5
  pieces = cc.pieces.select {|i| i[0].include? bottom.opposite} .map {|i| t_piece i, [bottom, front], [0,5]}
  positions = 3.pieces_clockwise.map {|i| pieces.assoc(i)[1].sort}
  positions.map {|i| 3.pieces_clockwise.index i}
end
=end # << important


# TERMINAL SETUP
def in_terminal?
  ENV['TERM'] or defined? IRB
end

puts "\n\e[#105m ! PINK = ORANGE ! \e[0m\n" if in_terminal?

## RECALCULATE AT EVERY MOVE #######################################################################

# VERRY INTERESTING, FIRST MOVE SHAVES OFF 5 MOVES AND INFINITE LOOP IS REACHED
# scramble = "D B' R D2 U' L' R2 F2 U B' L2 B U F' U' B2 D2 U' L D2"

# ONLY 2 JUMPS, OTHERWISE REGULAR
# scramble = "U' F L2 F L2 B2 F U B U' F2 D2 B' R' D U R D2 F2 L'"

# scramble = gen_scramble
#
# puts scramble
# puts
#
# c = Cube.new.permutate! scramble
#
# until c.solved?
#   current_solve = c.solve_alg
#   puts "#{current_solve.split.length.to_s.ljust 3}#{current_solve}"
#   c.permutate! current_solve.split[0]
# end

## SOLVE FROM INPUT ################################################################################

c = Cube.new.input Patterns[:cube_in_a_cube_in_a_cube]
puts "your scramble:\n\t#{c.antisolve}"
puts in_terminal? ? c.in_color : c
puts "the solve:\n\t#{c.solve!}"
puts in_terminal? ? c.in_color : c

# puts Cube.new.permutate reverse "F R U R' U' R U R' U' R U' R' U' R U R' F'"

####################################################################################################

__END__
# other testing stuff

NUMBER_OF_SCRAMBLES = 100

scrambles = NUMBER_OF_SCRAMBLES.times.map {gen_scramble 50}
puts "scrambles done"

every = scrambles.length / 10

w = 50
i = 0
times = []
lengths = []
clengths = []

# require 'profile'

scrambles.each_with_index do |s, index|
  puts "cache warmup" if index == 0
  puts "measuring" if index == w
  f = rand 6
  c = Cube.new.permutate(s)
  start = Time.new if index >= w
  begin
    # r = c.solve_cf! :cross, f
    # rf = c.solve_cf! :f2l, f
    # ro = c.solve_ol! f
    # rp = c.solve_pl! f
    r = c.solve!
    times << Time.new - start if index >= w
  rescue Exception => e
    warn s, f unless e.is_a? Interrupt
    raise e
  end
  puts i.to_s.rjust (NUMBER_OF_SCRAMBLES - 1).to_s.length if i % every == 0
  raise s, f unless c.mask? transpose Masks[:solved], f
  i += 1
  lengths << r.split.length # already compressed
end
puts "average time: #{((times.inject{ |sum, el| sum + el }.to_f / times.length) * 1000).round 3}ms"
puts "average length: #{lengths.inject{ |sum, el| sum + el }.to_f / lengths.length}"
puts "max length: #{lengths.max}"
puts "min length: #{lengths.min}"