main = putStrLn (show (testFun 10))

testFun 0 = 1
testFun x = testFun (x + 1) - testFun (x*2) 
