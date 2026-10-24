# ArduPilot + Gazebo Harmonic: 3 Drone Simülasyonu (WSL2)

[English](README.md) | **Türkçe**

Windows 11 üzerinde, WSL2 içindeki Ubuntu 24.04'te çalışan bir ArduPilot SITL + Gazebo Harmonic simülasyonu:

- Aynı dünyada **3 Iris quadcopter**, her biri ayrı bir ArduCopter SITL tarafından yönetiliyor
- Her drone'da **aşağı bakan kamera** (640x480, 30 FPS)
- Yerde, mesajı değiştirilebilen bir **QR kod** ve kameradan okuyan örnek bir Python betiği
- Tek komutla başlatma / durdurma

![Drone kamerasından QR görüntüsü](docs/qr_camera.png)

---

## İçindekiler

1. [Gereksinimler](#1-gereksinimler)
2. [WSL2 ve Ubuntu 24.04 kurulumu](#2-wsl2-ve-ubuntu-2404-kurulumu)
3. [Sistem güncellemesi](#3-sistem-güncellemesi)
4. [Gazebo Harmonic](#4-gazebo-harmonic)
5. [Ekran kartı ayarı (önemli)](#5-ekran-kartı-ayarı-önemli)
6. [ArduPilot SITL](#6-ardupilot-sitl)
7. [ardupilot_gazebo eklentisi](#7-ardupilot_gazebo-eklentisi)
8. [Tek drone testi](#8-tek-drone-testi)
9. [Bu repoyu kurmak](#9-bu-repoyu-kurmak)
10. [Kullanım](#10-kullanım)
11. [Sorun giderme](#11-sorun-giderme)

---

## 1. Gereksinimler

- Windows 11 (WSLg ile grafik pencereler doğrudan açılır)
- BIOS/UEFI'de sanallaştırma açık (Görev Yöneticisi > Performans > CPU > "Sanallaştırma: Etkin")
- ~30 GB boş disk alanı
- Tercihen NVIDIA ekran kartı (Intel/AMD ile de çalışır, sadece daha yavaş olabilir)

Test edilen sistem: i7-12700H, 64 GB RAM, RTX 4060 Laptop, WSL 3.0.3, Ubuntu 24.04, Gazebo Harmonic (gz-sim 8).

## 2. WSL2 ve Ubuntu 24.04 kurulumu

**Yönetici olarak** PowerShell aç ve çalıştır (`--location` isteğe bağlı; Ubuntu'yu C: yerine başka bir diske koymak için):

```powershell
wsl --install -d Ubuntu-24.04 --location D:\WSL\Ubuntu --version 2 --no-launch
```

İlk seferde WSL bileşenleri kurulur ve **yeniden başlatma** ister. Yeniden başlattıktan sonra **aynı komutu tekrar** çalıştır. Kontrol:

```powershell
wsl -l -v
```

`Ubuntu-24.04` ve `VERSION 2` görünmeli.

Başlat menüsünden **Ubuntu 24.04**'ü aç. Kullanıcı adı (küçük harf, Türkçe karakter ve boşluk yok) ve şifre oluştur. Şifre yazarken ekranda görünmez, bu normal.

> WSL'de Ubuntu masaüstü yoktur, sadece terminal açılır. Gazebo gibi grafik programlar normal Windows pencereleri olarak açılır.

> Terminalde **Ctrl+C kopyalamaz, çalışan programı durdurur.** Kopyalamak için **Ctrl+Shift+C**, yapıştırmak için **Ctrl+Shift+V** veya sağ tık.

## 3. Sistem güncellemesi

```bash
sudo apt update && sudo apt upgrade -y
```

## 4. Gazebo Harmonic

[Resmi kurulum sayfası](https://gazebosim.org/docs/harmonic/install_ubuntu/):

```bash
sudo apt-get install -y curl lsb-release gnupg
sudo curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
sudo apt-get update
sudo apt-get install -y gz-harmonic
```

## 5. Ekran kartı ayarı (önemli)

WSL varsayılan olarak çizimi işlemciyle (`llvmpipe`) yapabilir; bu durumda Gazebo çok yavaş çalışır. Kontrol et:

```bash
sudo apt-get install -y mesa-utils
glxinfo -B | grep "renderer string"
```

- `D3D12 (NVIDIA ...)` yazıyorsa sorun yok.
- `llvmpipe` veya `D3D12 (Intel ...)` yazıyorsa ve bilgisayarında NVIDIA kart varsa:

```bash
cat >> ~/.bashrc <<'EOF'

# WSL: render with the NVIDIA GPU instead of llvmpipe
export GALLIUM_DRIVER=d3d12
export MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
EOF
source ~/.bashrc
glxinfo -B | grep "renderer string"
```

Artık `D3D12 (NVIDIA GeForce ...)` görünmeli. Bu ayar kalıcıdır.

Test: `gz sim shapes.sdf` (kapatmak için pencereyi kapat veya terminalde Ctrl+C).

## 6. ArduPilot SITL

```bash
cd ~
sudo apt install -y git
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot.git
cd ~/ardupilot
Tools/environment_install/install-prereqs-ubuntu.sh -y
```

Bitince **Ubuntu penceresini kapatıp yeniden aç.** Satır başında `(venv-ardupilot)` görmelisin; ArduPilot'un Python ortamı her açılışta otomatik etkinleşir. MAVProxy de bu adımla kurulur.

Gazebo'suz test:

```bash
cd ~/ardupilot/ArduCopter
sim_vehicle.py -w --console --map
```

`STABILIZE>` çıkınca:

```
mode guided
arm throttle
takeoff 10
```

İndirmek için `mode land`, çıkmak için Ctrl+C.

> `Failed to download /SRTM3/...` hatası zararsızdır (harita arazi verisi).

## 7. ardupilot_gazebo eklentisi

[ArduPilot/ardupilot_gazebo](https://github.com/ArduPilot/ardupilot_gazebo):

```bash
sudo apt install -y libgz-sim8-dev rapidjson-dev libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

cd ~
git clone https://github.com/ArduPilot/ardupilot_gazebo
cd ardupilot_gazebo
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j8
```

Ortam değişkenleri:

```bash
cat >> ~/.bashrc <<'EOF'

# ardupilot_gazebo
export GZ_VERSION=harmonic
export GZ_SIM_SYSTEM_PLUGIN_PATH=$HOME/ardupilot_gazebo/build:$GZ_SIM_SYSTEM_PLUGIN_PATH
export GZ_SIM_RESOURCE_PATH=$HOME/ardupilot_gazebo/models:$HOME/ardupilot_gazebo/worlds:$GZ_SIM_RESOURCE_PATH
EOF
source ~/.bashrc
```

## 8. Tek drone testi

İki Ubuntu penceresi aç.

**1. pencere:**

```bash
gz sim -v4 -r iris_runway.sdf
```

**2. pencere:**

```bash
cd ~/ardupilot
sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON --map --console -w \
  --add-param-file=Tools/autotest/default_params/copter.parm \
  --add-param-file=Tools/autotest/default_params/gazebo-iris.parm
```

Sonra `mode guided`, `arm throttle`, `takeoff 10`.

> **Neden `--add-param-file`?** Ekim 2026 itibarıyla ArduPilot'un geliştirme sürümü (master), varsayılan parametreleri `-f gazebo-iris` yerine `--model JSON` adına göre arıyor ve Iris ayarlarını yüklemiyor. Sonuç: `PreArm: Motors: Check frame class and type`. Parametre dosyalarını elle vermek bunu çözer. Bu repodaki betikler bunu otomatik yapar.

## 9. Bu repoyu kurmak

Betikler `~/sim_drones` klasörünü varsayar:

```bash
cd ~
git clone https://github.com/busrayanal/ArduPilot-Gazebo-Multi-Drone-Sim.git sim_drones
cd ~/sim_drones
chmod +x *.sh
pip install qrcode
./setup_models.sh
```

`setup_models.sh`, ardupilot_gazebo'daki `iris_with_ardupilot` modelinden `iris_drone1..3` modellerini üretir. Her birinin ayrı bir FDM portu ve aşağı bakan bir kamerası olur.

## 10. Kullanım

### Başlatma

```bash
~/sim_drones/start_3drones.sh
```

Gazebo ve ardından **Drone1**, **Drone2**, **Drone3** pencereleri açılır. Her pencerede `STABILIZE>` çıkınca:

```
mode guided
arm throttle
takeoff 10
```

`PreArm` veya `Accels inconsistent` uyarısı çıkarsa 10-20 saniye bekleyip `arm throttle` komutunu tekrarla.

### Durdurma

```bash
~/sim_drones/stop_sim.sh
```

`Everything stopped.` görünmeli. Ctrl+C ile kapatmak arka planda ArduPilot süreçleri bırakabilir; her zaman bu betiği kullan.

### Drone'lar, portlar, konumlar

| Drone | SITL instance | SYSID | Gazebo FDM portu | Kodun için MAVLink | Kamera topic'i | Konum (Gazebo) |
|---|---|---|---|---|---|---|
| drone1 | 0 | 1 | 9002 | `udp:127.0.0.1:14561` | `/drone1/down_camera` | (0, 0) |
| drone2 | 1 | 2 | 9012 | `udp:127.0.0.1:14562` | `/drone2/down_camera` | (0, 4) |
| drone3 | 2 | 3 | 9022 | `udp:127.0.0.1:14563` | `/drone3/down_camera` | (0, 8) |

Gazebo'da +Y kuzeydir. Her açılışta drone parametreleri sıfırlanır (`-w`), böylece her test aynı başlangıçla yapılır.

### Kamerayı izleme

Gazebo'da sağ üstteki **⋮** menüsünden **Image Display** ekle ve listeden `/drone1/down_camera` seç. Drone yerdeyken görüntü bulanıktır (kamera zemine ~10 cm uzaklıkta); kalkınca netleşir.

### QR kod

QR, drone1'in 20 m kuzeyinde, yerde duruyor (4x4 m). Mesajı değiştirmek için (simülasyon kapalıyken):

```bash
~/sim_drones/make_qr.sh "Yeni mesaj"
```

Okumak için ayrı bir pencerede:

```bash
python3 ~/sim_drones/examples/qr_oku.py 1
```

Drone1 penceresinde QR'ın üstüne git:

```
mode guided
arm throttle
takeoff 10
guided -35.363082 149.165237 10
```

Okuyucu penceresinde `drone1 QR: ...` satırı belirir.

> MAVProxy'de `guided` komutu **enlem boylam yükseklik** alır, metre değil. `guided 20 0 10` drone'u enlem 20°, boylam 0°'a gönderir!

## 11. Sorun giderme

| Belirti | Sebep / çözüm |
|---|---|
| `PreArm: Motors: Check frame class and type` | Iris parametreleri yüklenmemiş. [8. adımdaki](#8-tek-drone-testi) `--add-param-file` notuna bak. Daha önce açık kalmış bir ArduPilot da sebep olabilir: `stop_sim.sh` çalıştır. |
| Gazebo çok yavaş / takılıyor | `glxinfo -B` ile `llvmpipe` kontrol et, [5. adım](#5-ekran-kartı-ayarı-önemli). |
| `ArduPilot controller has reset` (Gazebo terminalinde) | Başlangıçta birkaç kez normal. Uçuş sırasında sürekli akıyorsa bağlantı kopuyordur; her şeyi kapatıp yeniden başlat. |
| `Failed to download /SRTM3/...` | Zararsız, görmezden gel. |
| Bir drone penceresinde `DroneN stopped` | O pencerede Ctrl+C'ye basılmış. `stop_sim.sh` ve `start_3drones.sh` ile yeniden başlat. |
| Kapattıktan sonra garip davranışlar | Arka planda süreç kalmış olabilir: `stop_sim.sh`. |

## Dosyalar

```
start_3drones.sh       Gazebo + 3 SITL başlatır
stop_sim.sh            Her şeyi kapatır
setup_models.sh        iris_drone1..3 modellerini üretir (port + kamera)
make_qr.sh             QR doku resmini üretir
worlds/iris_3drones.sdf
models/qr_marker/      Yerdeki QR modeli
examples/qr_oku.py     Kameradan QR okuma örneği
```

## Teşekkürler

- [ArduPilot](https://github.com/ArduPilot/ardupilot) ve [ardupilot_gazebo](https://github.com/ArduPilot/ardupilot_gazebo): dünya dosyası ve Iris modeli bu projelerdeki `iris_runway.sdf` ve `iris_with_ardupilot` üzerine kuruludur.
- [Gazebo](https://gazebosim.org/)
