ANSIcolors = {
  "R" => 101,
  "G" => 102,
  "Y" => 103,
  "B" => 104,
  "O" => 105,
  "W" => 107
}

class String
  def tint
    "\e[#{ANSIcolors[self]}m  \e[0m"
  end
end

class Cube
  def in_color
    canvas = ([nil]*6).map {[nil]*9}
    canvas.each_with_index do |f, i|
      canvas[i][4] = i
      @pieces.each do |c|
        [*i.edges, *i.corners].each do |e|
          if c[1].sort == e
            canvas[i][P[i][(c[1] - [i]).sort]] = c[0][c[1].index i]
          end
        end
      end
    end
    cs = ''
    [0, 3, 6].each do |i|
      cs += ' '*14 + canvas[3][i..i+2].map(&:to_color).map(&:tint).join('  ') + "\n\n"
    end
    cs += "\n"
    [0, 3, 6].each do |i|
      [1, 5, 4, 2].each do |f|
        cs += canvas[f][i..i+2].map(&:to_color).map(&:tint).join('  ') + '    '
      end
      cs += "\n\n"
    end
    cs += "\n"
    [0, 3, 6].each do |i|
      cs += ' '*14 + canvas[0][i..i+2].map(&:to_color).map(&:tint).join('  ') + "\n\n"
    end
    "\n" + cs + "\n"
  end
end