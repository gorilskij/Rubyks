class Integer
  def opposite
    (self + 3) % 6
  end

  def adjacent
    [-2, -1, 1, 2].map {|o| (self + o) % 6} .sort
  end

  def adjacent_clockwise
    even? ? adjacent.sort.reverse : adjacent.sort
  end

  def edges
    adjacent.map {|a| [a, self].sort}
  end

  def edges_clockwise
    adjacent_clockwise.map {|a| [a, self].sort}
  end

  def corners
    4.times.map {|i| [self, adjacent[i], adjacent[(i + 1) % 4]].sort}
  end

  def corners_clockwise
    4.times.map {|i| [self, adjacent_clockwise[i], adjacent_clockwise[(i + 1) % 4]].sort}
  end

  def pieces
    [*edges, *corners]
  end

  def pieces_clockwise
    [edges_clockwise, corners_clockwise].transpose.flatten 1
  end

  def to_color
    C[self]
  end

  def cube_equals other
    self == -1 || other == -1 ? true : self == other
  end

  def dh6
    [self % 6, (self / 6).floor]
  end
end

class NilClass
  def to_color
    '?'
  end
  def to_str
    ''
  end
end

class Array
  def to_cube
    Cube.new self
  end

  def ternary_eval
    index = 0
    index += 2 until (index >= length - 1) || yield(self[index])
    return self[index + 1] unless index == length - 1
    last
  end

  def h6
    self[0] + self[1]*6
  end
end

# puts ['true', 0, 'true', 1, 2].ternary_eval {|i| i == 'true'}

class String
  def recurrence_time
    c = Cube.new
    i = 0
    begin
      i += 1
      c.permutate! self
    end until c.solved?
    i
  end
end