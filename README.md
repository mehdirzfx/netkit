# NetKit

A multi-purpose toolkit for network testing and text security | Swiss Army Knife for Network & Security, Built for Iranian users.

## 🎯 Core Features

### 🔐 Text Encryption & Decryption
- Encrypt text using standard algorithms
- Decrypt encrypted messages
- Secure information transfer

### 📱 QR Code Generator & Scanner
- Convert text to QR code
- Scan QR codes using camera
- Easy information sharing

### 🌐 Network Tools
- **Ping** websites and IP addresses
- **IP Information** (geolocation, ISP, etc.)
- **Proxy Testing** - Ping proxies to find the fastest one

### 🔄 Telegram Proxy Tools (Coming Soon)
- Fetch and test Telegram proxies
- ProxyChain support for running multiple proxies
- Support for MTProto, SOCKS5, HTTP proxies

## 📱 Supported Platforms
- Android
- iOS
- Windows
- macOS
- Linux
- Web

## 🛠️ Tech Stack
- **Framework:** Flutter
- **Language:** Dart
- **Encryption:** (Add your package here, e.g., `crypto` or `encrypt`)
- **QR Code:** (e.g., `qr_flutter`, `mobile_scanner`)
- **Networking:** (e.g., `http`, `ping`, `dart:io`)

## 📦 Installation

### Android (APK)
1. Download APK from [Releases](https://github.com/mehdirzfx/netkit/releases)
2. Install the APK (enable "Install from unknown sources" if needed)
3. Launch the app

### Build from source
```bash
git clone https://github.com/mehdirzfx/netkit.git
cd netkit
flutter pub get
flutter run
```

## 🧪 How to Use

### Text Encryption
1. Go to **Encrypt/Decrypt** section
2. Enter your text
3. Click **Encrypt**
4. To decrypt, enter the encrypted text and click **Decrypt**

### QR Code Generation
1. Go to **QR Generator** section
2. Enter your text or link
3. QR code is generated automatically
4. Save or share the QR code

### Ping & Network Testing
1. Go to **Network Tools** section
2. Enter website address or IP (e.g., `google.com` or `8.8.8.8`)
3. Click **Ping**
4. View response time results

### IP Information
- In **IP Info** section, your current IP is shown automatically
- You can also enter any IP address to get its details (country, city, ISP)

### Proxy Testing
1. Enter your proxy (e.g., `192.168.1.1:8080`)
2. Click **Test Proxy**
3. App pings the proxy and shows response time
4. Compare multiple proxies to find the fastest one

## ⏳ Upcoming Features

- [ ] Dedicated Telegram proxy tool
- [ ] ProxyChain implementation
- [ ] Auto-fetch active proxy lists
- [ ] Auto-connect to fastest proxy

## 🤝 Contributing

We welcome contributions to improve NetKit:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) file for details.

## 📧 Contact

Mehdi Rezaei Far  
- GitHub: [@mehdirzfx](https://github.com/mehdirzfx)
- Email: semicalon@outlook.com

## ⭐ Support

If NetKit is useful for you, please give it a star ⭐ on GitHub to encourage further development.
