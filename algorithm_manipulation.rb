def gen_scramble len = 20
  compress((len * 2).times.map {Moves.sample} .join ' ').split[0...len].join ' '
end

def compress_sub algorithm
  final = []
  algorithm.scan(/[UD2' ]+|[RL2' ]+|[FB2' ]+/).each do |group|
    counts = {}
    group.split.each do |move|
      occurrences = case move[1..-1]
      when '' then 1
      when '2' then 2
      when "'" then 3
      end
      if counts.include?(move[0])
        counts[move[0]] += occurrences
      else
        counts[move[0]] = occurrences
      end
    end
    counts.sort.each do |key, count|
      count %= 4
      next if count == 0
      final << key + (count == 1 ? '' : count == 2 ? '2' : "'")
    end
  end
  final.join ' '
end

def compress algorithm
  while true
    saved = algorithm
    algorithm = compress_sub algorithm
    return algorithm if saved == algorithm
  end
end

def reverse algorithm
  algorithm.split.reverse.map {|i| i.length == 1 ? i + "'" : i[1] == "'" ? i[0] : i} .join ' '
end

def _c a # only for face turns
  compress(a).gsub(/[A-Z]'/) {|i| i[0].downcase} .gsub(/[A-Z]2/) {|i| (i[0].ord + 1).chr} .gsub ' ', ''
end

def _d a # only for face turns
  a.split('').join(' ').gsub(/[a-z]/) {|i| i.upcase + "'"} .gsub(/[SMVEGC]/) {|i| (i.ord - 1).chr + '2'}
end

def _ct t # compress ternary ( [k, v] ) containing only face turns
  t0 = t[0].map {|i| i.join} .join ','
  # >
  t1 = ''
  ls = false
  t[1].each do |i|
    if i.is_a? Array
      t1 << i.map {|i| i.join} .join(',')
      ls = false
    elsif i.is_a? String
      if ls
        t1 << ',' + _c(i)
      else
        t1 << (i == '' ? '_' : _c(i))
      end
      ls = true
    else
      raise "unexpected class (#{i.class}) in ternary expression"
    end
  end
  (t0 + '>' + t1).gsub /(\d\d),\1/, '\1k'
end

def _dt t # decompress ternary ( [k, v] ) containing only face turns
  t0, t1 = *t.gsub(/(\d\d)k/, '\1,\1').split('>')
  t0 = t0.split(',').map {|i| i.split('').map &:to_i}
  t1a = []
  t1 = t1.split(/(?=[a-zA-Z_])(?<=\d)|(?=\d)(?<=[a-zA-Z_])|,/).map do |i|
    if i =~ /[a-zA-Z_]/
      i == '_' ? '' : _d(i)
    elsif i =~ /\d/
      i.split('').map &:to_i
    else
      raise "unexpected character found in #{i} in ternary expression"
    end
  end
  la = false
  t1.each do |i|
    if i.is_a? String
      t1a << i
      la = false
    elsif i.is_a? Array
      if la
        t1a[-1] << i
      else
        t1a << [i]
      end
      la = true
    end
  end
  [t0, t1a]
end

def _ci i
  if i[0] == :default_piece
    'd' + i[1].map {|j| j.join} .join(',')
  elsif i[0] == :select
    's' + i[1].join
  else
    raise 'error _ci'
  end
end

def _di i
  if i[0] == 'd'
    [:default_piece, i[1..-1].split(',').map {|j| j.split('').map(&:to_i)}]
  elsif i[0] == 's'
    [:select, i[1..-1].split('').map(&:to_i)]
  else
    raise 'error _di'
  end
end

def _ca h
  # h.to_a.map {|i| i[0].is_a?(Array) ? _ct(i) : i} # FOR SEPARATE STRINGS
  h = h.to_a # see below
  h0 = h.select {|i| i[0].is_a? Symbol} .map {|i| _ci i} .join('|')
  h1 = h.select {|i| i[0].is_a? Array} .map {|i| _ct i} .join('|') # for single long string
  # h.map {|i| i.is_a?(String) ? i.scan(/.{1,81}/).join("\n") : i}
  h0 + '!' + h1
end

def _da h
  # Hash[h.map {|i| i.is_a?(String) ? _dt(i) : i}] # FOR SEPARATE STRINGS
  i, h = *h.split('!')
  Hash[i.split('|').map {|j| _di j}].merge Hash[h.split('|'). map {|i| _dt i}] # for single long string
end

def _cA a
  a.to_a.map {|i| i[0].to_s + '%' + _ca(i[1])}.join '$'
end

def _dA a
  na = {}
  a.split('$').map do |i|
    n, i = *i.split('%')
    na[n.to_sym] = _da(i)
  end
  na
end

def writealgs
  File.open('algfile.txt', 'w+') do |f|
    f.print _cA Algorithms
  end
end
def readalgs
  File.open('algfile.txt', 'r') do |f|
    # _dA(f.gets).each do |k, v|
    #   Algorithms[k] = v
    # end
    Algorithms.replace _dA f.gets
  end
end

MvMap = {
  "u" => "D Y",
  "d" => "U Y'",
  "r" => "L X",
  "l" => "R X'",
  "f" => "B Z",
  "b" => "F Z'",
  "M" => "R L' X'",
  "E" => "U D' Y'",
  "S" => "F' B Z"
}

Rotations = {
  "Y"  => [0,4],
  "Y'" => [0,1],
  "Y2" => [0,2],
  "X"  => [2,0],
  "X'" => [5,3],
  "X2" => [3,2],
  "Z"  => [4,5],
  "Z'" => [1,5],
  "Z2" => [3,5]
}

def interpret algorithm
  # puts algorithm
  algorithm.gsub!(/([udrlfbMES]['2]?)/) do |i|
    move, mod = i[0], i[1..1]
    MvMap[move].split.map {|i| (i + mod).gsub("''", '').gsub "'2", '2'} .join ' '
  end
  # puts algorithm
  new_alg = []
  current = [0,5]
  algorithm.split.each do |i|
    if i =~ /[XYZ]/
      current = transpose_position Rotations[i], [0, 5], current
    else
      new_alg << transpose_moves(i, [0, 5], current)
    end
  end
  compress new_alg.join ' '
end