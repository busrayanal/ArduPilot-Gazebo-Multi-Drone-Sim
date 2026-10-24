#!/bin/bash
# Writes a new QR code texture for the qr_marker model on the ground.
# Usage: ~/sim_drones/make_qr.sh "your message"
if [ -z "$1" ]; then
  echo "Usage: $0 \"message\""
  exit 1
fi
source $HOME/venv-ardupilot/bin/activate
python3 - "$1" "$HOME/sim_drones/models/qr_marker/materials/textures/qr.png" <<'PY'
import sys, qrcode
msg, out = sys.argv[1], sys.argv[2]
qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=20, border=4)
qr.add_data(msg.encode("utf-8"))
qr.make(fit=True)
qr.make_image(fill_color="black", back_color="white").save(out)
print(f"QR written ({qr.modules_count}x{qr.modules_count} modules): {msg}")
PY
echo "$1" > "$HOME/sim_drones/models/qr_marker/message.txt"
echo "Restart the simulation to see the new QR code."
