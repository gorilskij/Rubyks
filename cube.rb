class Cube
  # Solved = []
  # 6.times do |f|
  #   f.pieces.each do |c|
  #     Solved << [c, c.clone]
  #   end
  # end
  # Solved.uniq!.sort!
  Solved = 6.times.flat_map {|f| f.pieces.map {|c| [c, c.clone]}} .uniq.sort
  
  def initialize pieces = Solved, static = false
    @pieces = pieces.map {|pc| pc.map &:clone}
    @static = static
    @trust_hash = @pieces.sort.hash if static
  end
  
  def input faces
    faces.map! {|i| i.split('').map {|j| Colors.index j}}
    faces.sort_by! {|i| i[4]}
    pieces = []
    faces.each do |f|
      face = f[4]
      f.each_with_index do |v, i|
        next if i == 4
        places = [face] + P[face].key(i)
        positions = places.map {|of| faces[of][P[of][(places - [of]).sort]]}
        unless pieces.assoc positions.sort
          pieces << resort(positions, places)
        end
      end
    end
    Cube.new pieces
  end
  
  def input! faces
    initialize input(faces).pieces
  end
  
  def turn_clockwise! face, times = 1
    @pieces.select {|pc| pc[1].include? face} .each {|pc|
      pc[1].map! {|i| i == face ? i : Mapto[face * 6 + times][i]}
    }
  end
  
  def permutate! code
    # raise "invalid moves: #{code.delete("UDFBRL2' ").split('').uniq.sort.join ', '}" if code.delete("UDFBRL2' ").length != 0
    code.split.each do |m|
      turn_clockwise! M.index(m[0]), m.length == 2 ? m[1] == "'" ? 3 : 2 : 1
    end
    self
  end
  
  def permutate code
    clone.permutate! code
  end
  
  # def == other
  #   @pieces == other.pieces
  # end
  
  def clone
    Cube.new @pieces
  end
  
  def solved?
    #mask? Solved
    @pieces == Solved
  end
  
  # def strict_mask? pcs
  #   pcs.each do |c|
  #     unless @pieces.include? c
  #       return false
  #     end
  #   end
  #   true
  # end
  
  def mask? *masks
    masks.each do |pcs|
      # pcs = [[piece, position], ...]
      pcs.each do |c|
        # p c
        piece = @pieces.assoc(c[0])
        next unless piece
        piece[1].each_with_index do |m, i|
          return false unless m.cube_equals c[1][i]
        end
      end
    end
    true
  end
  
  def == other
    return false unless other.class == Cube
    (other.static ? other.trust_hash : other.pieces.sort.hash) == (@static ? @trust_hash : @pieces.sort.hash)
  end
  
  attr_accessor :static, :trust_hash
  
  def scramble! len = 10
    s = gen_scramble len
    permutate! s
    s
  end
  
  def scramble len = 10
    clone.scramble! len
  end
  
  def reach *masks
    max_moves = masks.delete masks.find {|i| i.class == Integer}
    # p masks[0]
    i = 0
    while true
      puts "checking #{i} moves"
      Moves.repeated_permutation(i).each_with_index do |a, i|
        puts i if i % 10_000 == 0 and i != 0
        return a.join ' ' if permutate(a.join ' ').mask? *masks
      end
      if max_moves and i == max_moves
        puts "stopping: checked up to #{i} moves"
        return nil
      end
      i += 1
    end
  end
  
  def solve_cf_alg what, bottom = 0
    centerpiece = Algorithms[what][:default_piece]
    cpls = centerpiece.first.class == Array ? centerpiece.map(&:length) : [centerpiece.length]
    cpml = cpls.max
    mandatory = transpose_position(Algorithms[what][:select], [bottom, bottom.adjacent[0]])
    algs = []
    bottom.adjacent.permutation do |order|
      working = clone
      order_alg = []
      order.each_with_index do |front, index|
        pieces = working.pieces.select {|i| cpls.include?(i[0].length) and (i[0] & mandatory).any?} .map {|j| transpose_piece j, [bottom, front], [0, 5]}
        position = centerpiece.map {|i| pieces.assoc(i)[1]}
        alg = Algorithms[what][position].ternary_eval {|pcs| pcs.index {|pc| pieces.include? [pc]*2}}
        alg = transpose_moves alg, [bottom, front]
        order_alg.push *alg.split
        working.permutate! alg
      end
      algs << compress(order_alg.join ' ')
    end
    algs.min {|a, b| a.split.length <=> b.split.length}
  end
  
  def solve_cf_alg_dump what, bottom = 0
    centerpiece = Algorithms[what][:default_piece]
    cpls = centerpiece.first.class == Array ? centerpiece.map(&:length) : [centerpiece.length]
    cpml = cpls.max
    mandatory = transpose_position(Algorithms[what][:select], [bottom, bottom.adjacent[0]])
    possible = get_dump Algorithms[what]
    algs = []
    bottom.adjacent.permutation do |order|
      working = clone
      order_alg = []
      order.each_with_index do |front, index|
        pieces = working.pieces.select {|i| cpls.include?(i[0].length) and (i[0] & mandatory).any?} .map {|j| transpose_piece j, [bottom, front], [0, 5]}
        goal_mask = 0.adjacent.flat_map {|adj| centerpiece.map {|piece| [transpose_position(piece, [0, 5], [0, adj])]*2}} .select {|i| centerpiece.include? i[0] or pieces.include? i}
        alg = get_dump(Algorithms[what]).find {|i| Cube.new(pieces).permutate(i).mask? goal_mask}
        alg = transpose_moves alg, [bottom, front]
        order_alg.push *alg.split
        working.permutate! alg
      end
      algs << compress(order_alg.join ' ')
    end
    algs.min {|a, b| a.split.length <=> b.split.length}
  end

  def solve_cf! *a
    moves = solve_cf_alg *a
    permutate! moves
    moves
  end

  def solve_cf *a
    c = clone
    c.solve_cf! *a
    c
  end

  def solve_ol_alg bottom = 0
    bottom.adjacent.each do |front|
      pieces = @pieces.select {|i| i[0].include? bottom.opposite} .map {|i| transpose_piece i, [bottom, front], [0, 5]} .map {|j| resort(*j.reverse)}
      code = []
      3.pieces_clockwise.map {|i| pieces.assoc(i)[1]} .flatten.each_with_index {|v, i| code << i if v == 3}
      if Algorithms[:oll].include? code
        return transpose_moves Algorithms[:oll][code], [bottom, front]
      end
    end
  end
  
  def solve_ol! *a
    moves = solve_ol_alg *a
    permutate! moves
    moves
  end
  
  def solve_ol *a
    c = clone
    c.solve_ol! *a
    c
  end
  
  def solve_pl_alg bottom = 0
    bottom.adjacent.each do |front|
      pieces = @pieces.select {|i| i[0].include? bottom.opposite} .map {|i| transpose_piece i, [bottom, front], [0, 5]}
      code = 3.pieces_clockwise.map {|i| pieces.assoc(i)[1].sort} .map {|i| 3.pieces_clockwise.index i}
      4.times do |rot|
        rot *= 2
        if Algorithms[:pll].include? code.rotate rot
          return transpose_moves(Algorithms[:pll][code.rotate rot], [bottom, front]) + " #{M[bottom.opposite]}"*(rot / 2)
        end
      end
    end
  end
  
  def solve_pl! *a
    moves = solve_pl_alg *a
    permutate! moves
    moves
  end
  
  def solve_pl *a
    c = clone
    c.solve_pl! *a
    c
  end
  
  def solve_alg
    algs = []
    6.times do |s_f|
      alg = []
      c = clone
      alg << c.solve_cf!(:cross, s_f)
      alg << c.solve_cf!(:f2l, s_f)
      alg << c.solve_ol!(s_f)
      alg << c.solve_pl!(s_f)
      algs << compress(alg.join ' ')
    end
    algs.min {|a, b| a.split.length <=> b.split.length}
  end
  
  def solve!
    moves = solve_alg
    permutate! moves
    moves
  end
  
  def solve
    c = clone
    c.solve!
    c
  end
  
  def antisolve
    reverse solve_alg
  end
  
  def to_s
    canvas = ([nil]*6).map {[nil]*9}
    canvas.each_with_index do |f, i|
      canvas[i][4] = i
      @pieces.each do |c|
        i.pieces.each do |e|
          if c[1].sort == e
            canvas[i][P[i][(c[1] - [i]).sort]] = c[0][c[1].index i]
          end
        end
      end
    end
    cs = ''
    [0, 3, 6].each do |i|
      cs += ' '*7 + canvas[3][i..i+2].map(&:to_color).join(' ') + "\n"
    end
    cs += "\n"
    [0, 3, 6].each do |i|
      [1, 5, 4, 2].each do |f|
        cs += canvas[f][i..i+2].map(&:to_color).join(' ') + '  '
      end
      cs += "\n"
    end
    cs += "\n"
    [0, 3, 6].each do |i|
      cs += ' '*7 + canvas[0][i..i+2].map(&:to_color).join(' ') + "\n"
    end
    "\n" + cs + "\n"
  end
  
  attr_reader :pieces
end