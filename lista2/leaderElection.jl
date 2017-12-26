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
#
# Message complexity: O(n logn)



type Node
  uid::Int64

  leader::Bool
  asleep::Bool
  CWreplied::Bool
  CCWreplied::Bool
  leaderIsNil::Bool

  myPosition::Int64
  leftNeighbour::Int64
  rightNeighbour::Int64

  nodeFunction::Function
  addToNeighbourhood::Function

  function Node(uid::Int64, myPosition::Int64, left::Int64, right::Int64)
    this = new()
    this.uid = uid
    this.leader = false
    this.leaderIsNil = true
    this.asleep = true
    this.CWreplied = false
    this.CCWreplied = false
    this.myPosition = myPosition
    this.leftNeighbour = left
    this.rightNeighbour = right

    this.nodeFunction = function (channels::Array{Channel{Tuple{Symbol, Int, Int, Int, Symbol}}})
      if this.asleep
        asleep = false
      #  send <probe, id, 0, 0> to links CW and CCW
        put!(channels[this.rightNeighbour], (:probe, this.uid, 0, 0, :right))
        put!(channels[this.leftNeighbour], (:probe, this.uid, 0, 0, :left))
      end

      shouldITerminate = false

      function passMsg(msgType, ids, phase, ttl, direction)
        put!(channels[direction == :left ? this.leftNeighbour : this.rightNeighbour], (msgType, ids, phase, ttl, direction))
      end
      function turnBackMsg(msgType, ids, phase, ttl, direction)
        put!(channels[direction == :left ? this.rightNeighbour : this.leftNeighbour], (msgType, ids, phase, ttl, direction == :left ? :right : :left))
      end

      while !shouldITerminate
        (msgType, ids, phase, ttl, direction) = take!(channels[this.myPosition])
        if msgType == :probe
          if this.uid == ids && this.leaderIsNil
            # send terminate to link CCW
            put!(channels[this.leftNeighbour], (:terminate, this.uid, -1, -1, :left))
            this.leader = true
            this.leaderIsNil = false
            shouldITerminate = true
          elseif ids > this.uid && ttl > 0
            # Pass the msg
            # send <probe, ids, phase, ttl−1>to link CCW (resp. CW)
            passMsg(:probe, ids, phase, ttl-1, direction)
            #put!(channels[direction == :left ? this.leftNeighbour : this.rightNeighbour], (:probe, ids, phase, ttl-1, direction))
          elseif ids > this.uid && ttl == 0
            turnBackMsg(:reply, ids, phase, ttl, direction)
            #put!(channels[direction == :left ? this.rightNeighbour : this.leftNeighbour], (:reply, ids, phase, ttl, direction == :left ? :right : :left))
          end
        end # of probe
        if msgType == :reply
          if ids != this.uid
            passMsg(msgType, ids, phase, ttl, direction)
          else
            if direction == :left
              this.CWreplied = true
            else
              this.CCWreplied = true
            end
            if this.CWreplied && this.CCWreplied
              this.CWreplied = false
              this.CCWreplied = false
              put!(channels[this.rightNeighbour], (:probe, this.uid, phase+1, 2^(phase+1) - 1, :right))
              put!(channels[this.leftNeighbour], (:probe, this.uid, phase+1, 2^(phase+1) - 1, :left))
            end
          end
        end # of reply
        if msgType == :terminate
          if this.leaderIsNil
            passMsg(:terminate, ids, phase, ttl, direction)
            this.leader = false
            this.leaderIsNil = false
            shouldITerminate = true
          end
        end # of terminate
      end #while
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
    push!(nodes, Node(randUID, j, getLeftNeighbour(j), getRightNeighbour(j)))
  end
  return nodes
end


function ringLE(n::Int64) :: Int64
  nodes = createRing(n)
  channels = [Channel{Tuple{Symbol, Int, Int, Int, Symbol}}(n) for i=1:n]
  @sync for i in 1:n
    @async nodes[i].nodeFunction(channels)
  end
  for i in 1:n
    if nodes[i].leader
      return nodes[i].uid
    end
  end
end

ringLE(10)
