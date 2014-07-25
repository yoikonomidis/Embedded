import sys
import signal, os
import time
import threading

# Exit the program if Python version used is lower than 2.7.3
if sys.version_info < (2,7,3):
  print('Required Python version 2.7.3 or newer. Exiting!')
  exit(1)

if sys.version_info < (3,0,1):
  # Python version 2.x
  import SocketServer as socketserver
else:
  # Python version 3.x
  import socketserver

# Check for valid IP address
def valid_ip(address):
  try:
    host_bytes = address.split('.')
    valid = [int(b) for b in host_bytes]
    valid = [b for b in valid if b >= 0 and b <= 255]
    return len(host_bytes) == 4 and len(valid) == 4
  except:
    return False

# Get the IP address to run the server on.
# This should be same as HOST computer's static IP address
try:
  g_HOST = sys.argv[1]
  if not valid_ip(g_HOST):
    exit(1)
except:
   print('Please enter a valid Web server IP address. Exiting!')
   exit(1)

# Global variables
g_interrupted = False
g_start_counter = False
g_sleep_time = 30
g_temperature = 0
g_program_running = False
g_log_file = 'temperature.log'

# Keyboard interrupt handler
def kb_handler(signum, frame):
    global g_interrupted
    g_interrupted = True

signal.signal(signal.SIGINT, kb_handler)

# ----------------------------------------------------------------------------
# Counter - a thread to manage the sleep count-down
# ----------------------------------------------------------------------------
def counter():
  global g_sleep_time
  global g_start_counter

  time_10s = 0
  old_temperature = 0
  timer_temperature = False

  log = open(g_log_file, 'w')
  log.write('Time     Temperature\n')
  
  while True:
    time.sleep(1)
    time_10s += 1

    if g_start_counter:
      if g_sleep_time >= 0:
        print(g_sleep_time)
        g_sleep_time -= 1
      else:
        print('Server: Sleep time exceeded. The chip should have woken up by now!')
        g_start_counter = False

    else:
      if time_10s >= 10:
        timer_temperature = True

      if ((g_temperature != old_temperature) or timer_temperature) and g_program_running:
        old_temperature = g_temperature
        time_10s = 0
        timer_temperature = False
        log.write(time.strftime('%H:%M:%S') + ' ' + str(g_temperature) + '\n')
        log.flush()
        print(g_temperature)
    if g_interrupted:
      log.close()
      break

# ----------------------------------------------------------------------------
# The TCP handler - receive data from the device and print it on the console
# ----------------------------------------------------------------------------
class xmos_tcp_handler(socketserver.BaseRequestHandler):

  def handle(self):

    global g_start_counter
    global g_sleep_time
    global g_temperature
    global g_program_running
    print('test')
    while True:
      print('DEBU')
      data = self.request.recv(1024).decode()
      g_start_counter = False
      g_program_running = True
      if data:
        for line in data.split('\n'):
          if line:
            print('XMOS: %s' % line)
            if 'Temperature' in line:
              g_temperature = int(line[28:31])
      else:
        g_sleep_time = 30
        print('-----------------------------------------')
        print('Server: Client closed connection, expecting wakeup in %d seconds...' %
            g_sleep_time)
        self.request.close()
        g_start_counter = True
        break

# ----------------------------------------------------------------------------
# start_server - wait until the link is up and then start listening
# ----------------------------------------------------------------------------
def start_server():
  global g_interrupted

  PORT = 3000

  print('Server: Logging temperature data to %s' % g_log_file)
  print('Server: Waiting to start web server')
  print('Server: Press CTRL+C to exit.')

  while True:
    socketserver.TCPServer.allow_reuse_address = True
    try:
      server = socketserver.TCPServer((g_HOST, PORT), xmos_tcp_handler)
      print('Server: Web server started with IP address = %s' % g_HOST)
      print('-----------------------------------------')
      server.serve_forever()

    except KeyboardInterrupt:
      g_interrupted = True
      server.socket.close()
      print('Server: Exiting')
      break

    except Exception as e:
      if 'Permission denied' in str(e):
        print('Server: Permssion denied - please run as administrator')
        g_interrupted = True
        break

      # Wait and try again
      time.sleep(1)

# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------
if __name__ == "__main__":

  t_server = threading.Thread(target=start_server)
  t_server.setDaemon(True)
  t_server.start()

  t_counter = threading.Thread(target=counter)
  t_counter.start()

  while True:
    if g_interrupted:
      t_counter.join()
      print('Server: Terminating...')
      break
    pass

