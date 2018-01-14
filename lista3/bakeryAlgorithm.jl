# Aleksander Spyra

# Lamport's Bakery algorithm

# Due to problem with preemption in Julia environment, at each moment process
# gives a chance for the Julia's threads scheduler to decide, which thread should
# work now.

numberOfThreads = 4
entering = SharedArray{Bool}(numberOfThreads)
number = SharedArray{Int}(numberOfThreads)

@everywhere function bakeryLock(i::Int)
  entering[i] = true
  yield()
  number[i] = 1 + maximum(number)
  yield()
  entering[i] = false
  for j in 1:numberOfThreads
    yield()
    if j == i
      continue
    end
    while entering[j]
      yield()
    end
    yield()
    while number[j] != 0 && (  number[j] < number[i] || ( number[j] == number[i] && j < i )  )
      yield()
    end
  end
end

@everywhere function bakeryUnlock(i::Int)
  number[i] = 0
end

@everywhere function cs(nu::Int)
  println("cs: $(nu)")
end

@everywhere function bakeryThread(id::Int)
  for l in 1:3
    yield()
    bakeryLock(id)
    cs(id)
    bakeryUnlock(id)
  end
end


@sync for k in 1:numberOfThreads
  @async bakeryThread(k)
end
