import random
import time


def string_gen(size=20, chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'):
  return ''.join(random.choice(chars) for _ in range(size))


if __name__ == '__main__':
  port = 21000
  while True:
    s = str(port) + '/write \'{"Set":{"key":' + str(time.time()) + \
        ',"value": [' + str(port) + "] " + string_gen() + '}}\''
    print(s)
    time.sleep(random.randint(1, 5))
