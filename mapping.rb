# mapping, projection and transposition

Mapto = Hash.new do |hash, key|
  s = (key / 6).adjacent_clockwise
  hash[key] = Hash[s.zip s.rotate(key % 6)]
end

def projection down_front
  # down_front = [down face, front face]
  mid = down_front[0].adjacent_clockwise
  [down_front[0], * mid.rotate(mid.index(down_front[1]) - 1), down_front[0].opposite]
end

Projection = Hash.new do |h, k|
  h[k] = projection k.dh6
end

def resort s, m, to_sort = 0
  # to_sort = true / false ?
  # puts "ONE" if to_sort == 1
  s, m = m, s if to_sort == 1
  r = [s.sort, s.map.with_index.sort.map(&:last).map {|i| m[i]}]
  #            s.each_with_index...
  to_sort == 0 ? r : r.reverse
end

def transpose_face face, from_DF = [0, 5], to_DF
  #5 -> 1
  dep = Projection[from_DF.h6]
  des = Projection[to_DF.h6]
  des[dep.index face]
  # Projection[to_DF.h6][Projection[from_DF.h6].index face]
end

def transpose_position position, from_DF = [0, 5], to_DF
  #[0,5] -> [0,1]
  position.map {|f| transpose_face f, from_DF, to_DF}
end

def transpose_piece piece, from_DF = [0, 5], to_DF
  #[[0,5], [0,1]] -> [[0,1], [0,2]]
  piece = piece[0].clone, piece[1].clone
  dep = Projection[from_DF.h6]
  des = Projection[to_DF.h6]
  t = piece.map {|rt|
    rt.map {|n|
      des[dep.index n]
    }
  }
  resort *t
end

def transpose_moves algorithm, from_DF = [0, 5], to_DF
  puts "THREE" if to_DF.length == 3
  from_DF = [0,4,5] if to_DF.length == 3
  dep = Projection[from_DF.h6]
  des = Projection[to_DF.h6]
  algorithm.split.map {|move|
    m, d = move[0], move[1..-1]
    M[des[dep.index M.index m.upcase]] + d
  } .join ' '
end

def transpose pcs, face
  return pcs if face == 0
  
  pcs.map do |pc|
    t = pc.map do |rt|
      rt.map do |n|
        ([-1, face, face.opposite] + face.adjacent_clockwise)[([-1, 0, 0.opposite] + 0.adjacent_clockwise).index n]
      end
    end
    resort *t
  end
end