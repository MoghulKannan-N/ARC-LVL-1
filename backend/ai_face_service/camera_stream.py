import cv2
import threading

class CameraStream:
    def __init__(self):
        self.cap = None
        self.frame = None
        self.running = False
        self.lock = threading.Lock()

    def start(self):
        if self.running:
            return
        
        self.cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
        self.running = True

        def run():
            while self.running:
                ret, frame = self.cap.read()
                if ret:
                    frame = cv2.flip(frame, 1)
                    with self.lock:
                        self.frame = frame

        threading.Thread(target=run, daemon=True).start()

    def stop(self):
        self.running = False
        if self.cap:
            self.cap.release()

    def get_frame(self):
        with self.lock:
            return None if self.frame is None else self.frame.copy()


camera_stream = CameraStream()
