#!/usr/bin/env python3
# Watches a drone's down camera and prints the QR message when it sees one.
# Usage: python3 ~/sim_drones/examples/qr_oku.py [drone number, default 1]
import sys, time
import numpy as np, cv2
from gz.transport13 import Node
from gz.msgs10.image_pb2 import Image

drone = sys.argv[1] if len(sys.argv) > 1 else "1"
topic = f"/drone{drone}/down_camera"
latest = {}

def on_image(msg):
    latest["img"] = msg

node = Node()
node.subscribe(Image, topic, on_image)
detector = cv2.QRCodeDetector()
last_text = None
print(f"Watching {topic} (Ctrl+C to stop)...")

while True:
    msg = latest.pop("img", None)
    if msg is not None:
        img = np.frombuffer(msg.data, np.uint8).reshape(msg.height, msg.width, 3)
        text, _, _ = detector.detectAndDecode(img)
        if text and text != last_text:
            print(f"drone{drone} QR: {text}")
            last_text = text
    time.sleep(0.1)
