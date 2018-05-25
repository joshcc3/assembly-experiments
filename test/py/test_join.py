import time
from threading import Thread


def thread1():
  print "Thread1 sleeping"
  time.sleep(10)
  print "Thread 1 exiting"

def thread2(t):
  time.sleep(5)
  print "Waiting on thread1 to finish"
  t.join()
  print "Thread 2 quitting"

def thread3():
  t = Thread(target=thread1)
  t2 = Thread(target=thread2, args=(t,))
  t.start()
  t2.start()
  print "Thread 3 dying"

thread3 = Thread(target=thread3)
thread3.start()

print "Main thread is sleeping"
time.sleep(15)
print "Main Thread quitting"

