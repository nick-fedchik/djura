#!/usr/bin/env python3
"""
lan_server.py — Локальний HTTPS + HTTP сервер для розробки «Geek Jack» на Xbox Series X та Web

Забезпечує Secure Context для Godot 4:
- Автоматична генерація локального SSL/TLS сертифіката (OpenSSL)
- Повноцінний HTTPS на порту 8443 (задовольняє вимогу Secure Context у браузері Edge на Xbox)
- Cross-Origin-Opener-Policy: same-origin
- Cross-Origin-Embedder-Policy: require-corp
- Правильні MIME-типи (.wasm, .pck, .js тощо)
- Cache-Control: no-cache для миттєвого оновлення коду
"""

import argparse
import http.server
import os
import socket
import ssl
import subprocess
import sys
import threading
from pathlib import Path


def get_lan_ips():
    ips = set()
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0.2)
        s.connect(("8.8.8.8", 80))
        ips.add(s.getsockname()[0])
        s.close()
    except Exception:
        pass

    try:
        hostname = socket.gethostname()
        for info in socket.getaddrinfo(hostname, None, socket.AF_INET):
            ip = info[4][0]
            if not ip.startswith("127."):
                ips.add(ip)
    except Exception:
        pass

    return sorted(list(ips))


def ensure_ssl_cert(ssl_dir: Path, lan_ips: list) -> tuple:
    ssl_dir.mkdir(parents=True, exist_ok=True)
    cert_path = ssl_dir / "cert.pem"
    key_path = ssl_dir / "key.pem"

    if cert_path.exists() and key_path.exists():
        return cert_path, key_path

    sans = ["DNS:localhost", "IP:127.0.0.1"]
    primary_ip = lan_ips[0] if lan_ips else "127.0.0.1"
    for ip in lan_ips:
        sans.append(f"IP:{ip}")
    san_str = ",".join(sans)

    cmd = [
        "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
        "-keyout", str(key_path),
        "-out", str(cert_path),
        "-days", "365",
        "-subj", f"/CN={primary_ip}",
        "-addext", f"subjectAltName={san_str}"
    ]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"⚠️  Не вдалося автоматично згенерувати SSL-сертифікат через openssl: {e}")
        return None, None

    return cert_path, key_path


class GodotWebRequestHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        "": "application/octet-stream",
        ".html": "text/html; charset=utf-8",
        ".js": "application/javascript",
        ".mjs": "application/javascript",
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".svg": "image/svg+xml",
        ".css": "text/css",
        ".json": "application/json",
        ".ico": "image/x-icon",
        ".woff2": "font/woff2",
    }

    def do_POST(self):
        if self.path == "/api/diagnostics":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            try:
                import json, time
                data = json.loads(body.decode("utf-8"))
                fps = data.get("fps", 0)
                ft = data.get("frame_time_ms", 0)
                gpu = data.get("gpu", "unknown")
                screen = data.get("screen", "")
                gamepad = data.get("gamepad", {})
                gp_count = gamepad.get("count", 0)
                gp_name = gamepad.get("name", "none")
                errors = data.get("errors", [])
                ua = data.get("ua", "")
                is_xbox = "Xbox" in ua

                # Красивий лог у термінал сервера
                print(f"\n📊 [КЛІЄНТ: {'XBOX' if is_xbox else 'БРАУЗЕР'}] FPS: {fps} ({ft}ms) | GP: {gp_count} [{gp_name}] | Резолюція: {screen}")
                if gp_count == 0 and is_xbox:
                    print("   ⚠️  УВАГА: Edge на Xbox у режимі миші! Натисніть кнопку Menu (три рисочки ☰) на геймпаді!")
                if errors:
                    print(f"   ❌ Помилки JS: {errors}")

                # Зберігаємо в файл diagnostics.jsonl
                with open("diagnostics.jsonl", "a", encoding="utf-8") as f:
                    data["server_timestamp"] = time.time()
                    f.write(json.dumps(data, ensure_ascii=False) + "\n")
            except Exception as e:
                sys.stderr.write(f"Помилка розбору діагностики: {e}\n")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
            return

        self.send_response(404)
        self.end_headers()

    def end_headers(self):
        # Заголовки для WebAssembly та Secure Context у Godot 4
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        super().end_headers()

    def log_message(self, format, *args):
        # Компактне логування
        sys.stderr.write(f"[{self.log_date_time_string()}] {args[0]} -> {args[1]}\n")


class HttpRedirectHandler(http.server.BaseHTTPRequestHandler):
    https_port = 8443

    def do_GET(self):
        host = self.headers.get("Host", "localhost").split(":")[0]
        target_url = f"https://{host}:{self.https_port}{self.path}"
        self.send_response(302)
        self.send_header("Location", target_url)
        self.end_headers()

    def do_HEAD(self):
        self.do_GET()

    def log_message(self, format, *args):
        pass


def run_http_redirect(bind_ip, http_port, https_port):
    class CustomHandler(HttpRedirectHandler):
        pass
    CustomHandler.https_port = https_port
    try:
        with http.server.ThreadingHTTPServer((bind_ip, http_port), CustomHandler) as httpd:
            httpd.serve_forever()
    except Exception:
        pass


def main():
    parser = argparse.ArgumentParser(description="LAN HTTPS Server для тестування гри на Xbox та Web")
    parser.add_argument("--port", "-p", type=int, default=8443, help="Порт HTTPS сервера (за замовчуванням: 8443)")
    parser.add_argument("--http-port", type=int, default=8080, help="Порт HTTP редиректу (за замовчуванням: 8080)")
    parser.add_argument("--bind", "-b", default="0.0.0.0", help="IP інтерфейсу для прослуховування")
    parser.add_argument("--dir", "-d", default=None, help="Каталог з файлами веб-збірки (за замовчуванням: build/web)")
    args = parser.parse_args()
    if args.bind == "0.0.0.0":
        print("[Увага] Сервер слухає всі інтерфейси (0.0.0.0) з самопідписаним сертифікатом: не запускайте в публічних мережах. Обмежте адресою LAN через --bind.", file=sys.stderr)

    repo_root = Path(__file__).resolve().parent.parent
    serve_dir = Path(args.dir) if args.dir else repo_root / "build" / "web"

    if not serve_dir.exists():
        serve_dir.mkdir(parents=True, exist_ok=True)

    os.chdir(serve_dir)

    lan_ips = get_lan_ips()
    primary_ip = lan_ips[0] if lan_ips else "127.0.0.1"
    ssl_dir = repo_root / "build" / ".ssl"

    cert_file, key_file = ensure_ssl_cert(ssl_dir, lan_ips)

    https_port = args.port
    http_port = args.http_port

    # Запускаємо фоновий HTTP редиректор на 8080 -> 8443
    redirect_thread = threading.Thread(
        target=run_http_redirect,
        args=(args.bind, http_port, https_port),
        daemon=True
    )
    redirect_thread.start()

    print("\n" + "=" * 70)
    print(" 🎮 GEEK JACK: ДЖУРА — ЛОКАЛЬНИЙ HTTPS LAN-СЕРВЕР ДЛЯ XBOX / ПК")
    print("=" * 70)
    print(f" 📂 Каталог збірки:  {serve_dir}")
    print(f" 🔒 HTTPS Порт:      {https_port} (Secure Context)")
    print(f" 🔄 HTTP Порт:       {http_port} (автоматичний редирект)")
    print("-" * 70)
    print(" 🔗 ВІДКРИЙТЕ НА XBOX (у додатку Microsoft Edge):")
    for ip in lan_ips:
        print(f"    👉 https://{ip}:{https_port}")
    print(f"    👉 https://localhost:{https_port} (на цьому ноутбуку)")
    print("-" * 70)
    print(" 🔑 ЯК ПРОЙТИ ПЕРЕВІРКУ НА XBOX EDGE (робиться 1 раз):")
    print("    1. Введіть адресу: https://" + primary_ip + f":{https_port}")
    print("    2. Edge покаже екран: «Ваше підключення не приватне» (через локальний SSL).")
    print("    3. Натисніть кнопку «Додатково» (Advanced) на екрані.")
    print(f"    4. Натисніть «Перейти на {primary_ip} (небезпечно)» / Continue.")
    print("    5. ВСЕ! Після цього вмикається Secure Context, гра стартує миттєво!")
    print("    6. Натисніть кнопку View (два квадратики на геймпаді) для повного екрана.")
    print("=" * 70)
    print(" ⚡ Сервер запущено. Натисніть Ctrl+C для зупинки.\n")

    handler = GodotWebRequestHandler

    try:
        with http.server.ThreadingHTTPServer((args.bind, https_port), handler) as httpd:
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            context.load_cert_chain(certfile=str(cert_file), keyfile=str(key_file))
            httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Сервер зупинено.")


if __name__ == "__main__":
    main()
