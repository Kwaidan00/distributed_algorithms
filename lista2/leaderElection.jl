# Distributed Algorithms
# Assignment 2

# Aleksander Spyra

# Leader election algorithm on the ring topology network with n processors. For each node v:
#   Input: list of v neighbours
#   Output: id of the chosen leader

# From the lectures.
# Deterministic solutions for LE.

# Assumption: Each node has an unique ID (UID).
# 1. Ring undirectional
#  UID of each processor is sent to neighbour
#  if UID > myUID
#    pass on it
#  if UID < myUID
#    discard it
#  if UID == myUID
#    I'm a leader!
#
#  Analysis:
#    Time: n
#    Total number of messages: O(n^2)
#
# 2. Two-way passing way model
# http://compalg.inf.elte.hu/~tony/Informatikai-Konyvtar/03-Algorithms%20of%20Informatics%201,%202,%203/Distributedf29May.pdf
# (p. 13)



type Node
  uid::Int64

  leader::Bool
  asleep::Bool
  CWreplied::Bool
  CCWreplied::Bool

  neighbourhood::Set{Int64}

  nodeFunction::Function
  addToNeighbourhood::Function

  function Node(uid::Int64)
    this = new()
    this.uid = uid
    this.leader = false
    this.neighbourhood = Set{Int64}()
    this.asleep = true
    this.CWreplied = false
    this.CCWreplied = false

    this.nodeFunction = function (channels::Array{Channel{Tuple{Symbol, Int, Int, Int}}})
      if this.asleep
        asleep = false
      #  send <probe, id, 0, 0> to links CW and CCW
      end

    end

    this.addToNeighbourhood = function (neighbour::Int64)
      if length(this.neighbourhood) < 2
        push!(this.neighbourhood, neighbour)
      end
    end
    return this
  end

end


# Assumption:
# An array of nodes determinates a ring topology:
#   ...-n-1-2-3-... etc.
function createRing(n::Int64) :: Vector{Node}
  function getLeftNeighbour(i::Int64) :: Int64
    index = i + 1
    if index > n
      index = 1
    end
    return index
  end
  function getRightNeighbour(i::Int64) :: Int64
    index = i - 1
    if index < 1
      index = n
    end
    return index
  end

  nodes = Vector{Node}()
  for j in 1:n
    randUID = rand(1:1000)
    push!(nodes, Node(randUID))
    nodes[j].addToNeighbourhood(getRightNeighbour(j))
    nodes[j].addToNeighbourhood(getLeftNeighbour(j))
  end
  return nodes
end

createRing(10)

channels = [Channel{Tuple{Symbol, Int, Int, Int}}(n) for i=1:n]
