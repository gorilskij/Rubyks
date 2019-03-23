Ps = [[1,2], [7,6], [3,0], [3,0], [3,0], [7,6]]

P = Hash.new do |h, k|
  edges = k.edges_clockwise.map {|i| i - [k]} .zip([1,5,7,3].rotate [1,5,7,3].index(Ps[k][0]))
  corners = k.corners_clockwise.map {|i| i - [k]} .zip([2,8,6,0].rotate [2,8,6,0].index(Ps[k][1]))
  h[k] = Hash[edges].merge Hash[corners]
end

# M = 'FLDBRU' # U in the middle
M = 'DLBURF' # F in the middle

Colors = 'WGRYBO'
C = Colors.clone # colors
# C = '012345' # numbers