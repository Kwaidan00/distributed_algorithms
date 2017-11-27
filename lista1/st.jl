# Algorytmy rozproszone
# Lista 1

# Aleksander Spyra

# MODEL
# Każdy wierzchołek to procesor z unikalnym UID
# parent = 0
# children = 0
#
# root (i0)
# root sends its ID to N(i0)

# Rest of nodes:
# 1. if w received message for the first time from v
#    a) it sends "you are my father" to v
#    b) set parent <- v
#    c) send message to N(w)
# 2. if w received "you are my parent" from v
#    a) chilren = children \cup {w}

type Node
  uid::Int64

  leader::Bool
  neighbourhood::Set{Int64}
  parent::Int64
  childrens::Array{Int64}

  rootFunction::Function
  nodeFunction::Function
  setLeader::Function
  addToNeighbourhood::Function


  function Node(id::Int64)
    this = new()
    this.uid = id
    this.leader = false
    this.parent = 0
    this.childrens = []
    this.neighbourhood = Set{Int64}()

    this.setLeader = function ()
      this.leader = true
    end
    this.rootFunction = function (channels::Array{Channel{Tuple{Symbol, Int}}})
      # root wysyła swoje ID to wszystkich swoich sąsiadów
      if this.leader
        for id in this.neighbourhood
          put!(channels[id], (:search, this.uid))
        end
        rMsg = 0
        eMsg = 2*length(this.neighbourhood)
        while rMsg < eMsg
          (msg, senderId) = take!(channels[this.uid])
          rMsg += 1
          if msg == :youaremyfather
            push!(this.childrens, senderId)
          elseif msg == :search
            put!(channels[senderId], (:goaway, this.uid))
          end
        end #while

      end
    end
    this.nodeFunction = function (channels::Array{Channel{Tuple{Symbol, Int}}})
      if !this.leader
        rMsg = 0
        eMsg = 2*length(this.neighbourhood)
        while rMsg < eMsg
          (msg, senderId) = take!(channels[this.uid])
          rMsg += 1
          if msg == :search
            if this.parent == 0
              this.parent = senderId
              put!(channels[senderId], (:youaremyfather, this.uid))
              for id in this.neighbourhood
            #    if id != senderId
                  put!(channels[id], (:search, this.uid))
            #    end
              end
            else
              put!(channels[senderId], (:goaway, this.uid))
            end
          elseif msg == :youaremyfather
            push!(this.childrens, senderId)
          end
        end # while
      end
    end
    this.addToNeighbourhood = function (neighbour::Int64)
      push!(this.neighbourhood, neighbour)
    end
    return this
  end

end


n = 5
testRange = 1:n
nodes = []
for i in testRange
  push!(nodes, Node(i))
end

#     1 - 2 - 4
#      \  |   |
#       3 --- 5
nodes[1].addToNeighbourhood(2)
nodes[1].addToNeighbourhood(3)
nodes[2].addToNeighbourhood(1)
nodes[2].addToNeighbourhood(3)
nodes[2].addToNeighbourhood(4)
nodes[3].addToNeighbourhood(1)
nodes[3].addToNeighbourhood(2)
nodes[3].addToNeighbourhood(5)
nodes[4].addToNeighbourhood(2)
nodes[4].addToNeighbourhood(5)
nodes[5].addToNeighbourhood(3)
nodes[5].addToNeighbourhood(4)

nodes[1].setLeader()

channels = [Channel{Tuple{Symbol, Int}}(n) for i=1:n]

@sync for i in 1:n
  if nodes[i].leader
    @async nodes[i].rootFunction(channels)
  else
    @async nodes[i].nodeFunction(channels)
  end
end
