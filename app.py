import os
import json
import time
import signal
import sys
import random
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

############################################
# CONFIG (works everywhere automatically)
############################################

HOST = "0.0.0.0"
PORT = int(os.getenv("PORT", 8080))   # 8080 local, 80 on EC2 if needed

shutdown_flag = False
FEATURE_ENABLED = True


############################################
# Graceful shutdown for Auto Scaling
############################################

def shutdown_handler(signum, frame):
    global shutdown_flag
    print("Shutdown signal received → draining requests...")
    shutdown_flag = True
    time.sleep(10)   # simulate graceful drain
    sys.exit(0)


signal.signal(signal.SIGTERM, shutdown_handler)
signal.signal(signal.SIGINT, shutdown_handler)


############################################
# Simulated DB check with retry
############################################

def db_check(retries=3):
    for attempt in range(retries):
        try:
            # simulate temporary DB failure
            if random.random() < 0.3:
                raise Exception()

            return True
        except:
            print(f"DB retry {attempt+1}")
            time.sleep(2)

    return False


############################################
# HTTP Server
############################################

class AppHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        return  # silence logs (cleaner for lab)

    def send_json(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())


    def do_GET(self):

        # ========= Home =========
        if self.path == "/":
            self.send_json(200, {
                "message": "Lab 3 Resilient Server Running",
                "instance": os.uname().nodename
            })


        # ========= Health check =========
        elif self.path == "/health":

            if shutdown_flag:
                self.send_json(503, {"status": "shutting_down"})
                return

            if not db_check():
                self.send_json(500, {"status": "db_unhealthy"})
                return

            self.send_json(200, {"status": "healthy"})


        # ========= Feature toggle =========
        elif self.path == "/feature":

            if FEATURE_ENABLED:
                self.send_json(200, {"feature": "enabled"})
            else:
                self.send_json(200, {"feature": "disabled"})


        else:
            self.send_json(404, {"error": "not found"})


############################################
# Start server
############################################

if __name__ == "__main__":
    server = ThreadingHTTPServer((HOST, PORT), AppHandler)
    print(f"Server running at http://localhost:{PORT}")
    server.serve_forever()